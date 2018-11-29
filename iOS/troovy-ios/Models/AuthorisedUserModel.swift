//
//  AuthorisedUserModel.swift
//  troovy-ios
//
//  Created by Daniil on 22.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import Foundation

protocol AuthorisedUserModelDelegate: class {
    func authorisedUserChagned(user: AuthorisedUserModel)
}

class AuthorisedUserModel: NSObject {
    
    private struct NotificationNames {
        static let modelChanged = "troovy_authorisedUserModelChanged"
    }
    
    private struct Keys {
        static let id = "id"
        static let accessToken = "accessToken"
        static let callingCode = "dialCode"
        static let phoneNumber = "phoneNumber"
        static let email = "email"
        static let username = "name"
        static let credits = "credits"
        static let profilePictureURL = "imageUrl"
        static let reservedCredits = "reservedCredits"
        static let currency = "currency"
    }
    
    // MARK: Public Properties
    
    /// Delegate. Responds to CourseModelDelegate.
    weak var delegate: AuthorisedUserModelDelegate? {
        didSet {
            self.saveDelegate(self.delegate)
        }
    }
    
    /// User ID from server database.
    private(set) var id: String!
    
    /// User access token. Used to identify authorised user.
    private(set) var networkToken: String!
    
    /// County calling code.
    private(set) var callingCode: String!
    
    /// Phone number of the user without calling code.
    private(set) var phoneNumber: String!
    
    /// Email address of the user
    private(set) var email: String!
    
    /// Name of the user.
    private(set) var username: String!
    
    /// Wallet balance.
    private(set) var credits: NSDecimalNumber!
    
    /// Wallet reserved balance.
    private(set) var reservedCredits: NSDecimalNumber!
    
    /// Profile image of the user.
    private(set) var profilePictureURL: String?
    
    /// Current user currency code
    private(set) var currency: String?
    
    // MARK: Private Properties
    
    private var delegates = MulticastDelegate<AuthorisedUserModelDelegate>()
    
    // MARK: Init Methods & Superclass Overriders
    
