//
//  PhoneVerificationViewController.swift
//  troovy-ios
//
//  Created by Daniil on 18.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

import IQKeyboardManager

class PhoneVerificationViewController: TroovyViewController, UITextFieldDelegate {

    // MARK: Interface Builder Properties
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var requestLabel: UILabel!
    @IBOutlet weak var requestButton: UIButton!
    @IBOutlet weak var requestButtonToBottom: NSLayoutConstraint!
    
    @IBOutlet weak var codeTextField: UITextField!
    @IBOutlet weak var firstNumber: UILabel!
    @IBOutlet weak var secondNumber: UILabel!
    @IBOutlet weak var thirdNumber: UILabel!
    @IBOutlet weak var fourthNumber: UILabel!
    @IBOutlet weak var fifthNumber: UILabel!
    
    @IBOutlet weak var firstNumberLine: UIView!
    @IBOutlet weak var secondNumberLine: UIView!
    @IBOutlet weak var thirdNumberLine: UIView!
    @IBOutlet weak var fourthNumberLine: UIView!
    @IBOutlet weak var fifthNumberLine: UIView!
    
    // MARK: Public Properties
    
    /// Model of the unauthorised user.
    var unauthorisedUserModel: UnauthorisedUserModel!
    
    // MARK: Internal Properties
    
    internal var verificationService: VerificationService!
    internal var unauthorisedUserService: UnauthorisedUserService!
    internal var authorisedUserService: AuthorisedUserService!
    
    internal var verificationCodeSymbols: [String] = []
    
    // MARK: Private Properties
    
    private var requestButtonToBottomValue: CGFloat = 0.0
    
    private var requestTimerSecondsLeft: Int = 0
    private var requestButtonTimer: Timer?
    
    private var confirmationMethodName: String?
    private var requestCodeMethodName: String?
    
    // MARK: Init Methods & Superclass Overriders
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.titleLabel.text = ApplicationMessages.ScreenTitles.verificationScreen
        
