//
//  ApplicationModel.swift
//  troovy-ios
//
//  Created by Daniil on 31.10.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import Foundation

class ApplicationModel: NSObject {
    
    private struct NotificationNames {
        static let modelChanged = "troovy_applicationModelChanged"
    }
    
    private struct Keys {
        static let payoutServiceTax = "payoutServiceTax"
        static let subscribeServiceTax = "subscribeServiceTax"
    }
    
    // MARK: Public Properties
    
    /// Withdrawal tax.
    private(set) var payoutServiceTax: NSDecimalNumber?
    
    /// Subscribe to the course tax.
    private(set) var subscribeServiceTax: NSDecimalNumber?
    
    // MARK: Init Methods & Superclass Overriders
    
    /// Initializes structure with dictionary.
    ///
    /// - parameter dictionary: Server response or saved user dictionary.
    ///
    init(withDictionary dictionary: [String:Any]) {
        super.init()
        
        if let payoutServiceTax = dictionary[Keys.payoutServiceTax] as? String {
            self.payoutServiceTax = NSDecimalNumber(string: payoutServiceTax)
        } else if let payoutServiceTax = dictionary[Keys.payoutServiceTax] as? Double {
            self.payoutServiceTax = NSDecimalNumber(value: payoutServiceTax)
        }
        
        if let subscribeServiceTax = dictionary[Keys.subscribeServiceTax] as? String {
            self.subscribeServiceTax = NSDecimalNumber(string: subscribeServiceTax)
        } else if let subscribeServiceTax = dictionary[Keys.subscribeServiceTax] as? Double {
            self.subscribeServiceTax = NSDecimalNumber(value: subscribeServiceTax)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationChanged(_:)), name: Notification.Name(NotificationNames.modelChanged), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Notifications & Observers
    
    @objc private func applicationChanged(_ notification: Notification) {
        guard let notificationModel = notification.object as? ApplicationModel else {
            return
        }
        
        if notificationModel != self {
            if let payoutServiceTax = notification.userInfo?[Keys.payoutServiceTax] as? NSDecimalNumber {
                self.payoutServiceTax = payoutServiceTax
            }
            
            if let subscribeServiceTax = notification.userInfo?[Keys.subscribeServiceTax] as? NSDecimalNumber {
                self.subscribeServiceTax = subscribeServiceTax
            }
        }
    }
    
    // MARK: Public Methods
    
    /// Converts model to dictionary.
    ///
    /// - returns: Model as dictionary.
    ///
    func modelAsDictionary() -> [String:Any] {
        var dictionary: [String:Any] = [:]
        if let payoutServiceTax = self.payoutServiceTax?.stringValue {
            dictionary[Keys.payoutServiceTax] = payoutServiceTax
        }
        
        if let subscribeServiceTax = self.subscribeServiceTax?.stringValue {
            dictionary[Keys.subscribeServiceTax] = subscribeServiceTax
        }
        
        return dictionary
    }
    
    /// Changes structure with passed properties.
    ///
    /// - parameter dictionary: Application server dictionary.
    ///
    func update(withDictionary dictionary: [String:Any]) {
        var userInfo: [String:Any] = [:]

        if let payoutServiceTax = dictionary[Keys.payoutServiceTax] as? String {
            self.payoutServiceTax = NSDecimalNumber(string: payoutServiceTax)
            userInfo[Keys.payoutServiceTax] = NSDecimalNumber(string: payoutServiceTax)
        } else if let payoutServiceTax = dictionary[Keys.payoutServiceTax] as? Double {
            self.payoutServiceTax = NSDecimalNumber(value: payoutServiceTax)
            userInfo[Keys.payoutServiceTax] = NSDecimalNumber(value: payoutServiceTax)
        }
        
        if let subscribeServiceTax = dictionary[Keys.subscribeServiceTax] as? String {
            self.subscribeServiceTax = NSDecimalNumber(string: subscribeServiceTax)
            userInfo[Keys.subscribeServiceTax] = NSDecimalNumber(string: subscribeServiceTax)
        } else if let subscribeServiceTax = dictionary[Keys.subscribeServiceTax] as? Double {
            self.subscribeServiceTax = NSDecimalNumber(value: subscribeServiceTax)
            userInfo[Keys.subscribeServiceTax] = NSDecimalNumber(value: subscribeServiceTax)
        }
        
        NotificationCenter.default.post(name: Notification.Name(NotificationNames.modelChanged), object: self, userInfo: userInfo)
    }
    
}
