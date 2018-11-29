//
//  WithdrawalResultModel.swift
//  troovy-ios
//
//  Created by Daniil on 10.11.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import Foundation

struct WithdrawalResultModel {
    
    private struct Keys {
        static let user = "user"
        static let error  = "error"
        
        static let balance = "balance"
        static let message = "message"
    }
    
    // Properties
    
    var succeeded = false
    
    var userDictionary: [String:Any]?
    
    var userBalance: NSDecimalNumber?
    var errorMessage: String?
    
    // MARK: Init Methods & Superclass Overriders
    
    init(withDictionary dictionary: [String:Any]?) {
        if let error = dictionary?[Keys.error] as? [String:Any] {
            var balance: NSDecimalNumber?
            if let balanceString = error[Keys.balance] as? String {
                balance = NSDecimalNumber(string: balanceString)
            } else if let balanceValue = error[Keys.balance] as? Double {
                balance = NSDecimalNumber(value: balanceValue)
            }
            
            self.succeeded = false
            self.userBalance = balance
            self.errorMessage = (error[Keys.message] as? String)
            self.userDictionary = nil
        } else {
            self.succeeded = true
            self.userBalance = nil
            self.errorMessage = nil
            self.userDictionary = (dictionary?[Keys.user] as? [String:Any])
        }
    }
    
}
