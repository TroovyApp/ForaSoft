//
//  PaymentResultModel.swift
//  troovy-ios
//
//  Created by Daniil on 13.10.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import Foundation

struct PaymentResultModel {
    
    private struct Keys {
        static let error  = "error"
        static let balance = "credits"
    }
    
    // Properties
    
    var finished = false
    var userBalance: NSDecimalNumber?
    
    // MARK: Init Methods & Superclass Overriders
    
    init(withDictionary dictionary: [String:Any]?) {
        if let error = dictionary?[Keys.error] as? [String:Any] {
            self.finished = false

            var balance: NSDecimalNumber?
            if let balanceString = error[Keys.balance] as? String {
                balance = NSDecimalNumber(string: balanceString)
            } else if let balanceValue = error[Keys.balance] as? Double {
                balance = NSDecimalNumber(value: balanceValue)
            }
            self.userBalance = balance
        } else {
            self.finished = true
            self.userBalance = nil
        }
    }
    
}
