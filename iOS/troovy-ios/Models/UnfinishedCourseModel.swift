//
//  UnfinishedCourseModel.swift
//  troovy-ios
//
//  Created by Daniil on 23.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import Foundation
import UIKit

struct UnfinishedCourseModel {
    
    private struct Keys {
        static let title = "title"
        static let description = "description"
        static let price = "price"
        static let mediaFilenames = "mediaFilenames"
        static let sessions = "sessions"
        static let priceTier = "tier"
    }
    
    // MARK: Properties
    
    /// Title of the course.
    private(set) var title: String?
    
    /// Description of the course.
    private(set) var description: String?
    
    /// Filenames of the preview images or/and videos of the course.
    private(set) var mediaFilenames: [String]?
    
    /// Price of the course.
    private(set) var price: NSDecimalNumber?
    
    /// Price tier identifier
    private(set) var priceTier: String? {
        didSet {
            if let priceTier = priceTier {
                self.price = TroovyProducts.shared.priceForProductIdentifier(priceTier)
            }
        }
    }
    
    /// Array of course sessions.
    private(set) var sessions: [CourseSessionModel] = []
    
    // MARK: Methods
    
    /// Initializes empty structure.
    init() {
        // Nothing to do.
    }
    
    /// Initializes structure with course model properties.
    ///
    /// - parameter model: Course model.
    ///
    init(withCourseModel model: CourseModel) {
        self.title = model.title
        self.description = model.specification
        self.price = model.price
        self.priceTier = model.priceTier
        
        var mediaFilenames: [String] = []
        for intro in model.intros {
            mediaFilenames.append(intro.id)
        }
        self.mediaFilenames = mediaFilenames
    }
    
    /// Initializes structure with dictionary.
    ///
    /// - parameter dictionary: Saved course dictionary.
    ///
    init(withDictionary dictionary: [String:Any]) {
        self.title = dictionary[Keys.title] as? String
        self.description = dictionary[Keys.description] as? String
        self.mediaFilenames = dictionary[Keys.mediaFilenames] as? [String]
        
        if let priceString = dictionary[Keys.price] as? String {
            self.price = NSDecimalNumber(string: priceString)
        }
        
        if let priceTierString = dictionary[Keys.priceTier] as? String {
            self.priceTier = priceTierString
        }
        
        if let sessionDictionaries = dictionary[Keys.sessions] as? [[String:Any]] {
            var sessions: [CourseSessionModel] = []
            for sessionDictionary in sessionDictionaries {
                let session = CourseSessionModel(withDictionary: sessionDictionary)
                sessions.append(session)
            }
            self.sessions = sessions
        }
    }
    
    /// Changes structure with passed properties.
    ///
    /// - parameter title: Title of the course.
    ///
    mutating func update(withTitle title: String?) {
        self.title = title
    }
    
    /// Changes structure with passed properties.
    ///
    /// - parameter description: Description of the course.
    ///
    mutating func update(withDescription description: String?) {
        self.description = description
    }
    
    /// Changes structure with passed properties.
    ///
    /// - parameter title: Title of the course.
    /// - parameter description: Description of the course.
    ///
    mutating func update(withTitle title: String?, description: String?) {
        self.title = title
        self.description = description
    }
    
    /// Changes structure with passed properties.
    ///
    /// - parameter price: Course price.
    ///
    mutating func update(withPrice price: NSDecimalNumber?) {
        self.price = price
    }
    
    /// Changes structure with passed properties.
    ///
    /// - parameter priceTier: Price tier string identifier
    ///
    mutating func update(withPriceTier priceTier: String?) {
        self.priceTier = priceTier
    }
    
    /// Changes structure with passed properties.
    ///
    /// - parameter mediaFilenames: Filenames of the preview images or/and videos.
    ///
    mutating func update(withMediaFilenames mediaFilenames: [String]?) {
        self.mediaFilenames = mediaFilenames
    }

    /// Changes structure with passed properties.
    ///
    /// - parameter from: From index.
    /// - parameter to: To index.
    ///
    mutating func update(mediaFilenamesOrderFrom from: Int, to: Int) {
        guard var media = self.mediaFilenames else {
            return
        }
        
        if media.count > to {
            let fromObject = media[from]
            let toObject = media[to]
            
            media[from] = toObject
            media[to] = fromObject
        }
        self.mediaFilenames = media
    }
    
    /// Changes structure with passed properties.
    ///
    /// - parameter sessions: Array of course sessions.
    ///
    mutating func update(withSessions sessions: [CourseSessionModel]) {
        self.sessions = sessions
    }
    
    /// Appends session to the sessions array.
    ///
    /// - parameter sessions: Course session.
    ///
    mutating func update(byAppendingSession session: CourseSessionModel) {
        self.sessions.insert(session, at: 0)
    }
    
    /// Replace session with new one. Search uses session server id or session local identifier.
    ///
    /// - parameter sessions: Course session.
    ///
    mutating func update(byReplacingSession session: CourseSessionModel) {
        if let id = session.id {
            if let index = self.sessions.index(where: {$0.id != nil && $0.id == id}) {
                self.sessions.remove(at: index)
                self.sessions.insert(session, at: index)
            }
        } else {
            if let index = self.sessions.index(where: {$0.identifier == session.identifier}) {
                self.sessions.remove(at: index)
                self.sessions.insert(session, at: index)
            }
        }
    }
    
    /// Converts model to dictionary.
    ///
    /// - returns: Model as dictionary.
    ///
    func modelAsDictionary() -> [String:Any] {
        var dictionary: [String:Any] = [:]
        if let title = self.title {
            dictionary[Keys.title] = title
        }
        if let description = self.description {
            dictionary[Keys.description] = description
        }
        if let mediaFilenames = self.mediaFilenames {
            dictionary[Keys.mediaFilenames] = mediaFilenames
        }
        if let priceString = self.price?.stringValue {
            dictionary[Keys.price] = priceString
        }
        
        if let priceTierString = self.priceTier {
            dictionary[Keys.priceTier] = priceTierString
        }
        
        var sessionDictionaries: [[String:Any]] = []
        for session in self.sessions {
            let sessionDictionary = session.modelAsDictionary()
            sessionDictionaries.append(sessionDictionary)
        }
        dictionary[Keys.sessions] = sessionDictionaries
        
        return dictionary
    }
    
}
