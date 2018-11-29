//
//  AuthorisedUserService.swift
//  troovy-ios
//
//  Created by Daniil on 11.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import Foundation

class AuthorisedUserService: TroovyService {
    
    private struct UserDefaultsKeys {
        static let authorisedUserModel = "troovy_authorisedUserModel"
    }
    
    // MARK: Private Proeprties
    
    private var userModel: AuthorisedUserModel?
    
    private let networkManager = NetworkManager.shared
    
    private var loadUsersTask: URLSessionTask?
    
    // MARK: Init Methods & Superclass Overriders
    
    override init() {
        super.init()
        
        self.userModel = self.loadUserModel()
    }
    
    // MARK: Public Methods
    
    /// Checks if user authorised.
    ///
    /// - returns: True if user authorised, and false otherwise.
    ///
    func isUserAuthorised() -> Bool {
        return (self.userModel != nil)
    }
    
    /// Returns authorised user. Check is user authorised before call. Will crash if user doesn't exist.
    ///
    /// - returns: Model of the authorised user model.
    ///
    func currentAuthorisedUser() -> AuthorisedUserModel {
        if let model = self.userModel {
            return model
        }
        
        fatalError("Authorised user not found. Call isUserAuthorised() before currentAuthorisedUser().")
    }
    
    /// Deletes saved authorised user model.
    func deauthoriseUser() {
        if self.isUserAuthorised() {
            self.networkManager.logout(withNetworkToken: self.currentAuthorisedUser().networkToken)
        }
        
        self.removeUserModel()
    }
    
    /// Saves authorised user model.
    ///
    /// - parameter model: Model of the authorised user model.
    ///
    func rememberUser(withUserModel model: AuthorisedUserModel) {
        self.saveUserModel(model)
    }
    
    /// Loads user info.
    ///
    /// - parameter user: Authorised user model.
    /// - returns: Method name.
    ///
    func loadRegisteredUser(withModel user: AuthorisedUserModel) -> String {
        let method = "loadRegisteredUser"
        self.serviceResultChanged(withResult: ServiceActionResult.methodStarted(method: method))
        
        self.networkManager.loadRegisteredUser(withNetworkToken: user.networkToken, userID: user.id) { (response, errorMessage, isCancelled) -> (Void) in
            if let responseDictionary = response as? [String:Any] {
                self.serviceResultChanged(withResult: ServiceActionResult.methodSucceededWithResponseDictionary(method: method, resultDictionary: responseDictionary))
            } else {
                self.serviceResultChanged(withResult: ServiceActionResult.methodFailed(method: method, error: errorMessage))
            }
        }
        
        return method
    }
    
    /// Requests withdrawal and block credits.
    ///
    /// - parameter user: Authorised user model.
    /// - parameter amountCredits: Amount of credits to block.
    /// - parameter bankAccountNumber: Bank account number to withdraw.
    /// - returns: Method name.
    ///
    func requestWithdrawal(withModel user: AuthorisedUserModel, amountCredits: String, bankAccountNumber: String) -> String {
        let method = "requestWithdrawal"
        self.serviceResultChanged(withResult: ServiceActionResult.methodStarted(method: method))
        
        self.networkManager.requestWithdrawal(withNetworkToken: user.networkToken, amountCredits: amountCredits, bankAccountNumber: bankAccountNumber) { (response, errorMessage, success) -> (Void) in
            if let responseDictionary = response as? [String:Any] {
                self.serviceResultChanged(withResult: ServiceActionResult.methodSucceededWithResponseDictionary(method: method, resultDictionary: responseDictionary))
            } else {
                self.serviceResultChanged(withResult: ServiceActionResult.methodFailed(method: method, error: errorMessage))
            }
        }
        
        return method
    }
    
    /// Edits user.
    ///
    /// - parameter user: Authorised user model.
    /// - parameter username: Username.
    /// - parameter email: Email
    /// - parameter profilePicture: Profile picture.
    /// - parameter shouldDeletePicture: True if user deleted his profile picture. False otherwise.
    ///
    func editUser(withModel user: AuthorisedUserModel, username: String?, email: String?, profilePicture: UIImage?, shouldDeletePicture: Bool)  -> String  {
        let method = "editUser"
        self.serviceResultChanged(withResult: ServiceActionResult.methodStarted(method: method))
        
        self.networkManager.editUser(withUserToken: user.networkToken, userID: user.id, username: username, email: email, profilePicture: profilePicture, shouldDeletePicture: shouldDeletePicture) { (response, errorMessage, success) -> (Void) in
            if let responseDictionary = response as? [String:Any] {
                self.serviceResultChanged(withResult: ServiceActionResult.methodSucceededWithResponseDictionary(method: method, resultDictionary: responseDictionary))
            } else {
                self.serviceResultChanged(withResult: ServiceActionResult.methodFailed(method: method, error: errorMessage))
            }
        }
        
        return method
    }
    
    /// Load users with identifiers.
    ///
    /// - parameter usersIdentifiers: Array of users server identifiers.
    /// - parameter user: Authorised user model.
    /// - returns: Method name.
    ///
    func loadUsers(withUsersIdentifiers usersIdentifiers: [String], user: AuthorisedUserModel?) -> String {
        let method = "loadUsers"
        self.serviceResultChanged(withResult: ServiceActionResult.methodStarted(method: method))
        
        if self.loadUsersTask != nil {
            self.loadUsersTask?.suspend()
            self.loadUsersTask?.cancel()
            self.loadUsersTask = nil
        }
        
        self.loadUsersTask = self.networkManager.loadUsers(withNetworkToken: user?.networkToken, usersIdentifiers: usersIdentifiers) { (response, errorMessage, isCancelled) -> (Void) in
            if isCancelled {
                self.serviceResultChanged(withResult: ServiceActionResult.methodCancelled(method: method))
            } else {
                if let result = response as? [[String:Any]] {
                    self.serviceResultChanged(withResult: ServiceActionResult.methodSucceededWithResponseArray(method: method, resultArray: result))
                } else {
                    self.serviceResultChanged(withResult: ServiceActionResult.methodFailed(method: method, error: errorMessage))
                }
            }
        }
        
        return method
    }
    
    /// Cancels processing of load user network task.
    func cancelUserLoading() {
        self.loadUsersTask?.suspend()
        self.loadUsersTask?.cancel()
        self.loadUsersTask = nil
    }
    
    // MARK: Private Methods
    
    private func loadUserModel() -> AuthorisedUserModel? {
        if let dictionary = UserDefaults.standard.object(forKey: UserDefaultsKeys.authorisedUserModel) as? [String:Any] {
            let userModel = AuthorisedUserModel(withDictionary: dictionary)
            return userModel
        } else {
            return nil
        }
    }
    
    private func saveUserModel(_ model: AuthorisedUserModel) {
        self.userModel = model
        
        let dictionary = model.modelAsDictionary()
        UserDefaults.standard.setValue(dictionary, forKey: UserDefaultsKeys.authorisedUserModel)
        UserDefaults.standard.synchronize()
    }
    
    private func removeUserModel() {
        self.userModel = nil
        
        if UserDefaults.standard.object(forKey: UserDefaultsKeys.authorisedUserModel) != nil {
            UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.authorisedUserModel)
            UserDefaults.standard.synchronize()
        }
    }
    
}