        self.configureCodeText()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.turnOffKeyboardManager()
        self.runRequestButtonTimer()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        if self.verificationCodeSymbols.count != self.verificationService.verificationCodeRequiredLength() {
            DispatchQueue.main.async {
                self.codeTextField.becomeFirstResponder()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.turnOnKeyboardManager()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
        
        self.stopRequestButtonTimer()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func inject(propertiesWithAssembly assembly: ViewControllerAssemblyManager) {
        self.verificationService = assembly.verificationService
        self.unauthorisedUserService = assembly.unauthorisedUserService
        self.authorisedUserService = assembly.authorisedUserService
    }
    
    override func configureServices() {
        self.unauthorisedUserService.delegate = self
    }
    
    override func serviceMethodSucceeded(withMethod method: String, resultDictionary: [String : Any]?, resultArray: [[String:Any]]?, resultString: String?) {
        if method == self.confirmationMethodName {
            self.verificationSucceeded(withResult: resultDictionary!)
        } else if method == self.requestCodeMethodName {
            self.runRequestButtonTimer()
        }
    }
    
    // MARK: Notifications & Observers
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let info = notification.userInfo else {
            return
        }
        
        let keyboardFrame = (info[UIKeyboardFrameEndUserInfoKey] as? CGRect) ?? CGRect.zero
        let animationDuration = (info[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval) ?? 0.0
        
        if self.requestButtonToBottomValue == 0.0 {
            self.requestButtonToBottomValue = self.requestButtonToBottom.constant
        }
        
        if self.requestButtonToBottom.constant != keyboardFrame.size.height + 20.0 {
            self.requestButtonToBottom.constant = keyboardFrame.size.height + 20.0
            
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
        
        if self.requestButtonToBottom.constant != self.requestButtonToBottomValue {
            self.requestButtonToBottom.constant = self.requestButtonToBottomValue
            
            UIView.animate(withDuration: animationDuration, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
    
    // MARK: Internal Methods
    
    /// Completes verification process. E.g. registers user, changes phone number, etc. MUST BE OVERRIDDEN.
    internal func verificationSucceeded(withResult result: [String:Any]) {
        fatalError("Must be overridden")
    }
    
    // MARK: Private Methods
    
    // MARK: Setups Methods
    
    private func turnOnKeyboardManager() {
        IQKeyboardManager.shared().isEnabled = true
        IQKeyboardManager.shared().shouldResignOnTouchOutside = true
    }
    
    private func turnOffKeyboardManager() {
        IQKeyboardManager.shared().isEnabled = false
        IQKeyboardManager.shared().shouldResignOnTouchOutside = false
    }
    
    // MARK: Request Timer
    
    private func runRequestButtonTimer() {
        if self.requestButtonTimer != nil {
            return
        }
        
        self.requestTimerSecondsLeft = self.verificationService.requestVerificationCodeInterval()
        self.requestButtonTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (timer) in
            self.requestTimeStep()
        })
        
        self.checkRequestButtonState()
    }
    
    private func stopRequestButtonTimer() {
        self.requestButtonTimer?.invalidate()
        self.requestButtonTimer = nil
        self.requestTimerSecondsLeft = 0
        
        self.checkRequestButtonState()
    }
    
    private func requestTimeStep() {
        self.requestTimerSecondsLeft -= 1
        if self.requestTimerSecondsLeft <= 0 {
            self.stopRequestButtonTimer()
        } else {
            let secondsLeft = "\(self.requestTimerSecondsLeft)"
            self.requestLabel.text = ApplicationMessages.Instructions.requestCode(withSecondsLeft: secondsLeft)
        }
    }
    
    private func checkRequestButtonState() {
        if self.requestButtonTimer == nil {
            self.requestButton.enableButton()
            self.requestLabel.text = nil
        } else {
            self.requestButton.disableButton()
            
            let secondsLeft = "\(self.requestTimerSecondsLeft)"
            self.requestLabel.text = ApplicationMessages.Instructions.requestCode(withSecondsLeft: secondsLeft)
        }
    }
    
    // MARK: Verification Methods
    
    private func checkFieldsInfo() {
        let codeString = self.verificationService.check(verificationCodeSymbols: self.verificationCodeSymbols)
        if codeString != nil {
            self.codeTextField.resignFirstResponder()
            self.confirmationMethodName = self.unauthorisedUserService.confirmPhoneNumber(withUnauthorisedUser: self.unauthorisedUserModel, verificationCode: codeString!)
        } else {
            self.showError(withCodeString: codeString)
        }
    }
    
    private func showError(withCodeString codeString: String?) {
        var messages: [String] = []
        
        if codeString == nil || codeString?.count == 0 {
            messages.append(ApplicationMessages.ErrorMessages.wrongVerificationCode)
        }
        
        if messages.count > 0 {
            self.showAlert(withErrorsMessages: messages)
        }
    }
    
    // MARK: Support Methods
    
    private func configureCodeText() {
        let requiredCodeLength = self.verificationService.verificationCodeRequiredLength()
        var codeString = ""
        var lastLabelWithCode = true
        for index in 0..<requiredCodeLength {
            if let codeLabel = self.codeLabel(withOrder: index), let codeLine = self.codeLine(withOrder: index) {
                if index >= self.verificationCodeSymbols.count {
                    codeLabel.text = nil
                    codeString.append("•")

                    if lastLabelWithCode {
                        lastLabelWithCode = false
                        codeLine.backgroundColor = UIColor.tv_purpleColor()
                    } else {
                        codeLine.backgroundColor = UIColor.tv_grayColor()
                    }
                } else {
                    codeLabel.text = self.verificationCodeSymbols[index]
                    codeString.append(self.verificationCodeSymbols[index])
                    codeLine.backgroundColor = UIColor.tv_purpleColor()
                    
                    lastLabelWithCode = true
                }
            }
        }
        
        self.codeTextField.text = codeString
    }
    
    private func codeLabel(withOrder order: Int) -> UILabel? {
        switch order {
        case 0:
            return self.firstNumber
        case 1:
            return self.secondNumber
        case 2:
            return self.thirdNumber
        case 3:
            return self.fourthNumber
        case 4:
            return self.fifthNumber
        default:
            return nil
        }
    }
    
    private func codeLine(withOrder order: Int) -> UIView? {
        switch order {
        case 0:
            return self.firstNumberLine
        case 1:
            return self.secondNumberLine
        case 2:
            return self.thirdNumberLine
        case 3:
            return self.fourthNumberLine
        case 4:
            return self.fifthNumberLine
        default:
            return nil
        }
    }
    
    // MARK: Controls Actions
    
    @IBAction func requestCodeButtonAction(_ sender: UIButton) {
        self.verificationCodeSymbols.removeAll()
        self.configureCodeText()
        
        self.requestCodeMethodName = self.unauthorisedUserService.requestVerificationCode(withUnauthorisedUser: self.unauthorisedUserModel)
    }
    
    // MARK: Protocols Implementation
    
    // MARK: UITextFieldDelegate
    
    internal func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string == "" {
            if self.verificationCodeSymbols.count > 0 {
                self.verificationCodeSymbols.removeLast()
                self.configureCodeText()
            }
        }
        
        let requiredCodeLength = self.verificationService.verificationCodeRequiredLength()
        if self.verificationCodeSymbols.count != requiredCodeLength {
            if string.count == 1 {
                if let numberString = self.verificationService.check(number: string) {
                    self.verificationCodeSymbols.append(numberString)
                    self.configureCodeText()
                    
                    if self.verificationCodeSymbols.count == requiredCodeLength {
                        self.checkFieldsInfo()
                    }
                }
            }
        }
        
        return false
    }
    
    internal func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if self.verificationCodeSymbols.count == self.verificationService.verificationCodeRequiredLength() {
            self.checkFieldsInfo()
        }
        
        return false
    }

}
