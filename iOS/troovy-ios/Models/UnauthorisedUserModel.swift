//
//  UnauthorisedUserModel.swift
//  troovy-ios
//
//  Created by Daniil on 18.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import Foundation
import UIKit

struct UnauthorisedUserModel {
    
    // MARK: Properties
    
    /// App generated code. Used to identify unauthorised user.
    private(set) var userToken: String!
    
    /// County calling code selected by the user.
    private(set) var callingCode: String?
    
    /// Country region code selected by the user.
    private(set) var regionCode: String?
    
    /// Phone number of the user without calling code.
    private(set) var phoneNumber: String?
    
    /// Formatted phone number of the user with calling code.
    private(set) var formattedPhoneNumber: String?
    
    /// Name of the user.
    private(set) var username: String?
    
    /// Profile image of the user.
    private(set) var profilePicture: UIImage?
    
    /// Initializes structure with userToken.
    init() {
        self.userToken = UUID().uuidString
    }
    
    // MARK: Methods
    
    /// Initializes structure with userToken and passed properties.
    ///
    /// - parameter callingCode: Calling code of the selected country.
    /// - parameter regionCode: Region code of the selected country.
    /// - parameter phoneNumber: Phone number of the user.
    /// - parameter formattedPhoneNumber: Formatted phone number of the user.
    ///
    init(withCallingCode callingCode: String, regionCode: String, phoneNumber: String, formattedPhoneNumber: String) {
        self.userToken = UUID().uuidString
        
        self.callingCode = callingCode
        self.regionCode = regionCode
        self.phoneNumber = phoneNumber
        self.formattedPhoneNumber = formattedPhoneNumber
    }
    
    /// Changes structure with passed properties.
    ///
    /// - parameter callingCode: Calling code of the selected country.
    /// - parameter regionCode: Region code of the selected country.
    /// - parameter phoneNumber: Phone number of the user.
    /// - parameter formattedPhoneNumber: Formatted phone number of the user.
    ///
    mutating func update(withCallingCode callingCode: String, regionCode: String, phoneNumber: String, formattedPhoneNumber: String) {
        self.callingCode = callingCode
        self.regionCode = regionCode
        self.phoneNumber = phoneNumber
        self.formattedPhoneNumber = formattedPhoneNumber
    }
    
    /// Changes structure with passed properties.
    ///
    /// - parameter username: Username of the user.
    ///
    mutating func update(withUsername username: String) {
        self.username = username
    }
    
    /// Changes structure with passed properties.
    ///
    /// - parameter username: Profile picture of the user.
    ///
    mutating func update(withProfilePicture profilePicture: UIImage?) {
        self.profilePicture = profilePicture
    }
    
    /// Changes structure with passed properties.
    ///
    /// - parameter username: Username of the user.
    /// - parameter username: Profile picture of the user.
    ///
    mutating func update(withUsername username: String, profilePicture: UIImage?) {
        self.username = username
        self.profilePicture = profilePicture
    }
    
}
