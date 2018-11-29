//
//  CourseIntroModel.swift
//  troovy-ios
//
//  Created by Daniil on 07.12.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import Foundation

enum CourseIntroType: Int {
    case video = 1
    case image = 3
}

class CourseIntroModel: NSObject {
    
    private struct Keys {
        static let id = "id"
        static let type = "type"
        static let fileAddress = "fileUrl"
        static let thumbnailAddress = "fileThumbnailUrl"
        static let order = "order"
    }
    
    // MARK: Public Properties
    
    /// Server ID of the intro.
    private(set) var id: String!
    
    /// Intro type.
    private(set) var type: CourseIntroType!
    
    /// File server address.
    private(set) var fileAddress: String?
    
    /// Thumbnail address.
    private(set) var thumbnailAddress: String?
    
    /// Intro order.
    private(set) var order: Int!
    
    // MARK: Init Methods & Superclass Overriders
    
    /// Initializes class with dictionary.
    ///
    /// - parameter dictionary: Saved or server session dictionary.
    ///
    init(withDictionary dictionary: [String:Any]) {
        self.id = dictionary[Keys.id] as? String
        self.type = CourseIntroType(rawValue: (dictionary[Keys.type] as! Int))
        self.fileAddress = dictionary[Keys.fileAddress] as? String
        self.thumbnailAddress = dictionary[Keys.thumbnailAddress] as? String
        self.order = dictionary[Keys.order] as! Int
    }
    
    /// Initializes class with properties.
    ///
    /// - parameter identifier: Server ID of the intro.
    /// - parameter type: Intro type.
    /// - parameter fileAddress: File server address.
    /// - parameter thumbnailAddress: Thumbnail address.
    /// - parameter order: Intro order.
    ///
    init(withIdentifier identifier: String, type: Int, fileAddress: String?, thumbnailAddress: String?, order: Int!) {
        self.id = identifier
        self.type = CourseIntroType(rawValue: type)
        self.fileAddress = fileAddress
        self.thumbnailAddress = thumbnailAddress
        self.order = order
    }
    
    // MARK: Public Methods
    
    /// Converts model to dictionary.
    ///
    /// - returns: Model as dictionary.
    ///
    func modelAsDictionary() -> [String:Any] {
        var dictionary: [String:Any] = [:]
        dictionary[Keys.id] = self.id
        dictionary[Keys.type] = self.type.rawValue
        dictionary[Keys.order] = self.order
        
        if let fileAddress = self.fileAddress {
            dictionary[Keys.fileAddress] = fileAddress
        }
        
        if let thumbnailAddress = self.thumbnailAddress {
            dictionary[Keys.thumbnailAddress] = thumbnailAddress
        }
        
        return dictionary
    }
    
}
