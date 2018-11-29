//
//  CourseSession.swift
//  troovy-ios
//
//  Created by Daniil on 25.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import Foundation

protocol SessionModelDelegate: class {
    func sessionChagned(session: CourseSessionModel)
}

class CourseSessionModel: NSObject {
    
    private struct NotificationNames {
        static let sessionChanged = "troovy_courseSessionChanged"
    }
    
    private struct Keys {
        static let id = "id"
        static let courseID = "courseId"
        static let creatorID = "creatorId"
        static let identifier = "identifier"
        static let title = "title"
        static let specification = "description"
        static let startTimestamp = "startAt"
        static let updatedTimestamp = "updatedAt"
        static let duration = "duration"
        static let attachments = "attachments"
    }
    
    // MARK: Public Properties
    
    /// Delegate. Responds to SessionModelDelegate.
    weak var delegate: SessionModelDelegate? {
        didSet {
            self.saveDelegate(self.delegate)
        }
    }
    
    /// Server ID of the session.
    private(set) var id: String?
    
    /// Creator ID of the session.
    private(set) var creatorID: String?
    
    /// Course ID of the session.
    private(set) var courseID: String?
    
    /// Local identifier of the session.
    private(set) var identifier: String!

    /// Title of the session.
    private(set) var title: String!
    
    /// Description of the session.
    private(set) var specification: String!
    
    /// Start timestamp of the session in seconds.
    private(set) var startTimestamp: Int64!
    
    /// Last update timestamp of the session in seconds.
    private(set) var updatedTimestamp: Int64?
    
    /// Approximate duration of the session in minutes.
    private(set) var duration: Int!
    
    /// Session attachments.
    private(set) var attachments: [CourseAttachmentModel]!
    
    // MARK: Private Properties
    
    private var delegates = MulticastDelegate<SessionModelDelegate>()
    
    // MARK: Init Methods & Superclass Overriders
    
