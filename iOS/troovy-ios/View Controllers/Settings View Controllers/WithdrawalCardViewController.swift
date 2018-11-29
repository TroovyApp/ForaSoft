//
//  WithdrawalCardViewController.swift
//  troovy-ios
//
//  Created by Daniil on 09.11.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

import Stripe
import IQKeyboardManager

protocol WithdrawalCardDelegate: class {
    func withdrawalController( _ : WithdrawalCardViewController, didSetBankCardWithNumber number: String, amount: String)
}

class WithdrawalCardViewController: TroovyViewController, UITextFieldDelegate {
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var bankCardFakeTextField: STPPaymentCardTextField!
    @IBOutlet weak var bankCardTextField: UITextField!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var enterCardButton: UIButton!
    @IBOutlet weak var bankCardToBottom: NSLayoutConstraint!
    
    // MARK: Public Properties
    
    /// Delegate. Responds to WithdrawalCardDelegate.
    weak var delegate: WithdrawalCardDelegate?
    
    /// Current user available balance.
    var currentBalance: String?
    
    // MARK: Private Properties
    
    private var bankCardToBottomValue: CGFloat = 0.0
    private var numberFormatter: NumberFormatter!
    
    // MARK: Init Methods & Superclass Overriders

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupNumberFormatter()
        
        self.amountTextField.text = self.currentBalance
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.turnOffKeyboardManager()
        self.configureBankCardTextField()
        self.checkFieldsFilled()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        DispatchQueue.main.async {
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
        numberFormatter.maximumFractionDigits = 2
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
        self.bankCardFakeTextField.cornerRadius = 23.0
        self.bankCardFakeTextField.borderWidth = 0.0
        self.bankCardFakeTextField.font = self.bankCardTextField.font
        self.bankCardFakeTextField.textColor = self.bankCardTextField.textColor
        
        for subview in self.bankCardFakeTextField.subviews {
            if String(describing: type(of: subview)) == "UIView" {
                let subviews = subview.subviews
                for index in 1..<subviews.count {
                    if let textField = subviews[index] as? UITextField {
                        textField.delegate = self
                        textField.isHidden = true
                    }
                }
                break
            }
        }
    }
    
    private func searchCardNumberTextField() -> UITextField? {
        for subview in self.bankCardFakeTextField.subviews {
            if String(describing: type(of: subview)) == "UIView" {
                let subviews = subview.subviews
                if let textField = subviews.first as? UITextField {
                    return textField
                }
            }
        }
        
        return nil
    }
    
    // MARK: Verification Methods
    
    private func checkFieldsFilled() {
        if self.bankCardFakeTextField.cardNumber != nil && self.bankCardFakeTextField.cardNumber?.count != 0 && self.amountTextField.text != nil && self.amountTextField.text?.count != 0 {
            self.enterCardButton.enableClearButton()
        } else {
            self.enterCardButton.disableClearButton()
        }
    }
    
    private func checkFieldsInfo() {
        var creditCardNumber: String?
        if let number = self.bankCardFakeTextField.cardNumber {
            let validationState = STPCardValidator.validationState(forNumber: number, validatingCardBrand: false)
            if validationState == .valid {
                creditCardNumber = STPCardValidator.sanitizedNumericString(for: number)
            }
        }

        var amountOfCredits: String?
        if let amount = self.amountTextField.text {
            let number = NSDecimalNumber(string: amount)
            if number.doubleValue != 0.0 {
                amountOfCredits = numberFormatter.string(from: number)
            }
        }
        
        if let number = creditCardNumber, let amount = amountOfCredits {
            self.presentingViewController?.dismiss(animated: true, completion: {
                self.delegate?.withdrawalController(self, didSetBankCardWithNumber: number, amount: amount)
            })
        } else {
            self.showError(wrongWallet: (creditCardNumber == nil), wrongAmount: (amountOfCredits == nil))
        }
    }
    
    private func showError(wrongWallet: Bool, wrongAmount: Bool) {
        var messages: [String] = []
        
        if wrongWallet {
            messages.append(ApplicationMessages.ErrorMessages.wrongBankCard)
        }
        
        if wrongAmount {
            messages.append(ApplicationMessages.ErrorMessages.wrongAmount)
        }
        
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
    
    // MARK: UITextFieldDelegate
    
    internal func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == self.bankCardTextField {
            if let textFieldText = textField.text {
                let newText = (textFieldText as NSString).replacingCharacters(in: range, with: string)
                textField.text = newText
            } else {
                textField.text = string
            }
            
            if let creditCardNumberTextField = self.searchCardNumberTextField() {
                creditCardNumberTextField.text = textField.text
                textField.attributedText = creditCardNumberTextField.attributedText
            }
            
            self.checkFieldsFilled()
            return false
        } else if textField == self.amountTextField {
            if let textFieldText = textField.text {
                let newText = (textFieldText as NSString).replacingCharacters(in: range, with: string)
                
                var result = false
                
                if newText == "" {
                    result = true
                } else {
                    result = newText.isValidDouble(maxDecimalPlaces: 2)
                }
                
                if result {
                    textField.text = newText
                    self.checkFieldsFilled()
                }
                return false
            } else {
                textField.text = string
            }

            self.checkFieldsFilled()
            return false
        }
        
        return true
    }
    
    internal func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return !textField.isHidden
    }
    
    internal func textFieldDidEndEditing(_ textField: UITextField) {
        self.checkFieldsFilled()
    }
    
}
