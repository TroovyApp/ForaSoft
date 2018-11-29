//
//  CoursePaymentViewController.swift
//  troovy-ios
//
//  Created by Daniil on 03.10.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit
import StoreKit

class CoursePaymentViewController: TroovyViewController, AuthorisedUserModelDelegate, CourseModelDelegate, UIScrollViewDelegate, UITextFieldDelegate {
    
    //CourseNotEnoughMoneyDelegate
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var topSeparatorView: UIView!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var walletLabel: UILabel!
    @IBOutlet weak var buyButton: UIButton!
    @IBOutlet weak var segmentedControl: SPSegmentedControl!
    @IBOutlet weak var emailTextField: RoundedTextField!
    @IBOutlet weak var accountView: UIView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var notEnoughBalanceLabel: UILabel!
    
    // MARK: Public Properties
    
    /// Model of the authorised user.
    var authorisedUserModel: AuthorisedUserModel! {
        willSet {
            self.authorisedUserModel?.removeDelegate(self)
        }
        didSet {
            self.authorisedUserModel?.delegate = self
        }
    }
    
    /// Model of the course.
    var courseModel: CourseModel! {
        willSet {
            self.courseModel?.removeDelegate(self)
        }
        didSet {
            self.courseModel?.delegate = self
        }
    }
    
    // MARK: Private Properties
    private var verificationService: VerificationService!
    private var paymentService: PaymentService!
    private var coursesService: CoursesService!
    private var authorisedUserService: AuthorisedUserService!
    
    // MARK: In-app purchase
    private var products = [SKProduct]()
    
    private var numberFormatter: NumberFormatter!
    
    private var cardAmountValue: String?
    private var buyCourseWithBalance: String?
    private var sendPurchaseConfirmation: String?
    private var buyCourseWithWalletAndValidateReceipt: String?
    
    
    // MARK: Init Methods & Superclass Overriders

