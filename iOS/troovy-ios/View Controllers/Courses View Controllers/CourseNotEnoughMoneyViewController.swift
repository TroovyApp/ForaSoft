//
//  CourseNotEnoughMoneyViewController.swift
//  troovy-ios
//
//  Created by Daniil on 09.11.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

import Stripe
import IQKeyboardManager

protocol CourseNotEnoughMoneyDelegate: class {
    func courseNotEnoughMoneyController( _ : CourseNotEnoughMoneyViewController, didSetBankCardWithParameters cardParameters: STPCardParams)
}

class CourseNotEnoughMoneyViewController: TroovyViewController, STPPaymentCardTextFieldDelegate {
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var bankCardTextField: STPPaymentCardTextField!
    @IBOutlet weak var notEnoughLabel: UILabel!
    @IBOutlet weak var enterCardButton: UIButton!
    @IBOutlet weak var bankCardToBottom: NSLayoutConstraint!
    
    // MARK: Public Properties
    
    /// Delegate. Responds to CourseNotEnoughMoneyDelegate.
    weak var delegate: CourseNotEnoughMoneyDelegate?
    
    /// Not enough amount.
    var notEnoughAmount: Double = 0.0
    
    /// User bank card parameters.
    var cardParameters: [String:Any] = [:]
    
    // MARK: Private Properties
    
    private var numberFormatter: NumberFormatter!
    
    private var bankCardToBottomValue: CGFloat = 0.0
    
    // MARK: Init Methods & Superclass Overriders
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupNumberFormatter()
        
        self.notEnoughLabel.text = ApplicationMessages.SuccessMessages.notEnoughMoney(withValueString: self.numberFormatter.string(from: NSNumber(value: self.notEnoughAmount)) ?? "0")
        
        let bankCardParameters = STPCardParams()
        bankCardParameters.number = self.cardParameters["number"] as? String
        bankCardParameters.expMonth = ((self.cardParameters["expMonth"] as? UInt) ?? 0)
        bankCardParameters.expYear = ((self.cardParameters["expYear"] as? UInt) ?? 0)
        bankCardParameters.cvc = self.cardParameters["cvv"] as? String
        
        self.bankCardTextField.isUserInteractionEnabled = false
        self.bankCardTextField.isEnabled = false
        self.bankCardTextField.cardParams = bankCardParameters
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.turnOffKeyboardManager()
        self.configureBankCardTextField()
        self.checkFieldsFilled()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        DispatchQueue.main.async {
            self.bankCardTextField.isUserInteractionEnabled = true
            self.bankCardTextField.isEnabled = true
            self.bankCardTextField.becomeFirstResponder()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.turnOnKeyboardManager()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: Notifications & Observers
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let info = notification.userInfo else {
            return
        }
        
        let keyboardFrame = (info[UIKeyboardFrameEndUserInfoKey] as? CGRect) ?? CGRect.zero
        let animationDuration = (info[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval) ?? 0.0
        
        if self.bankCardToBottomValue == 0.0 {
            self.bankCardToBottomValue = self.bankCardToBottom.constant
        }
        
        if self.bankCardToBottom.constant != keyboardFrame.size.height + 32.0 {
            self.bankCardToBottom.constant = keyboardFrame.size.height + 32.0
            
            UIView.animate(withDuration: animationDuration, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let info = notification.userInfo else {
            return
        }
        
        let animationDuration = (info[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval) ?? 0.0
        
        if self.bankCardToBottom.constant != self.bankCardToBottomValue {
            self.bankCardToBottom.constant = self.bankCardToBottomValue
            
            UIView.animate(withDuration: animationDuration, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
    
    // MARK: Private Methods
    
    private func setupNumberFormatter() {
        self.numberFormatter = NumberFormatter()
        self.numberFormatter.numberStyle = .currency
        self.numberFormatter.currencyCode = "USD"
        self.numberFormatter.minimumFractionDigits = 2
    }
    
    private func turnOnKeyboardManager() {
        IQKeyboardManager.shared().isEnabled = true
        IQKeyboardManager.shared().shouldResignOnTouchOutside = true
    }
    
    private func turnOffKeyboardManager() {
        IQKeyboardManager.shared().isEnabled = false
        IQKeyboardManager.shared().shouldResignOnTouchOutside = false
    }
    
    private func configureBankCardTextField() {
        self.bankCardTextField.cornerRadius = 23.0
        self.bankCardTextField.borderWidth = 0.0
        self.bankCardTextField.font = UIFont.systemFont(ofSize: 14.0)
        self.bankCardTextField.textColor = UIColor.tv_darkColor()
    }
    
    // MARK: Verification Methods
    
    private func checkFieldsFilled() {
         if self.bankCardTextField.isValid {
            self.enterCardButton.enableClearButton()
        } else {
            self.enterCardButton.disableClearButton()
        }
    }
    
    private func checkFieldsInfo() {
        if self.bankCardTextField.isValid  {
            let cardParameters = self.bankCardTextField.cardParams
            
            self.presentingViewController?.dismiss(animated: true, completion: {
                self.delegate?.courseNotEnoughMoneyController(self, didSetBankCardWithParameters: cardParameters)
            })
        } else {
            self.showError()
        }
    }
    
    private func showError() {
        var messages: [String] = []
        
        messages.append(ApplicationMessages.ErrorMessages.wrongBankCard)
        
        if messages.count > 0 {
            self.showAlert(withErrorsMessages: messages)
        }
    }
    
    // MARK: Controls Actions
    
    @IBAction func enterCardButtonAction(_ sender: UIButton) {
        self.bankCardTextField.resignFirstResponder()
        
        self.checkFieldsInfo()
    }
    
    // MARK: Protocols Implementation
    
    // MARK: STPPaymentCardTextFieldDelegate
    
    internal func paymentCardTextFieldDidChange(_ textField: STPPaymentCardTextField) {
        self.checkFieldsFilled()
    }
    
}

