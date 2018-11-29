//
//  UserModel.swift
//  troovy-ios
//
//  Created by Daniil on 20.10.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import Foundation

struct UserModel {
    
    private struct Keys {
        static let id = "id"
        static let username = "name"
        static let profilePictureURL = "imageUrl"
    }
    
    // MARK: Properties
    
    /// User ID from server database.
     var id: String!
    
    /// Name of the user.
    var username: String!
    
    /// Profile image of the user.
    var profilePictureURL: String?
    
    // MARK: Init Methods
    
    /// Initializes structure with dictionary.
    ///
    /// - parameter dictionary: Server response or saved user dictionary.
    ///
    init(withDictionary dictionary: [String:Any]) {
        self.id = dictionary[Keys.id] as! String
        self.username = dictionary[Keys.username] as! String
        self.profilePictureURL = dictionary[Keys.profilePictureURL] as? String
    }
    
}