    override func viewDidLoad() {
        super.viewDidLoad()
        self.verificationService = VerificationService()
        
        self.titleLabel.text = ApplicationMessages.ScreenTitles.buyCourseScreen

        self.setupNumberFormatter()
        self.setupSegmentedControl()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.structPaymentPage()
        self.checkFieldsFilled()
        self.subscribeToProductUpdates()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.courseModel.removeDelegate(self)
        self.authorisedUserModel.removeDelegate(self)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.configureSeparatorsStateForScroll()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func inject(propertiesWithAssembly assembly: ViewControllerAssemblyManager) {
        self.paymentService = assembly.paymentService
        self.coursesService = assembly.coursesService
        self.authorisedUserService = assembly.authorisedUserService
    }
    
    override func configureServices() {
        self.paymentService.delegate = self
    }
    
    override func showLoadingView(withMethod method: String) {
        if method == self.buyCourseWithBalance {
            self.showLoadingView()
        } else {
            super.showLoadingView(withMethod: method)
        }
    }
    
    override func serviceMethodSucceeded(withMethod method: String, resultDictionary: [String : Any]?, resultArray: [[String : Any]]?, resultString: String?) {
        if method == self.buyCourseWithBalance  {
            if let result = resultDictionary {
                let paymentResultModel = PaymentResultModel(withDictionary: result)
                if paymentResultModel.finished {
                    self.courseModel.update(withSubscribed: true)
                    self.coursesService.updateCourse(withModel: self.courseModel)
                    
                    if let balance = paymentResultModel.userBalance {
                        self.authorisedUserModel.update(withCredits: balance)
                        self.authorisedUserService.rememberUser(withUserModel: self.authorisedUserModel)
                    } else if let price = self.courseModel.price, price != NSDecimalNumber.notANumber {
                        let priceFromCard = NSDecimalNumber(string: self.cardAmountValue)
                        let priceFromWallet = price.subtracting(priceFromCard)
                        
                        self.authorisedUserModel.update(withCoursePrice: priceFromWallet)
                        self.authorisedUserService.rememberUser(withUserModel: self.authorisedUserModel)
                    }
                    
                    NotificationCenter.default.post(name: Notification.Name(CreateCoursesNotificationNames.subscribedSessionsChanged), object: nil)
                    
                    if let email = emailTextField.text {
                        sendSubscriptionConfirmation(withEmail: email)
                    }
                    
                } else {
                    guard let price = self.courseModel.price, let balance = paymentResultModel.userBalance else {
                        return
                    }
                    
                    self.authorisedUserModel.update(withCredits: balance)
                    self.authorisedUserService.rememberUser(withUserModel: self.authorisedUserModel)
                    
                    var amountValue = price.doubleValue - balance.doubleValue
                    if amountValue < 0.0 {
                        amountValue = 0.0
                    }
                    self.showNotEnoughAlert(withCardAmountValue: amountValue)
                }
            }
        } else if method == self.sendPurchaseConfirmation  {
            hideLoadingView(withMethod: method)
            if let result = resultDictionary {
                self.authorisedUserModel.update(withDictionary: result)
                if let courseTitle = courseModel.title, let courseAuthor = courseModel.creatorName, let email = authorisedUserModel.email {
                    
                    let message = ApplicationMessages.SuccessMessages.successfulPurchase(withCourseName: courseTitle, author: courseAuthor, email: email)
                    self.sendPurchaseConfirmation = nil
                    self.showDismissalAlert(withTitle: ApplicationMessages.AlertTitles.success, message: message, completion: { [weak self]() in
                        self?.router.showScheduleScreen()
                    })
                }
            }
        } else if method == self.buyCourseWithWalletAndValidateReceipt {
            hideLoadingView(withMethod: method)
            self.courseModel.update(withSubscribed: true)
            self.coursesService.updateCourse(withModel: self.courseModel)
            
            if let email = emailTextField.text {
                sendSubscriptionConfirmation(withEmail: email)
            }
        }
    }

    
    private func sendSubscriptionConfirmation(withEmail email: String) {
        if self.sendPurchaseConfirmation != nil { return }
        
        if let courseID = self.courseModel.id, let userModel = self.authorisedUserModel {
            self.sendPurchaseConfirmation = self.paymentService.sendPurchaseConfirmation(withCourseID: courseID, email: email, user: userModel)
            showLoadingView(withMessage: ApplicationMessages.Instructions.sendingEmailConfirmation)
        } else {
            self.showDismissalAlert(withTitle: ApplicationMessages.AlertTitles.error, message: ApplicationMessages.ErrorMessages.wrongCourseData)
        }
    }
    
    private func setupNumberFormatter() {
        self.numberFormatter = NumberFormatter()
        self.numberFormatter.numberStyle = .currency
        if let currency = TroovyProducts.shared.getCurrentCurrency(), let locale = TroovyProducts.shared.getCurrentCurrencyLocale() {
            self.numberFormatter.currencyCode = currency
            self.numberFormatter.locale = locale
        }
        self.numberFormatter.minimumFractionDigits = 2
    }
    
    @IBAction func textFieldDidChange(_ sender: UITextField) {
        checkFieldsFilled()
    }
    
    private func structPaymentPage() {
        self.priceLabel.text = self.numberFormatter.string(from: self.courseModel.price ?? NSDecimalNumber.zero)
        self.walletLabel.text = self.numberFormatter.string(from: self.authorisedUserModel.credits)
        self.emailTextField.text = self.authorisedUserModel.email
        
        self.configureSeparatorsStateForScroll()
    }
    
    private func configureSeparatorsStateForScroll() {
        self.topSeparatorView.isHidden = !(self.scrollView.contentOffset.y >= 19.0)
    }
    
    private func configureNotEnoughBalanceError(enoughBalance: Bool) {
        UIView.animate(withDuration: 0.25, delay: 0, options: [], animations: { [weak self]() in
            self?.notEnoughBalanceLabel.alpha = enoughBalance ? 0.0 : 1.0
        }, completion: nil)
        walletLabel.textColor = enoughBalance ? UIColor.tv_lightGrayTextColor() : UIColor.tv_redTextColor()
    }
    
    // MARK: Verification Methods
    
    private func checkFieldsFilled() {
        let email = verificationService.check(email: emailTextField.text)
        let emailNotNull = (email != nil)
        var enoughBalance = false
        var buttonEnabled = false
        
        // Pay with balance
        if segmentedControl.selectedIndex == 1 {
            if let coursePrice = self.courseModel.price, let accountBalance = self.authorisedUserModel.credits {
                enoughBalance = (accountBalance.compare(coursePrice) != .orderedAscending)
            }
            
            // Make error message visible or not
            configureNotEnoughBalanceError(enoughBalance: enoughBalance)
            buttonEnabled = emailNotNull && enoughBalance
        } else {
            // Pay with wallet
            configureNotEnoughBalanceError(enoughBalance: true)
            buttonEnabled = emailNotNull
        }
        
        if buttonEnabled {
            buyButton.enableButton()
        } else {
            buyButton.disableButton()
        }
    }
    
    private func checkFieldsInfo(andBuyWithBalance withBalance: Bool, withWallet: Bool) {
        guard let coursePrice = self.courseModel.price?.stringValue else {
            return
        }
        
        if withBalance {
            self.cardAmountValue = "0"
            self.buyCourseWithBalance = self.paymentService.buyCourseWithBalance(withCourseID: self.courseModel.id, coursePrice: coursePrice, user: self.authorisedUserModel)
        } else if withWallet {
            if let priceTier = self.courseModel.priceTier {
                self.cardAmountValue = coursePrice
                showLoadingView()
                TroovyProducts.shared.buyProduct(priceTier)
            }
        }
    }
    
    private func showError(buyWithWallet withWallet: Bool, withCard: Bool) {
        var messages: [String] = []
        
        if withWallet {
            messages.append(ApplicationMessages.ErrorMessages.wrongWallet)
        } else {
            messages.append(ApplicationMessages.ErrorMessages.wrongBankCard)
        }
        
        if messages.count > 0 {
            self.showAlert(withErrorsMessages: messages)
        }
    }
    

    
    private func showNotEnoughAlert(withCardAmountValue value: Double) {
        
        //TODO
    }
    
    private func showDismissalAlert(withTitle title: String, message: String?, completion: @escaping () -> Void) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: ApplicationMessages.AlertButtonsTitles.ok, style: .cancel, handler: {[weak self](action) in
            self?.presentingViewController?.dismiss(animated: true, completion: {
                completion()
            })
            
        }))
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func showDismissalAlert(withTitle title: String, message: String?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: ApplicationMessages.AlertButtonsTitles.ok, style: .cancel, handler: { [weak self] (action) in
            
            self?.presentingViewController?.dismiss(animated: true, completion: nil)
        }))
        self.present(alertController, animated: true, completion: nil)
    }
    
    // MARK: Controls Actions
    
    @IBAction func buyButtonAction(_ sender: UIButton) {
        if segmentedControl.selectedIndex == 0 {
            self.checkFieldsInfo(andBuyWithBalance: false, withWallet: true)
        } else {
            self.checkFieldsInfo(andBuyWithBalance: true, withWallet: false)
        }
    }
    
    // MARK: Protocols Implementation
    
    // MARK: CourseModelDelegate
    
    internal func courseChagned(course: CourseModel) {
        if self.courseModel.id == course.id {
            self.priceLabel.text = self.numberFormatter.string(from: self.courseModel.price ?? NSDecimalNumber.zero)
        }
    }
    
    // MARK: AuthorisedUserModelDelegate
    
    internal func authorisedUserChagned(user: AuthorisedUserModel) {
        if self.authorisedUserModel.id == user.id {
            self.walletLabel.text = self.numberFormatter.string(from: user.credits)
        }
    }
    
    // MARK: UIScrollViewDelegate
    
    internal func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.configureSeparatorsStateForScroll()
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

}