    /// Initializes class.
    override init() {
        super.init()
        
        self.identifier = UUID().uuidString
        self.attachments = []
        
        NotificationCenter.default.addObserver(self, selector: #selector(sessionChanged(_:)), name: Notification.Name(NotificationNames.sessionChanged), object: nil)
    }
    
    /// Initializes class with dictionary.
    ///
    /// - parameter dictionary: Saved or server session dictionary.
    ///
    convenience init(withDictionary dictionary: [String:Any]) {
        self.init()
        
        self.id = dictionary[Keys.id] as? String
        self.creatorID = dictionary[Keys.creatorID] as? String
        self.courseID = dictionary[Keys.courseID] as? String
        self.title = dictionary[Keys.title] as! String
        self.specification = dictionary[Keys.specification] as! String
        self.startTimestamp = dictionary[Keys.startTimestamp] as! Int64
        self.updatedTimestamp = dictionary[Keys.updatedTimestamp] as? Int64
        self.duration = dictionary[Keys.duration] as! Int
        
        if let identifier = dictionary[Keys.identifier] as? String {
            self.identifier = identifier
        }
    }
    
    /// Initializes class with properties.
    ///
    /// - parameter title: Title of the session.
    /// - parameter specification: Description of the session.
    /// - parameter startTimestamp: Start timestamp of the session.
    /// - parameter duration: Duration of the session.
    ///
    convenience init(withTitle title: String, specification: String, startTimestamp: Int64, duration: Int) {
        self.init()
        
        self.title = title
        self.specification = specification
        self.startTimestamp = startTimestamp
        self.duration = duration
    }
    
    /// Initializes class with properties.
    ///
    /// - parameter id: Server ID of the session.
    /// - parameter title: Title of the session.
    /// - parameter specification: Description of the session.
    /// - parameter startTimestamp: Start timestamp of the session.
    /// - parameter updatedTimestamp: Last update timestamp of the session.
    /// - parameter duration: Duration of the session.
    ///
    convenience init(withID id: String?, identifier: String?, title: String, specification: String, startTimestamp: Int64, updatedTimestamp: Int64?, duration: Int) {
        self.init()
        
        self.id = id
        self.title = title
        self.specification = specification
        self.startTimestamp = startTimestamp
        self.updatedTimestamp = updatedTimestamp
        self.duration = duration
        
        if let serverIdentifier = identifier {
            self.identifier = serverIdentifier
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Notifications & Observers
    
    @objc private func sessionChanged(_ notification: Notification) {
        guard let notificationModel = notification.object as? CourseSessionModel else {
            return
        }
        
        if (notificationModel.id != nil && self.id != nil && notificationModel.id != self.id) || (notificationModel.id == nil && notificationModel.identifier != self.identifier) {
            return
        }
        
        if notificationModel != self {
            if let title = notification.userInfo?[Keys.title] as? String {
                self.title = title
            }
            
            if let specification = notification.userInfo?[Keys.specification] as? String {
                self.specification = specification
            }
            
            if let startTimestamp = notification.userInfo?[Keys.startTimestamp] as? Int64 {
                self.startTimestamp = startTimestamp
            }
            
            if let updatedTimestamp = notification.userInfo?[Keys.updatedTimestamp] as? Int64 {
                self.updatedTimestamp = updatedTimestamp
            }
            
            if let duration = notification.userInfo?[Keys.duration] as? Int {
                self.duration = duration
            }
            
            if let attachments = notification.userInfo?[Keys.attachments] as? [CourseAttachmentModel] {
                self.attachments = attachments
            }
        }
        
        self.delegates.invoke { (sessionDelegate) in
            sessionDelegate.sessionChagned(session: self)
        }
    }
    
    // MARK: Public Methods
    
    /// Changes class with passed properties.
    ///
    /// - parameter title: Title of the session.
    ///
    func update(withTitle title: String) {
        self.title = title
        
        NotificationCenter.default.post(name: Notification.Name(NotificationNames.sessionChanged), object: self, userInfo: [Keys.title : title])
    }
    
    /// Changes class with passed properties.
    ///
    /// - parameter specification: Description of the session.
    ///
    func update(withSpecification specification: String) {
        self.specification = specification
        
        NotificationCenter.default.post(name: Notification.Name(NotificationNames.sessionChanged), object: self, userInfo: [Keys.specification : specification])
    }
    
    /// Changes class with passed properties.
    ///
    /// - parameter startTimestamp: Start timestamp of the session.
    ///
    func update(withStartTimestamp startTimestamp: Int64) {
        self.startTimestamp = startTimestamp
        
        NotificationCenter.default.post(name: Notification.Name(NotificationNames.sessionChanged), object: self, userInfo: [Keys.startTimestamp : startTimestamp])
    }
    
    /// Changes class with passed properties.
    ///
    /// - parameter duration: Approximate duration of the session.
    ///
    func update(withDuration duration: Int) {
        self.duration = duration
        
        NotificationCenter.default.post(name: Notification.Name(NotificationNames.sessionChanged), object: self, userInfo: [Keys.duration : duration])
    }
    
    /// Changes class with passed properties.
    ///
    /// - parameter attachments: Session attachments.
    ///
    func update(withAttachments attachments: [CourseAttachmentModel]) {
        self.attachments = attachments
        
        NotificationCenter.default.post(name: Notification.Name(NotificationNames.sessionChanged), object: self, userInfo: [Keys.attachments : attachments])
    }
    
    /// Changes class with passed properties.
    ///
    /// - parameter title: Title of the session.
    /// - parameter specification: Description of the session.
    /// - parameter startTimestamp: Start timestamp of the session.
    /// - parameter duration: Approximate duration of the session.
    ///
    func update(withTitle title: String?, specification: String?, startTimestamp: Int64?, duration: Int?) {
        var changedProperties: [String:Any] = [:]
        if let sessionTitle = title {
            self.title = sessionTitle
            changedProperties[Keys.title] = sessionTitle
        }
        if let sessionSpecification = specification {
            self.specification = sessionSpecification
            changedProperties[Keys.specification] = sessionSpecification
        }
        if let sessionStartTimestamp = startTimestamp {
            self.startTimestamp = sessionStartTimestamp
            changedProperties[Keys.startTimestamp] = sessionStartTimestamp
        }
        if let sessionDuration = duration {
            self.duration = sessionDuration
            changedProperties[Keys.duration] = sessionDuration
        }
        
        NotificationCenter.default.post(name: Notification.Name(NotificationNames.sessionChanged), object: self, userInfo: changedProperties)
    }
    
    /// Changes class with passed properties.
    ///
    /// - parameter dictionary: Saved or server session dictionary.
    ///
    func update(withDictionary dictionary: [String:Any]) {
        self.title = dictionary[Keys.title] as! String
        self.specification = dictionary[Keys.specification] as! String
        self.startTimestamp = dictionary[Keys.startTimestamp] as! Int64
        self.updatedTimestamp = dictionary[Keys.updatedTimestamp] as? Int64
        self.duration = dictionary[Keys.duration] as! Int
        
        NotificationCenter.default.post(name: Notification.Name(NotificationNames.sessionChanged), object: self, userInfo: dictionary)
    }
    
    /// Converts model to dictionary.
    ///
    /// - returns: Model as dictionary.
    ///
    func modelAsDictionary() -> [String:Any] {
        var dictionary: [String:Any] = [:]
        
        if let id = self.id {
            dictionary[Keys.id] = id
        }
        
        if let creatorID = self.creatorID {
            dictionary[Keys.creatorID] = creatorID
        }
        
        if let courseID = self.courseID {
            dictionary[Keys.courseID] = courseID
        }
        
        dictionary[Keys.identifier] = self.identifier
        dictionary[Keys.title] = self.title
        dictionary[Keys.specification] = self.specification
        dictionary[Keys.startTimestamp] = self.startTimestamp
        dictionary[Keys.duration] = self.duration
        
        return dictionary
    }
    
    /// Removes delegate from the delegates list.
    ///
    /// - parameter delegate: Delegate. Responds to SessionModelDelegate.
    ///
    func removeDelegate(_ delegate: SessionModelDelegate?) {
        guard let object = delegate else {
            return
        }
        
        self.delegates.removeDelegate(delegate: object)
    }
    
    // MARK: Private Methods
    
    private func saveDelegate(_ delegate: SessionModelDelegate?) {
        guard let object = delegate else {
            return
        }
        
        self.delegates.addDelegate(delegate: object)
    }
    
}
