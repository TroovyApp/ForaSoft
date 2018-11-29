
//
//  PaymentService.swift
//  troovy-ios
//
//  Created by Daniil on 03.10.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

import Stripe

class PaymentService: TroovyService {

    private struct PaymentConstants {
        static let commissionPercentage = 0.3
    }
    
    // MARK: Private Properties
    
    private let networkManager = NetworkManager.shared
    private let applicationService = ApplicationService()
    //private let stripeClient = STPAPIClient()
    
    // MARK: Public Methods
    
    /// Returns course commision percentage.
    ///
    /// - returns: Course commision percentage from constants.
    ///
    func courseCommisionPercentage() -> Double {
        if let commissionPercentage = self.applicationService.savedApplicationModel()?.subscribeServiceTax?.doubleValue {
            return commissionPercentage
        }
        
        return PaymentConstants.commissionPercentage
    }
    
    /// Creates stripe token from bank card data.
    ///
    /// - parameter cardParameters: Stripe card parameters.
    /// - returns: Method name.
    ///
//    func createStripeToken(withCardParameters cardParameters: STPCardParams) -> String {
//        let method = "createStripeToken"
//        self.serviceResultChanged(withResult: ServiceActionResult.methodStarted(method: method))
//
//        self.stripeClient.createToken(withCard: cardParameters) { (token, error) in
//            if let tokenID = token?.tokenId {
//                self.serviceResultChanged(withResult: ServiceActionResult.methodSucceededWithMessage(method: method, resultString: tokenID))
//            } else {
//                self.serviceResultChanged(withResult: ServiceActionResult.methodFailed(method: method, error: error?.localizedDescription))
//            }
//        }
//
//        return method
//    }
    
    /// Buys course with balance.
    ///
    /// - parameter courseID: Course server ID.
    /// - parameter coursePrice: Course price.
    /// - parameter user: Authorised user model.
    /// - returns: Method name.
    ///
    func buyCourseWithBalance(withCourseID courseID: String, coursePrice: String, user: AuthorisedUserModel?) -> String {
        let method = "buyCourseWithBalance"
        self.serviceResultChanged(withResult: ServiceActionResult.methodStarted(method: method))
        
        self.networkManager.buyCourse(withNetworkToken: user?.networkToken, courseID: courseID, usingBalanceWithCoursePrice: coursePrice) { (response, errorMessage, isCancelled) -> (Void) in
            if let result = response as? [String:Any] {
                self.serviceResultChanged(withResult: ServiceActionResult.methodSucceededWithResponseDictionary(method: method, resultDictionary: result))
            } else {
                self.serviceResultChanged(withResult: ServiceActionResult.methodFailed(method: method, error: errorMessage))
            }
        }
        
        return method
    }
    
    /// Buys course with wallet
    ///
    /// - parameter courseID: Course server ID.
    /// - parameter coursePrice: Course price.
    /// - parameter user: Authorised user model.
    /// - parameter receiptData: receipt data
    /// - returns: Method name.
    ///
    func buyCourseWithWalletAndValidateReceipt(withCourseID courseID: String, coursePrice: String, receiptData: Data, user: AuthorisedUserModel?) -> String {
        let method = "buyCourseWithWalletAndValidateReceipt"
        self.serviceResultChanged(withResult: ServiceActionResult.methodStarted(method: method))
        
        self.networkManager.buyCourseAndValidateReceipt(withNetworkToken: user?.networkToken, courseID: courseID, usingWalletWithCoursePrice: coursePrice, receiptData: receiptData) { (response, errorMessage, isCancelled) -> (Void) in
            if let result = response as? [String:Any] {
                self.serviceResultChanged(withResult: ServiceActionResult.methodSucceededWithResponseDictionary(method: method, resultDictionary: result))
            } else {
                self.serviceResultChanged(withResult: ServiceActionResult.methodFailed(method: method, error: errorMessage))
            }
        }
        
        return method
    }
    
    /// Requests server to send email receipt for course purchase
    ///
    /// - parameter courseID: Course server ID.
    /// - parameter email: user's e-mail address
    /// - parameter user: Authorised user model.
    /// - returns: Method name.
    ///
    func sendPurchaseConfirmation(withCourseID courseID: String, email: String, user: AuthorisedUserModel?) -> String {
        let method = "sendPurchaseConfirmation"
        self.serviceResultChanged(withResult: ServiceActionResult.methodStarted(method: method))
        
        self.networkManager.sendCoursePurchaseConfirmation(withNetworkToken: user?.networkToken, courseID: courseID, email: email) { (response, errorMessage, isCancelled) -> (Void) in
            if let result = response as? [String:Any] {
                self.serviceResultChanged(withResult: ServiceActionResult.methodSucceededWithResponseDictionary(method: method, resultDictionary: result))
            } else {
                self.serviceResultChanged(withResult: ServiceActionResult.methodFailed(method: method, error: errorMessage))
            }
        }
        
        return method
    }
}