extension CoursePaymentViewController: SPSegmentControlCellStyleDelegate, SPSegmentControlDelegate {
    
    private func setupSegmentedControl() {
        segmentedControl.layer.borderColor = UIColor.clear.cgColor
        segmentedControl.backgroundColor = UIColor.tv_grayLightColor()
        segmentedControl.styleDelegate = self
        segmentedControl.delegate = self
        segmentedControl.indicatorView.backgroundColor = UIColor.tv_purpleColor()
        
        let xFirstCell = self.createCell(
            text: ApplicationMessages.ButtonsTitles.payWithWallet,
            image: nil
        )
//        let xSecondCell = self.createCell(
//            text: ApplicationMessages.ButtonsTitles.payWithBalance,
//            image: nil
//        )

        for cell in [xFirstCell] {
            cell.layout = .onlyText
            self.segmentedControl.add(cell: cell)
        }
    }
    
    private func createCell(text: String, image: UIImage?) -> SPSegmentedControlCell {
        let cell = SPSegmentedControlCell.init()
        cell.label.text = text
        cell.label.font = UIFont.tv_SemiBoldFontOfSize(12.0)
        cell.imageView.image = image
        return cell
    }
    
    private func processSelectedIndex(_ index: Int) {
        let text = segmentedControl.cells[segmentedControl.selectedIndex].label.text?.uppercased()
        buyButton.setTitle(text, for: .normal)
        checkFieldsFilled()
        
        UIView.animate(withDuration: 0.25, delay: 0, options: [], animations: { [weak self]() in
            
            //UIStackView bug fix for multiples times hidden setting
            if index == 0 {
                if self?.accountView.isHidden == false {
                    self?.accountView.isHidden = true
                }
            } else if index == 1 {
                if self?.accountView.isHidden == true {
                    self?.accountView.isHidden = false
                }
            }
            self?.stackView?.layoutIfNeeded()
        }, completion: nil)
    }
    
