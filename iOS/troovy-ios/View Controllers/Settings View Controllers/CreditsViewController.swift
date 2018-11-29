//
//  CreditsViewController.swift
//  troovy-ios
//
//  Created by Daniil on 30.10.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class CreditsViewController: TroovyViewController, AuthorisedUserModelDelegate, WithdrawalCardDelegate {
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var availableBalanceLabel: UILabel!
    @IBOutlet weak var totalBalanceLabel: UILabel!
    @IBOutlet weak var pendingBalanceLabel: UILabel!
    
    // MARK: Public Properties
    
    /// Model of the unauthorised user.
    var authorisedUserModel: AuthorisedUserModel! {
        willSet {
            self.authorisedUserModel?.removeDelegate(self)
        }
        didSet {
            self.authorisedUserModel?.delegate = self
        }
    }
    
    // MARK: Private Properties
    
    private var authorisedUserService: AuthorisedUserService!
    
    private var numberFormatter: NumberFormatter!
    
    private var requestWithdrawalMethod: String?

    // MARK: Init Methods & Superclass Overriders
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = nil
        self.titleLabel.text = ApplicationMessages.ScreenTitles.balanceScreen
        
        self.setupNumberFormatter()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.configureBalance()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func inject(propertiesWithAssembly assembly: ViewControllerAssemblyManager) {
        self.authorisedUserService = assembly.authorisedUserService
    }
    
    override func configureServices() {
        self.authorisedUserService.delegate = self
    }
    
    override func serviceMethodSucceeded(withMethod method: String, resultDictionary: [String : Any]?, resultArray: [[String : Any]]?, resultString: String?) {
        if method == self.requestWithdrawalMethod {
            if let result = resultDictionary {
                let withdrawalResultModel = WithdrawalResultModel(withDictionary: result)
                if withdrawalResultModel.succeeded {
                    if let userDictionary = withdrawalResultModel.userDictionary {
                        self.authorisedUserModel.update(withDictionary: userDictionary)
                        self.authorisedUserService.rememberUser(withUserModel: self.authorisedUserModel)
                    }
                } else {
                    if let userBalance = withdrawalResultModel.userBalance {
                        self.authorisedUserModel.update(withCredits: userBalance)
                        self.authorisedUserService.rememberUser(withUserModel: self.authorisedUserModel)
                    }
                    
                    if let errorMessage = withdrawalResultModel.errorMessage {
                        self.showAlert(withTitle: ApplicationMessages.AlertTitles.message, message: errorMessage)
                    }
                }
            }
        }
    }
    
    // MARK: Private Methods
    
    private func setupNumberFormatter() {
        self.numberFormatter = NumberFormatter()
        self.numberFormatter.numberStyle = .currency
        
        if let currencyCode = authorisedUserModel.currency {
            self.numberFormatter.currencyCode = currencyCode
        } else if let currencyCode = TroovyProducts.shared.getCurrentCurrency() {
            self.numberFormatter.currencyCode = currencyCode
        }
        
        if let locale = TroovyProducts.shared.getCurrentCurrencyLocale() {
            self.numberFormatter.locale = locale
        }
        
        self.numberFormatter.minimumFractionDigits = 2
        self.numberFormatter.maximumFractionDigits = 2
    }
    
    private func configureBalance() {
        let credits = self.authorisedUserModel.credits ?? NSDecimalNumber.zero
        let creditsString = self.numberFormatter.string(from: credits)
        self.availableBalanceLabel.text = creditsString
        
        let reservedCredits = self.authorisedUserModel.reservedCredits ?? NSDecimalNumber.zero
        let reservedCreditsString = self.numberFormatter.string(from: reservedCredits)
        self.pendingBalanceLabel.text = reservedCreditsString
        
        let totalCredits = credits.adding(reservedCredits)
        let totalCreditsString = self.numberFormatter.string(from: totalCredits)
        self.totalBalanceLabel.text = totalCreditsString
    }
    
    // MARK: Controls Actions
    
    @IBAction func requestWithdrawalButtonAction(_ sender: UIButton) {
        if let number = self.authorisedUserModel.credits, number.doubleValue != 0.0 {
            let balanceFormatter = NumberFormatter()
            balanceFormatter.maximumFractionDigits = 2
            let currentBalance = balanceFormatter.string(from: number)
            self.router.showWithdrawalCardViewController(withAuthorisedUserModel: self.authorisedUserModel, currentBalance: currentBalance, delegate: self)
        } else {
            self.router.showWithdrawalCardViewController(withAuthorisedUserModel: self.authorisedUserModel, currentBalance: nil, delegate: self)
        }
    }
    
    // MARK: Protocols Implementation
    
    // MARK: AuthorisedUserModelDelegate
    
    internal func authorisedUserChagned(user: AuthorisedUserModel) {
        if self.authorisedUserModel.id == user.id {
            self.configureBalance()
        }
    }
    
    // MARK: WithdrawalCardDelegate
    
    internal func withdrawalController( _ : WithdrawalCardViewController, didSetBankCardWithNumber number: String, amount: String) {
        self.requestWithdrawalMethod = self.authorisedUserService.requestWithdrawal(withModel: self.authorisedUserModel, amountCredits: amount, bankAccountNumber: number)
    }

}
