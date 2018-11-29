//
//  ReportCourseViewController.swift
//  troovy-ios
//
//  Created by Daniil on 02.10.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

import IQKeyboardManager

class ReportCourseViewController: TroovyViewController, UITextViewDelegate {
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var reasonTextView: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var reportContainerToBottom: NSLayoutConstraint!
    
    // MARK: Public Methods
    
    /// Model of the unauthorised user.
    var authorisedUserModel: AuthorisedUserModel!
    
    /// Course server ID.
    var courseID: String!
    
    // MARK: Private Methods
    
    private var verificationService: VerificationService!
    private var createCoursesService: CreateCoursesService!
    
    private var reportContainerToBottomValue: CGFloat = 0.0
    private var reportSended = false
    
    private var reportCourseMethod: String?
    
    // MARK: Init Methods & Superclass Overriders

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.turnOffKeyboardManager()
        self.checkFieldsFilled()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        if !self.reportSended {
            DispatchQueue.main.async {
                self.reasonTextView.becomeFirstResponder()
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
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func inject(propertiesWithAssembly assembly: ViewControllerAssemblyManager) {
        self.verificationService = assembly.verificationService
        self.createCoursesService = assembly.createCoursesService
    }
    
    override func configureServices() {
        self.createCoursesService.delegate = self
    }
    
    override func serviceMethodSucceeded(withMethod method: String, resultDictionary: [String : Any]?, resultArray: [[String:Any]]?, resultString: String?) {
        if method == self.reportCourseMethod {
            self.reportSended = true
            self.showDismissalAlert(withTitle: ApplicationMessages.AlertTitles.success, message: ApplicationMessages.SuccessMessages.report)
        }
    }
    
    // MARK: Notifications & Observers
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let info = notification.userInfo else {
            return
        }
        
        let keyboardFrame = (info[UIKeyboardFrameEndUserInfoKey] as? CGRect) ?? CGRect.zero
        let animationDuration = (info[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval) ?? 0.0
        
        if self.reportContainerToBottomValue == 0.0 {
            self.reportContainerToBottomValue = self.reportContainerToBottom.constant
        }
        
        if self.reportContainerToBottom.constant != keyboardFrame.size.height + 32.0 {
            self.reportContainerToBottom.constant = keyboardFrame.size.height + 32.0
            
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
        
        if self.reportContainerToBottom.constant != self.reportContainerToBottomValue {
            self.reportContainerToBottom.constant = self.reportContainerToBottomValue
            
            UIView.animate(withDuration: animationDuration, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
    
    // MARK: Private Methods
    
    private func turnOnKeyboardManager() {
        IQKeyboardManager.shared().isEnabled = true
        IQKeyboardManager.shared().shouldResignOnTouchOutside = true
    }
    
    private func turnOffKeyboardManager() {
        IQKeyboardManager.shared().isEnabled = false
        IQKeyboardManager.shared().shouldResignOnTouchOutside = false
    }
    
    // MARK: Verification Methods
    
    private func checkFieldsFilled() {
        let reportReason = self.verificationService.check(string: self.reasonTextView.text)
        
        if reportReason != nil {
            self.sendButton.enableClearButton()
        } else {
            self.sendButton.disableClearButton()
        }
    }
    
    private func checkFieldsInfo() {
        let reportReason = self.verificationService.check(string: self.reasonTextView.text)
        
        if reportReason != nil {
            self.reportCourseMethod = self.createCoursesService.reportCourse(withCourseID: self.courseID, reason: reportReason!, user: self.authorisedUserModel)
        } else {
            self.showError(withReportReason: reportReason)
        }
    }
    
    private func showError(withReportReason reportReason: String?) {
        var messages: [String] = []
        
        if reportReason == nil || reportReason?.count == 0 {
            messages.append(ApplicationMessages.ErrorMessages.wrongReportReason)
        }
        
        if messages.count > 0 {
            self.showAlert(withErrorsMessages: messages)
        }
    }
    
    private func showDismissalAlert(withTitle title: String, message: String?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: ApplicationMessages.AlertButtonsTitles.ok, style: .cancel, handler: { [weak self] (action) in
            self?.presentingViewController?.dismiss(animated: true, completion: nil)
        }))
        self.present(alertController, animated: true, completion: nil)
    }
    
    // MARK: Controls Actions
    
    @IBAction func sendButtonAction(_ sender: UIButton) {
        self.checkFieldsInfo()
    }
    
    // MARK: UITextViewDelegate
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText = (textView.text ?? "") as NSString
        let changedText = currentText.replacingCharacters(in: range, with: text)
        textView.text = changedText
        
        self.checkFieldsFilled()
        
        return false
    }
    
    internal func textViewDidEndEditing(_ textView: UITextView) {
        self.checkFieldsFilled()
    }

}
