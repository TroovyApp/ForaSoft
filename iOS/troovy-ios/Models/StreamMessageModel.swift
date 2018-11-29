//
//  StreamMessageModel.swift
//  troovy-ios
//
//  Created by Daniil on 13.11.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import Foundation

class StreamMessageModel: NSObject, NSCopying, NSCoding, Comparable {
    
    private struct Keys {
        static let messageID = "messageId"
        static let text = "text"
        static let senderID = "senderId"
        static let senderName = "senderName"
        static let senderProfilePictureURL = "senderImageUrl"
        static let timestamp = "timestamp"
    }
    
    // MARK: Properties
    
    /// Message server ID.
    private(set) var messageID: String!
    
    /// Message text.
    private(set) var text: String!
    
    /// Message sender server ID.
    private(set) var senderID: String!
    
    /// Message sender username.
    private(set) var senderName: String!
    
    /// Message sender profile picture url.
    private(set) var senderProfilePictureURL: String?
    
    /// Message creation timestamp.
    private(set) var timestamp: Int64!
    
    // MARK: Init Methods & Superclass Overriders
    
    static func <(lhs: StreamMessageModel, rhs: StreamMessageModel) -> Bool {
        return lhs.timestamp > rhs.timestamp
    }
    
    static func >(lhs: StreamMessageModel, rhs: StreamMessageModel) -> Bool {
        return lhs.timestamp < rhs.timestamp
    }
    
    static func ==(lhs: StreamMessageModel, rhs: StreamMessageModel) -> Bool {
        return lhs.timestamp == rhs.timestamp
    }
    
    static func !=(lhs: StreamMessageModel, rhs: StreamMessageModel) -> Bool {
        return lhs.timestamp != rhs.timestamp
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? StreamMessageModel else {
            return false
        }
        
        return self.messageID == rhs.messageID
    }
    
    /// Initializes class with dictionary.
    ///
    /// - parameter dictionary: Server response or saved user dictionary.
    ///
    init(withDictionary dictionary: [String:Any]) {
        self.messageID = dictionary[Keys.messageID] as! String
        self.text = dictionary[Keys.text] as! String
        self.senderID = dictionary[Keys.senderID] as! String
        self.senderName = dictionary[Keys.senderName] as! String
        self.senderProfilePictureURL = dictionary[Keys.senderProfilePictureURL] as? String
        self.timestamp = dictionary[Keys.timestamp] as! Int64
    }
    
    override func copy() -> Any {
        var message: [String:Any] = [Keys.messageID : self.messageID,
                                     Keys.text : self.text,
                                     Keys.senderID : self.senderID,
                                     Keys.senderName : self.senderName,
                                     Keys.timestamp : self.timestamp]
        
        if let senderProfilePictureURL = self.senderProfilePictureURL {
            message[Keys.senderProfilePictureURL] = senderProfilePictureURL
        }
        
        let copy = StreamMessageModel(withDictionary: message)
        return copy
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        return self.copy()
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.messageID = aDecoder.decodeObject(forKey: Keys.messageID) as! String
        self.text = aDecoder.decodeObject(forKey: Keys.text) as! String
        self.senderID = aDecoder.decodeObject(forKey: Keys.senderID) as! String
        self.senderName = aDecoder.decodeObject(forKey: Keys.senderName) as! String
        self.senderProfilePictureURL = aDecoder.decodeObject(forKey: Keys.senderProfilePictureURL) as? String
        self.timestamp = (aDecoder.decodeObject(forKey: Keys.timestamp) as! NSNumber).int64Value
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.messageID, forKey: Keys.messageID)
        aCoder.encode(self.text, forKey: Keys.text)
        aCoder.encode(self.senderID, forKey: Keys.senderID)
        aCoder.encode(self.senderName, forKey: Keys.senderName)
        aCoder.encode(self.senderProfilePictureURL, forKey: Keys.senderProfilePictureURL)
        aCoder.encode(NSNumber.init(value: self.timestamp), forKey: Keys.timestamp)
    }
    
}