    /// Initializes structure with dictionary.
    ///
    /// - parameter dictionary: Server response or saved user dictionary.
    ///
    init(withDictionary dictionary: [String:Any]) {
        super.init()
        
        self.id = dictionary[Keys.id] as! String
        self.networkToken = dictionary[Keys.accessToken] as! String
        self.callingCode = dictionary[Keys.callingCode] as! String
        self.phoneNumber = dictionary[Keys.phoneNumber] as! String
        self.username = dictionary[Keys.username] as! String
        self.profilePictureURL = dictionary[Keys.profilePictureURL] as? String
        self.currency = dictionary[Keys.currency] as? String
        
        if let credits = dictionary[Keys.credits] as? String {
            self.credits = NSDecimalNumber(string: credits)
        } else {
            if let credits = dictionary[Keys.credits] as? Double {
                self.credits = NSDecimalNumber(value: credits)
            } else {
                self.credits = NSDecimalNumber.zero
            }
        }
        
        if let reservedCredits = dictionary[Keys.reservedCredits] as? String {
            self.reservedCredits = NSDecimalNumber(string: reservedCredits)
        } else {
            if let reservedCredits = dictionary[Keys.reservedCredits] as? Double {
                self.reservedCredits = NSDecimalNumber(value: reservedCredits)
            } else {
                self.reservedCredits = NSDecimalNumber.zero
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(userChanged(_:)), name: Notification.Name(NotificationNames.modelChanged), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Notifications & Observers
    
    @objc private func userChanged(_ notification: Notification) {
        guard let notificationModel = notification.object as? AuthorisedUserModel else {
            return
        }
        
        if notificationModel.id != self.id  {
            return
        }
        
        if notificationModel != self {
            if let callingCode = notification.userInfo?[Keys.callingCode] as? String {
                self.callingCode = callingCode
            }
            
            if let phoneNumber = notification.userInfo?[Keys.phoneNumber] as? String {
                self.phoneNumber = phoneNumber
            }
            
            if let email = notification.userInfo?[Keys.email] as? String {
                self.email = email
            }
            
            if let username = notification.userInfo?[Keys.username] as? String {
                self.username = username
            }
            
            if let credits = notification.userInfo?[Keys.credits] as? NSDecimalNumber {
                self.credits = credits
            }
            
            if let reservedCredits = notification.userInfo?[Keys.reservedCredits] as? NSDecimalNumber {
                self.reservedCredits = reservedCredits
            }
            
            if let profilePictureURL = notification.userInfo?[Keys.profilePictureURL] as? String {
                self.profilePictureURL = profilePictureURL
            }
            
            if let currency = notification.userInfo?[Keys.currency] as? String {
                self.currency = currency
            }
        }
        
        self.delegates.invoke { (courseDelegate) in
            courseDelegate.authorisedUserChagned(user: self)
        }
    }
    
    // MARK: Public Methods
    
    /// Converts model to dictionary.
    ///
    /// - returns: Model as dictionary.
    ///
    func modelAsDictionary() -> [String:Any] {
        var dictionary: [String:Any] = [:]
        dictionary[Keys.id] = self.id
        dictionary[Keys.accessToken] = self.networkToken
        dictionary[Keys.callingCode] = self.callingCode
        dictionary[Keys.phoneNumber] = self.phoneNumber
        dictionary[Keys.username] = self.username
        dictionary[Keys.credits] = self.credits.stringValue
        dictionary[Keys.reservedCredits] = self.reservedCredits.stringValue
        
        if let email = self.email {
            dictionary[Keys.email] = email
        }
        
        if let profilePictureURL = self.profilePictureURL {
            dictionary[Keys.profilePictureURL] = profilePictureURL
        }
        
        if let currency = self.currency {
            dictionary[Keys.currency] = currency
        }
        
        return dictionary
    }
    
    /// Changes structure with passed properties.
    ///
    /// - parameter credits: Wallet balance.
    ///
    func update(withCredits credits: NSDecimalNumber) {
        self.credits = credits
        
        NotificationCenter.default.post(name: Notification.Name(NotificationNames.modelChanged), object: self, userInfo: [Keys.credits : credits])
    }
    
    /// Changes structure with passed properties.
    ///
    /// - parameter reservedCredits: Wallet reserved balance.
    ///
    func update(withReservedCredits reservedCredits: NSDecimalNumber) {
        self.reservedCredits = reservedCredits
        
        NotificationCenter.default.post(name: Notification.Name(NotificationNames.modelChanged), object: self, userInfo: [Keys.reservedCredits : reservedCredits])
    }
    
    /// Changes wallet balance by subtracting course price.
    ///
    /// - parameter coursePrice: Course price.
    ///
    func update(withCoursePrice coursePrice: NSDecimalNumber) {
        if self.credits.doubleValue <= coursePrice.doubleValue {
            self.credits = NSDecimalNumber.zero
        } else {
            self.credits = self.credits.subtracting(coursePrice)
        }
        
        NotificationCenter.default.post(name: Notification.Name(NotificationNames.modelChanged), object: self, userInfo: [Keys.credits : credits])
    }
    
    /// Changes structure with passed properties.
    ///
    /// - parameter dictionary: User server dictionary.
    ///
    func update(withDictionary dictionary: [String:Any]) {
        var userInfo: [String:Any] = [:]
        if let callingCode = dictionary[Keys.callingCode] as? String {
            self.callingCode = callingCode
            userInfo[Keys.callingCode] = callingCode
        }
        
        if let phoneNumber = dictionary[Keys.phoneNumber] as? String {
            self.phoneNumber = phoneNumber
            userInfo[Keys.phoneNumber] = phoneNumber
        }
        
        if let email = dictionary[Keys.email] as? String {
            self.email = email
            userInfo[Keys.email] = email
        }
        
        if let username = dictionary[Keys.username] as? String {
            self.username = username
            userInfo[Keys.username] = username
        }
        
        if let profilePictureURL = dictionary[Keys.profilePictureURL] as? String {
            self.profilePictureURL = profilePictureURL
            userInfo[Keys.profilePictureURL] = profilePictureURL
        }
        
        if let currency = dictionary[Keys.currency] as? String {
            self.currency = currency
            userInfo[Keys.currency] = currency
        }
        
        if let credits = dictionary[Keys.credits] as? String {
            let creditsValue = NSDecimalNumber(string: credits)
            self.credits = creditsValue
            userInfo[Keys.credits] = creditsValue
        } else if let credits = dictionary[Keys.credits] as? Double {
            let creditsValue = NSDecimalNumber(value: credits)
            self.credits = creditsValue
            userInfo[Keys.credits] = creditsValue
        }
        
        if let reservedCredits = dictionary[Keys.reservedCredits] as? String {
            let reservedCreditsValue = NSDecimalNumber(string: reservedCredits)
            self.reservedCredits = reservedCreditsValue
            userInfo[Keys.reservedCredits] = reservedCreditsValue
        } else if let reservedCredits = dictionary[Keys.reservedCredits] as? Double {
            let reservedCreditsValue = NSDecimalNumber(value: reservedCredits)
            self.reservedCredits = reservedCreditsValue
            userInfo[Keys.reservedCredits] = reservedCreditsValue
        }
        
        NotificationCenter.default.post(name: Notification.Name(NotificationNames.modelChanged), object: self, userInfo: userInfo)
    }
    
    /// Removes delegate from the delegates list.
    ///
    /// - parameter delegate: Delegate. Responds to AuthorisedUserModelDelegate.
    ///
    func removeDelegate(_ delegate: AuthorisedUserModelDelegate?) {
        guard let object = delegate else {
            return
        }
        
        self.delegates.removeDelegate(delegate: object)
    }
    
    // MARK: Private Methods
    
    private func saveDelegate(_ delegate: AuthorisedUserModelDelegate?) {
        guard let object = delegate else {
            return
        }
        
        self.delegates.addDelegate(delegate: object)
    }
    
}
