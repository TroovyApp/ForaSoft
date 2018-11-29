//
//  TroovyStore.swift
//  troovy-ios
//
//  Created by forasoft on 25/04/2018.
//  Copyright © 2018 ForaSoft. All rights reserved.
//

import Foundation
import StoreKit

public class TroovyProducts {
    
    static let shared = TroovyProducts()
    static let TroovyProductsUpdatedNotification = "TroovyProductsUpdatedNotification"
    static let TroovyProductsDidMakePurchaseNotification = "TroovyProductsDidMakePurchaseNotification"
    static let TroovyProductsFailPurchaseNotification = "TroovyProductsFailPurchaseNotif`ication"
    
    // MARK: Private Properties
    private static var productIdentifiers: Set<ProductIdentifier> = []
    private static let productTiersNumbers = [10, 20, 30, 40, 50, 52, 54, 56, 58, 60]
    private static var productTemplateIdentifier: String! = ""
    
    private var products = [SKProduct]()
    private var store: IAPService!
    private var isRequesting = false
    private let infoPlistService = InfoPlistService()
    
    // MARK: Public Methods
    public func priceStringForProduct(item: SKProduct) -> String? {
        let numberFormatter = NumberFormatter()
        let price = item.price
        let locale = item.priceLocale
        numberFormatter.numberStyle = .currency
        numberFormatter.locale = locale
        return numberFormatter.string(from: price)
    }
    
    public func getCurrentCurrency() -> String? {
        if products.count > 0 {
            return currencyCodeForProduct(item: products[0])
        } else {
            return nil
        }
    }
    
    public func getCurrentCurrencyLocale() -> Locale? {
        if products.count > 0 {
            return products[0].priceLocale
        } else {
            return nil
        }
    }
    
    /// Returns  ISO 4217 currency code for product
    public func currencyCodeForProduct(item: SKProduct) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.locale = item.priceLocale
        return numberFormatter.currencyCode
    }
    
    public func resourceNameForProductIdentifier(_ productIdentifier: String) -> String? {
        return productIdentifier.components(separatedBy: ".").last
    }
    
    public func priceForProductIdentifier(_ productIdentifier: String) -> NSDecimalNumber? {
        return products.first(where: {$0.productIdentifier == productIdentifier})?.price
    }
    
    public func productForProductIdentifier(_ productIdentifier: String) -> SKProduct? {
        return products.first(where: {$0.productIdentifier == productIdentifier})
    }
    
    init() {
        TroovyProducts.productTemplateIdentifier = infoPlistService.inAppPurchaseProductTemplate()
        createProductIdentifiers()
        store = IAPService(productIds: TroovyProducts.productIdentifiers)
        NotificationCenter.default.addObserver(self, selector: #selector(handleProductsNotification(_:)), name: NSNotification.Name(rawValue: IAPService.IAPServiceProductsLoadedNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleProductsNotification(_:)), name: NSNotification.Name(rawValue: IAPService.IAPServiceProductsFailedLoadingNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleProductsNotification(_:)), name: NSNotification.Name(rawValue: IAPService.IAPServicePurchaseSucceedNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleProductsNotification(_:)), name: NSNotification.Name(rawValue: IAPService.IAPServicePurchaseFailNotification), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    public func requestProducts() {
        if products.isEmpty && !isRequesting {
            isRequesting = true
            store.requestProducts()
        } else if !isRequesting {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: TroovyProducts.TroovyProductsUpdatedNotification), object: products)
        }
    }
    
    public func buyProduct(_ productID: String) {
        if let product = productForProductIdentifier(productID) {
            store.buyProduct(product)
        }
    }
    
    // MARK: Private Methods
    
    private func createProductIdentifiers() {
        for i in TroovyProducts.productTiersNumbers {
            let nextIdentifier = TroovyProducts.productTemplateIdentifier + String(i)
            TroovyProducts.productIdentifiers.insert(nextIdentifier)
        }
    }

    @objc private func handleProductsNotification(_ notification: Notification) {
        if notification.name.rawValue == IAPService.IAPServiceProductsFailedLoadingNotification {
            isRequesting = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: { [weak store]() in
                store?.requestProducts()
            })
        } else if notification.name.rawValue == IAPService.IAPServiceProductsLoadedNotification {
            isRequesting = false
            guard let products = notification.object as? [SKProduct] else { return }
            self.products = products
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: TroovyProducts.TroovyProductsUpdatedNotification), object: products)
        } else if notification.name.rawValue == IAPService.IAPServicePurchaseSucceedNotification {
            guard let productID = notification.object as? String else { return }
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: TroovyProducts.TroovyProductsDidMakePurchaseNotification), object: productID)
        } else if notification.name.rawValue == IAPService.IAPServicePurchaseFailNotification {
            guard let productID = notification.object as? String else { return }
            if let userInfo = notification.userInfo {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: TroovyProducts.TroovyProductsFailPurchaseNotification), object: productID, userInfo: userInfo)
            } else {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: TroovyProducts.TroovyProductsFailPurchaseNotification), object: productID)
            }
        }
    }
    
}
