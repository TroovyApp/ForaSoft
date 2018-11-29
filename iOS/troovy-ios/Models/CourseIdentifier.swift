//
//  CourseIdentifier.swift
//  troovy-ios
//
//  Created by Daniil on 30.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import Foundation

class CourseIdentifier: NSObject, NSCopying, NSCoding, Comparable {
    
    private struct Keys {
        static let identifier = "id"
        static let updatedTimestamp = "updatedAt"
        static let sortingTimestamp = "sortBy"
    }
    
    // MARK: Public Properties
    
    private(set) var identifier: String!
    private(set) var lastUpdateTimestamp: Int64!
    private(set) var sortingTimestamp: Int64!
    
    // MARK: Init Methods & Superclass Overriders
    
    static func <(lhs: CourseIdentifier, rhs: CourseIdentifier) -> Bool {
        return lhs.sortingTimestamp > rhs.sortingTimestamp
    }
    
    static func >(lhs: CourseIdentifier, rhs: CourseIdentifier) -> Bool {
        return lhs.sortingTimestamp < rhs.sortingTimestamp
    }
    
    static func ==(lhs: CourseIdentifier, rhs: CourseIdentifier) -> Bool {
        return lhs.sortingTimestamp == rhs.sortingTimestamp
    }
    
    static func !=(lhs: CourseIdentifier, rhs: CourseIdentifier) -> Bool {
        return lhs.sortingTimestamp != rhs.sortingTimestamp
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? CourseIdentifier else {
            return false
        }
        
        return self.identifier == rhs.identifier
    }
    
    init(dictionary: [String: Any]) {
        self.identifier = dictionary[Keys.identifier] as! String
        self.lastUpdateTimestamp = dictionary[Keys.updatedTimestamp] as! Int64
        self.sortingTimestamp = dictionary[Keys.sortingTimestamp] as! Int64
    }
    
    init(identifier: String!, lastUpdateTimestamp: Int64!, sortingTimestamp: Int64!) {
        self.identifier = identifier
        self.lastUpdateTimestamp = lastUpdateTimestamp
        self.sortingTimestamp = sortingTimestamp
    }
    
    override func copy() -> Any {
        let copy = CourseIdentifier(identifier: self.identifier, lastUpdateTimestamp: self.lastUpdateTimestamp, sortingTimestamp: self.sortingTimestamp)
        return copy
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        return self.copy()
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.identifier = aDecoder.decodeObject(forKey: Keys.identifier) as! String
        self.lastUpdateTimestamp = (aDecoder.decodeObject(forKey: Keys.updatedTimestamp) as! NSNumber).int64Value
        self.sortingTimestamp = (aDecoder.decodeObject(forKey: Keys.sortingTimestamp) as! NSNumber).int64Value
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.identifier, forKey: Keys.identifier)
        aCoder.encode(NSNumber.init(value: self.lastUpdateTimestamp), forKey: Keys.updatedTimestamp)
        aCoder.encode(NSNumber.init(value: self.sortingTimestamp), forKey: Keys.sortingTimestamp)
    }
    
}

