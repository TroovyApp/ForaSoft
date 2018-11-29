//
//  CourseAttachmentModel.swift
//  troovy-ios
//
//  Created by Daniil on 22.09.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import Foundation

enum CourseAttachmentType: Int {
    case video = 1
    case image = 2
    case PDF = 3
    case link = 4
}

class CourseAttachmentModel: NSObject {
    
    private struct Keys {
        static let id = "id"
        static let type = "type"
        static let fileAddress = "fileUrl"
        static let thumbnailAddress = "fileThumbnailUrl"
        static let filePath = "filePath"
        static let createdTimestamp = "createdAt"
    }
    
    // MARK: Public Properties
    
    /// Server ID of the attachment.
    private(set) var id: String!
    
    /// Attachment type.
    private(set) var type: CourseAttachmentType!
    
    /// File server address.
    private(set) var fileAddress: String?
    
    /// Thumbnail address.
    private(set) var thumbnailAddress: String?
    
    /// Disk file path.
    private(set) var filePath: String?
    
    /// Created timestamp of the attachment in seconds.
    private(set) var createdTimestamp: Int64!
    
    // MARK: Init Methods & Superclass Overriders
    
    /// Initializes class with dictionary.
    ///
    /// - parameter dictionary: Saved or server session dictionary.
    ///
    init(withDictionary dictionary: [String:Any]) {
        self.id = dictionary[Keys.id] as? String
        self.type = CourseAttachmentType(rawValue: (dictionary[Keys.type] as! Int))
        self.fileAddress = dictionary[Keys.fileAddress] as? String
        self.thumbnailAddress = dictionary[Keys.thumbnailAddress] as? String
        self.filePath = dictionary[Keys.filePath] as? String
        self.createdTimestamp = dictionary[Keys.createdTimestamp] as! Int64
    }
    
    /// Initializes class with properties.
    ///
    /// - parameter identifier: Server ID of the attachment.
    /// - parameter type: Attachment type.
    /// - parameter fileAddress: File server address.
    /// - parameter thumbnailAddress: Thumbnail address.
    /// - parameter filePath: Disk file path.
    ///
    init(withIdentifier identifier: String, type: Int, fileAddress: String?, thumbnailAddress: String?, filePath: String?, createdTimestamp: Int64) {
        self.id = identifier
        self.type = CourseAttachmentType(rawValue: type)
        self.fileAddress = fileAddress
        self.thumbnailAddress = thumbnailAddress
        self.filePath = filePath
        self.createdTimestamp = createdTimestamp
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
        
        if let fileAddress = self.fileAddress {
            dictionary[Keys.fileAddress] = fileAddress
        }
        
        if let thumbnailAddress = self.thumbnailAddress {
            dictionary[Keys.thumbnailAddress] = thumbnailAddress
        }
        
        if let filePath = self.filePath {
            dictionary[Keys.filePath] = filePath
        }
        
        return dictionary
    }
    
    /// Changes structure with passed properties.
    ///
    /// - parameter filePath: Disk file path.
    ///
    func update(withFilePath filePath: String) {
        self.filePath = filePath
    }
    
}
