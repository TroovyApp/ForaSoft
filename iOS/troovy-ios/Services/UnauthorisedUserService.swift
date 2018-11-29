//
//  UnauthorisedUserService.swift
//  troovy-ios
//
//  Created by Daniil on 17.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import Foundation

class UnauthorisedUserService: TroovyService {
    
    private struct UserDefaultsKeys {
        static let tutorialPassed = "troovy_tutorialPassed"
    }
    
    // Private Properties
    
    private let networkManager = NetworkManager.shared
    
    // Public Methods
    
    /// Checks if tutorial passed.
    ///
    /// - returns: True if tutorial passed, and false otherwise.
    ///
    func isTutorialPassed() -> Bool {
        let tutorialPassed = UserDefaults.standard.bool(forKey: UserDefaultsKeys.tutorialPassed)
        return tutorialPassed
    }
    
    /// Sets tutorial as passed.
    func setTutorialPassed() {
        UserDefaults.standard.set(true, forKey: UserDefaultsKeys.tutorialPassed)
        UserDefaults.standard.synchronize()
    }
    
    /// Requests sms with verification code.
    ///
    /// - parameter user: User model, kind of UnauthorisedUserModel.
    ///
    func requestVerificationCode(withUnauthorisedUser user: UnauthorisedUserModel) -> String {
        let method = "requestVerificationCode"
        self.serviceResultChanged(withResult: ServiceActionResult.methodStarted(method: method))
        
        self.networkManager.requestVerificationCode(withUserToken: user.userToken, callingCode: user.callingCode!, phoneNumber: user.phoneNumber!) { (response, errorMessage, isCancelled) -> (Void) in
            if response != nil {
                self.serviceResultChanged(withResult: ServiceActionResult.methodSucceeded(method: method))
            } else {
                self.serviceResultChanged(withResult: ServiceActionResult.methodFailed(method: method, error: errorMessage))
            }
        }
        return method
    }
    
    /// Confirms phone number. Gets user info if already registered.
    ///
    /// - parameter user: User model, kind of UnauthorisedUserModel.
    /// - parameter verificationCode: Verification code from sms.
    ///
    func confirmPhoneNumber(withUnauthorisedUser user: UnauthorisedUserModel, verificationCode: String) -> String {
        let method = "confirmPhoneNumber"
        self.serviceResultChanged(withResult: ServiceActionResult.methodStarted(method: method))
        
        self.networkManager.confirmPhoneNumber(withUserToken: user.userToken, verificationCode: verificationCode) { (response, errorMessage, isCancelled) -> (Void) in
            if let result = response as? [String:Any] {
                self.serviceResultChanged(withResult: ServiceActionResult.methodSucceededWithResponseDictionary(method: method, resultDictionary: result))
            } else {
                self.serviceResultChanged(withResult: ServiceActionResult.methodFailed(method: method, error: errorMessage))
            }
        }
        return method
    }
    
    /// Registers user.
    ///
    /// - parameter user: User model, kind of UnauthorisedUserModel.
    ///
    func registerUser(withUnauthorisedUser user: UnauthorisedUserModel) -> String {
        let method = "registerUser"
        self.serviceResultChanged(withResult: ServiceActionResult.methodStarted(method: method))
        
        self.networkManager.registerUser(withUserToken: user.userToken, callingCode: user.callingCode!, phoneNumber: user.phoneNumber!, username: user.username!, profilePicture: user.profilePicture) { (response, errorMessage, isCancelled) -> (Void) in
            if let result = response as? [String:Any] {
                self.serviceResultChanged(withResult: ServiceActionResult.methodSucceededWithResponseDictionary(method: method, resultDictionary: result))
            } else {
                self.serviceResultChanged(withResult: ServiceActionResult.methodFailed(method: method, error: errorMessage))
            }
        }
        return method
    }
    
}