    func selectedState(segmentControlCell: SPSegmentedControlCell, forIndex index: Int) {
        
        UIView.transition(with: segmentControlCell.label, duration: 0.1, options: [.transitionCrossDissolve, .beginFromCurrentState], animations: {
            segmentControlCell.label.textColor = UIColor.white
        }, completion: nil)
        
        processSelectedIndex(index)
    }
    
    func normalState(segmentControlCell: SPSegmentedControlCell, forIndex index: Int) {
        
        UIView.transition(with: segmentControlCell.label, duration: 0.1, options: [.transitionCrossDissolve, .beginFromCurrentState], animations: {
            segmentControlCell.label.textColor = UIColor.tv_darkTextColor()
        }, completion: nil)
    }
    
    private func subscribeToProductUpdates() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleTroovyProductsNotification(_:)),
                                               name: NSNotification.Name(rawValue: TroovyProducts.TroovyProductsDidMakePurchaseNotification),
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleTroovyProductsNotification(_:)),
                                               name: NSNotification.Name(rawValue: TroovyProducts.TroovyProductsFailPurchaseNotification),
                                               object: nil)
    }
    
    private func buyCourseWithWalletAndValidate() {
        if let receiptURL = Bundle.main.appStoreReceiptURL {
            do {
                let receipt = try Data.init(contentsOf: receiptURL)
                //TODO: Refactor this
                self.buyCourseWithWalletAndValidateReceipt = paymentService.buyCourseWithWalletAndValidateReceipt(withCourseID: courseModel.id, coursePrice: (courseModel.price?.stringValue)!, receiptData: receipt, user: authorisedUserModel)
                
                showLoadingView(withMessage: ApplicationMessages.Instructions.courseValidation)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    // MARK: NSNotificationCenter
    
    @objc func handleTroovyProductsNotification(_ notification: Notification) {
        if notification.name.rawValue == TroovyProducts.TroovyProductsDidMakePurchaseNotification {
            hideLoadingView(withMethod: "")
            if let purchasedPriceTierID = notification.object as? String,
                let coursePriceTier = courseModel.priceTier,
                purchasedPriceTierID == coursePriceTier{
                
                buyCourseWithWalletAndValidate()
            }
        } else if notification.name.rawValue == TroovyProducts.TroovyProductsFailPurchaseNotification {
            hideLoadingView(withMethod: "")
            
            if let userInfo = notification.userInfo, let errorMessage = userInfo["error"] as? String {
                self.showAlert(withTitle: ApplicationMessages.AlertTitles.error, message: errorMessage)
            }
        }
    }
}
