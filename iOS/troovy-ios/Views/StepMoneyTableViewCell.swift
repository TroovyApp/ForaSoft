//
//  StepTextInfoTableViewCell.swift
//  StepScrollView
//
//  Created by Daniil on 04.12.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit
import IQKeyboardManager
import StoreKit

class StepMoneyTableViewCell: StepInfoTableViewCell, UITextViewDelegate {
    
    // MARK: Properties Overriders
    
    override var frame: CGRect {
        didSet {
            self.contentTextView?.layoutSubviews()
            self.contentTextViewLight?.layoutSubviews()
        }
    }
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var contentTextView: PlaceholderTextView!
    @IBOutlet weak var contentTextViewLight: PlaceholderTextView!
    
    // MARK: Private Properties
    
    private var numberFormatter: NumberFormatter!
    private let paymentService = PaymentService()
    private let pickerView = UIPickerView()
    private var products = [SKProduct]()
    
    // MARK: Init Methods & Superclass Overriders
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.setupNumberFormatter()
        self.setupPickerView()
        subscribeToProductUpdates()
        TroovyProducts.shared.requestProducts()
    }
    
    override func removeFromSuperview() {
        NotificationCenter.default.removeObserver(self)
        
        super.removeFromSuperview()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func isStepFilled() -> Bool {
        return (self.stepSelected || (self.contentTextView.text != nil && !self.contentTextView.text!.isEmpty))
    }
    
    override func makeAdditionalTransforms(filled: Bool, scaled: Bool) {
        self.contentContainer.transform = (scaled ? CGAffineTransform.identity : CGAffineTransform.identity.scaledBy(x: 0.85, y: 0.85).translatedBy(x: 0.0 - self.contentTextViewLight.bounds.width * 0.09, y: 0.0 - self.fullSizeHeight * 0.025))
        
        self.contentTextView.alpha = (scaled ? 1.0 : 0.0)
        self.contentTextViewLight.alpha = (scaled ? 0.0 : 1.0)
        
        self.contentContainer.bringSubview(toFront: (scaled ? self.contentTextView : self.contentTextViewLight))
    }
    
    override func configureInterface(animated: Bool) {
        if !self.stepSelected && self.contentTextView.isFirstResponder {
            self.contentTextView.resignFirstResponder()
        }
        
        self.configureInterface()
        
        super.configureInterface(animated: animated)
    }
    
    // MARK: Private Methods
    
    private func subscribeToProductUpdates() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleProductsUpdateNotification(_:)),
                                               name: NSNotification.Name(rawValue: TroovyProducts.TroovyProductsUpdatedNotification),
                                               object: nil)
    }
    
    
    private func setupPickerView() {
        self.pickerView.delegate = self
        self.pickerView.dataSource = self
    }
    
    private func setupNumberFormatter() {
        self.numberFormatter = NumberFormatter()
        self.numberFormatter.numberStyle = .currency
    }
    
    private func configureInterface() {
        var priceString: String?
        if let step = self.step.text, let product = TroovyProducts.shared.productForProductIdentifier(step) {
            priceString = self.moneyString(fromProduct: product)
        }
        self.contentTextView.placeholder = self.step.placeholder
        self.contentTextView.text = priceString
        self.contentTextView.isScrollEnabled = false
        
        self.contentTextViewLight.placeholder = self.step.placeholder
        self.contentTextViewLight.textContainer.maximumNumberOfLines = 2
        self.contentTextViewLight.textContainer.lineBreakMode = .byTruncatingTail
        self.contentTextViewLight.text = priceString
        //self.contentTextViewLight.text = self.moneyString(fromText: self.step.text)
        self.contentTextViewLight.isScrollEnabled = false
    }
    
    private func moneyString(fromProduct product: SKProduct) -> String? {
        self.numberFormatter.locale = product.priceLocale
        let number = product.price
        if number != NSDecimalNumber.notANumber {
            let commission = self.paymentService.courseCommisionPercentage()
            let priceAfterCommission = number.multiplying(by: NSDecimalNumber(value: 1.0 - commission))
            if let string = self.numberFormatter.string(from: priceAfterCommission ){
                return string + " / subscription"
            }
        }
        
        return nil
    }
    
    // MARK: Protocols Implementation
    
    // MARK: UITextViewDelegate
    
    internal func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        //IQKeyboardManager.shared().isEnableAutoToolbar = true
        if textView == self.contentTextViewLight {
            if !self.stepSelected {
                DispatchQueue.main.async {
                    self.delegate?.cell(self, didBecomeFirstResponderWithOrder: self.stepOrder)
                }
            }
            
            return false
        }
        
        return true
    }
    
    internal func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return false
    }
    
    internal func textViewDidBeginEditing(_ textView: UITextView) {
        self.setContentLabel(visible: true, animated: true)
        
        if !self.stepSelected {
            self.delegate?.cell(self, didBecomeFirstResponderWithOrder: self.stepOrder)
        }
        
        if let priceTierText = self.step.text, priceTierText.isEmpty == false {
            if let index = products.index(where: {$0.productIdentifier == priceTierText}) {
                self.pickerView.selectRow(index, inComponent: 0, animated: true)
                self.pickerView(pickerView, didSelectRow: index, inComponent: 0)
            }
        } else if products.count > 0 {
            self.pickerView.selectRow(0, inComponent: 0, animated: true)
            self.pickerView(pickerView, didSelectRow: 0, inComponent: 0)
        } else {
            
        }
    }
    
    internal func textViewDidEndEditing(_ textView: UITextView) {
        self.setContentLabel(visible: false, animated: true)
        //IQKeyboardManager.shared().isEnableAutoToolbar = false
    }
    
    internal func textViewDidChange(_ textView: UITextView) {
//        self.checkCellFilled(animated: true)
//        self.step.changeText(text: textView.text)
//        self.delegate?.cell(self, didChangeStep: self.step, order: self.stepOrder)
    }
    
}

extension StepMoneyTableViewCell: UIPickerViewDelegate, UIPickerViewDataSource {
    
    //MARK: UIPickerViewDelegate
    
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let priceTierString = String(describing: products[row].productIdentifier)
        self.checkCellFilled(animated: true)
        self.step.changeText(text: priceTierString)
        self.contentTextView.text = self.moneyString(fromProduct: products[row])
        self.contentTextViewLight.text = self.moneyString(fromProduct: products[row])
        self.delegate?.cell(self, didChangeStep: self.step, order: self.stepOrder)
    }
 
    //MARK: UIPickerViewDataSource
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return products.count
    }
    
    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return TroovyProducts.shared.priceStringForProduct(item: products[row])
    }
    
    // MARK: NSNotificationCenter
    
    @objc func handleProductsUpdateNotification(_ notification: Notification) {
        guard let products = notification.object as? [SKProduct] else { return }
        
        self.products = products
        
        if (products.count > 0) {
            DispatchQueue.main.async { [weak self]() in
                self?.contentTextView.inputView = self?.pickerView
                self?.pickerView.reloadAllComponents()
            }
        }
    }
}
