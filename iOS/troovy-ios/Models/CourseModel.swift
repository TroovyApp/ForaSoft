//
//  CourseModel.swift
//  troovy-ios
//
//  Created by Daniil on 30.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import Foundation

protocol CourseModelDelegate: class {
    func courseChagned(course: CourseModel)
}

class CourseModel: NSObject {
    
    private struct NotificationNames {
        static let modelChanged = "troovy_courseModelChanged"
    }
    
    private struct Keys {
        static let model = "model"
        static let id = "id"
        static let creatorID = "creatorId"
        static let creatorName = "creatorName"
        static let title = "title"
        static let specification = "description"
        static let price = "price"
        static let priceTier = "tier"
        static let state = "status"
        static let earnings = "earnings"
        static let sessions = "sessions"
        static let attachments = "attachments"
        static let updatedTimestamp = "updatedAt"
        static let createdTimestamp = "createdAt"
        static let nearestSessionTimestamp = "nearestSessionAt"
        static let webPage = "webPage"
        static let subscribed = "subscribed"
        static let intros = "intro"
        static let previewImageURL = "courseImageUrl"
        static let previewVideoThumbnailURL = "courseIntroVideoPreviewUrl"
        static let imageSharingURL = "courseImageSharingUrl"
        static let subscribersCount = "subscribersCount"
    }
    
    // MARK: Public Properties
    
    /// Delegate. Responds to CourseModelDelegate.
    weak var delegate: CourseModelDelegate? {
        didSet {
            self.saveDelegate(self.delegate)
        }
    }
    
    /// Server ID of the course.
    private(set) var id: String!
    
    /// Sever ID of the course creator.
    private(set) var creatorID: String?
    
    /// Username of the course creator.
    private(set) var creatorName: String!
    
    /// Title of the course.
    private(set) var title: String!
    
    /// Description of the course.
    private(set) var specification: String!
    
    /// Price of the course.
    private(set) var price: NSDecimalNumber?
    
    /// Price tier of the course
    private(set) var priceTier: String? {
        didSet {
            if let priceTier = priceTier {
                self.price = TroovyProducts.shared.priceForProductIdentifier(priceTier)
            }
        }
    }
    
    /// State of the course. 0 - unpublished, 1 - published.
    private(set) var state: Int?
    
    /// Money earned for this course.
    private(set) var earnings: NSDecimalNumber?
    
    /// Array of course sessions kind of CourseSessionModel class.
    private(set) var sessions: [CourseSessionModel]!
    
    /// Array of course attachments kind of CourseAttachment class.
    private(set) var attachments: [CourseAttachmentModel]!
    
    /// Last update timestamp of the course in seconds.
    private(set) var updatedTimestamp: Int64!
    
    /// Created timestamp of the course in seconds.
    private(set) var createdTimestamp: Int64!
    
    /// Start timestamp of the nearest session in this course in seconds.
    private(set) var nearestSessionTimestamp: Int64?
    
    /// Preview image url string.
    private(set) var previewImageURL: String?
    
    /// Preview image for share feature
    private(set) var imageSharingURL: String?
    
    /// Preview intro models.
    private(set) var intros: [CourseIntroModel]! {
        didSet {
            if intros == nil {
                intros = [CourseIntroModel]()
            }
        }
    }
    
    /// Course web page address.
    private(set) var webPage: String?
    
    /// Indicates whether the user has purchased this course.
    private(set) var subscribed: Bool!
    
    private(set) var subscribersCount: Int = 0
    
    // MARK: Private Properties
    
    private var delegates = MulticastDelegate<CourseModelDelegate>()
    
    // MARK: Init Methods & Superclass Overriders
    
    /// Initializes class.
    override init() {
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(courseChanged(_:)), name: Notification.Name(NotificationNames.modelChanged), object: nil)
    }
    
    /// Initializes class with dicrionary.
    ///
    /// - parameter dictionary: Server course dictionary.
    ///
    convenience init(withDictionary dictionary: [String:Any]) {
        let identifier = dictionary[Keys.id] as! String
        let creatorID = dictionary[Keys.creatorID] as? String
        let creatorName = dictionary[Keys.creatorName] as! String
        let title = dictionary[Keys.title] as! String
        let specification = dictionary[Keys.specification] as! String
        let state = dictionary[Keys.state] as? Int
        let updatedTimestamp = dictionary[Keys.updatedTimestamp] as! Int64
        let createdTimestamp = dictionary[Keys.createdTimestamp] as! Int64
        let nearestSessionTimestamp = dictionary[Keys.nearestSessionTimestamp] as? Int64
        let webPage = dictionary[Keys.webPage] as? String
        let subscribed = (dictionary[Keys.subscribed] as? Bool) ?? false
        let imageSharingURL = dictionary[Keys.imageSharingURL] as? String
        let subscribersCount = dictionary[Keys.subscribersCount] as? Int
        
        var previewImageURL: String?
        if let imageURL = dictionary[Keys.previewImageURL] as? String, !imageURL.isEmpty {
            previewImageURL = imageURL
        } else if let imageURL = dictionary[Keys.previewVideoThumbnailURL] as? String, !imageURL.isEmpty {
            previewImageURL = imageURL
        }
        
        var price: NSDecimalNumber?
        if let priceString = dictionary[Keys.price] as? String {
            price = NSDecimalNumber(string: priceString)
        } else if let priceValue = dictionary[Keys.price] as? Double {
            price = NSDecimalNumber(value: priceValue)
        }
        
        var priceTier: String?
        if let priceTierString = dictionary[Keys.priceTier] as? String {
            priceTier = priceTierString
        }
        
        var earnings: NSDecimalNumber?
        if let earningsString = dictionary[Keys.earnings] as? String {
            earnings = NSDecimalNumber(string: earningsString)
        } else if let earningsValue = dictionary[Keys.earnings] as? Double {
            earnings = NSDecimalNumber(value: earningsValue)
        }
        
        var sessions: [CourseSessionModel] = []
        if let sessionDictionaries = dictionary[Keys.sessions] as? [[String:Any]] {
            for sessionDictionary in sessionDictionaries {
                //THis is a fix, because no creatorID is passed to session from server
                var sessionDictionaryWithCreatorID = sessionDictionary
                sessionDictionaryWithCreatorID[Keys.creatorID] = creatorID
                let session = CourseSessionModel(withDictionary: sessionDictionaryWithCreatorID)
                sessions.append(session)
            }
        }
        
        var attachments: [CourseAttachmentModel] = []
        if let attachmentDictionaries = dictionary[Keys.attachments] as? [[String:Any]] {
            for attachmentDictionary in attachmentDictionaries {
                let attachment = CourseAttachmentModel(withDictionary: attachmentDictionary)
                attachments.append(attachment)
            }
        }
        
        var intros: [CourseIntroModel] = []
        if let introDictionaries = dictionary[Keys.intros] as? [[String:Any]] {
            for introDictionary in introDictionaries {
                let intro = CourseIntroModel(withDictionary: introDictionary)
                intros.append(intro)
            }
        }
        
        self.init(withIdentifier: identifier, creatorID: creatorID, creatorName: creatorName, title: title, specification: specification, priceString: price?.stringValue, priceTierString: priceTier, state: state, earningsString: earnings?.stringValue, sessions: sessions, attachments: attachments, updatedTimestamp: updatedTimestamp, createdTimestamp: createdTimestamp, nearestSessionTimestamp: nearestSessionTimestamp, previewImageURL: previewImageURL, intros: intros, webPage: webPage, subscribed: subscribed, imageSharingURL: imageSharingURL, subscribersCount: subscribersCount ?? 0)
    }
    
    /// Initializes class with properties.
    ///
    /// - parameter identifier: Server ID of the course.
    /// - parameter creatorID: Server ID of the course creator.
    /// - parameter creatorName: Username of the course creator.
    /// - parameter title: Title of the course.
    /// - parameter specification: Description of the course.
    /// - parameter priceString: Price of the course.
    /// - parameter state: State of the course.
    /// - parameter earningsString: Money earned for this course.
    /// - parameter sessions: Array of course sessions.
    /// - parameter attachments: Array of course attachments.
    /// - parameter updatedTimestamp: Last update timestamp of the course in seconds.
    /// - parameter createdTimestamp: Created timestamp of the course in seconds.
    /// - parameter nearestSessionTimestamp: Start timestamp of the nearest session in this course in seconds.
    /// - parameter previewImageURL: Preview image URL.
    /// - parameter intros: Preview intro models.
    /// - parameter webPage: Web page address of the course.
    /// - parameter subscribed: Indicates whether the user has purchased this course.
    ///
    convenience init(withIdentifier identifier: String, creatorID: String?, creatorName: String, title: String, specification: String, priceString: String?, priceTierString: String?, state: Int?, earningsString: String?, sessions: [CourseSessionModel], attachments: [CourseAttachmentModel], updatedTimestamp: Int64, createdTimestamp: Int64, nearestSessionTimestamp: Int64?, previewImageURL: String?, intros: [CourseIntroModel], webPage: String?, subscribed: Bool, imageSharingURL: String?, subscribersCount: Int) {
        self.init()
        
        self.id = identifier
        self.creatorID = creatorID
        self.creatorName = creatorName
        self.title = title
        self.specification = specification
        self.price = (priceString != nil ? NSDecimalNumber(string: priceString!) : NSDecimalNumber.zero)
        self.priceTier = priceTierString
        self.state = state
        self.earnings = (earningsString != nil ? NSDecimalNumber(string: earningsString!) : nil)
        self.sessions = sessions
        self.attachments = attachments
        self.updatedTimestamp = updatedTimestamp
        self.createdTimestamp = createdTimestamp
        self.nearestSessionTimestamp = nearestSessionTimestamp
        self.previewImageURL = previewImageURL
        self.intros = intros
        self.webPage = webPage
        self.subscribed = subscribed
        self.imageSharingURL = imageSharingURL
        self.subscribersCount = subscribersCount
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Notifications & Observers
    
    @objc private func courseChanged(_ notification: Notification) {
        guard let notificationModel = notification.object as? CourseModel else {
            return
        }
        
        if notificationModel.id != self.id  {
            return
        }
        
        if notificationModel != self {
            if let sessions = notification.userInfo?[Keys.sessions] as? [CourseSessionModel] {
                self.sessions = sessions
            }
            
            if let model = notification.userInfo?[Keys.model] as? CourseModel {
                self.copyProperties(fromModel: model)
            }
            
            if let attachments = notification.userInfo?[Keys.attachments] as? [CourseAttachmentModel] {
                self.attachments = attachments
            }
            
            if let intros = notification.userInfo?[Keys.intros] as? [CourseIntroModel] {
                self.previewImageURL = (intros.first(where: { $0.type == .video })?.thumbnailAddress ?? intros.first?.fileAddress)
                self.intros = intros
            }
            
            if let subscribed = notification.userInfo?[Keys.subscribed] as? Bool {
                self.subscribed = subscribed
            }
            
            if let price = notification.userInfo?[Keys.price] as? NSDecimalNumber {
                self.price = price
            }
            
            if let priceTier = notification.userInfo?[Keys.priceTier] as? String {
                self.priceTier = priceTier
            }
            
            if let earnings = notification.userInfo?[Keys.earnings] as? NSDecimalNumber {
                self.earnings = earnings
            }
            
            if let subscribersCount = notification.userInfo?[Keys.subscribersCount] as? Int {
                self.subscribersCount = subscribersCount
            }
        }
        
        self.delegates.invoke { (courseDelegate) in
            courseDelegate.courseChagned(course: self)
        }
    }
    
    // MARK: Public Methods
    
    /// Changes structure with passed properties.
    ///
    /// - parameter attachments: Array of course attachments.
    ///
    func update(withAttachments attachments: [CourseAttachmentModel]) {
        self.attachments = attachments
        
        NotificationCenter.default.post(name: Notification.Name(NotificationNames.modelChanged), object: self, userInfo: [Keys.attachments : self.attachments])
    }
    
    /// Changes structure with passed properties.
    ///
    /// - parameter intros: Array of course intros.
    ///
    func update(withIntros intros: [CourseIntroModel]) {
        self.previewImageURL = (intros.first(where: { $0.type == .video })?.thumbnailAddress ?? intros.first?.fileAddress)
        self.intros = intros
        
        NotificationCenter.default.post(name: Notification.Name(NotificationNames.modelChanged), object: self, userInfo: [Keys.intros : self.intros])
    }
    
    /// Changes structure with passed properties.
    ///
    /// - parameter attachment: Attachment to append.
    ///
    func update(byAppendingAttachment attachment: CourseAttachmentModel) {
        self.attachments.append(attachment)
        
        NotificationCenter.default.post(name: Notification.Name(NotificationNames.modelChanged), object: self, userInfo: [Keys.attachments : self.attachments])
    }
    
    /// Changes structure with passed properties.
    ///
    /// - parameter session: Session to change.
    ///
    func update(byChangingSession session: CourseSessionModel) {
        let found = self.sessions.index(where: { (sessionModel) -> Bool in
            return (sessionModel.id != nil && sessionModel.id == session.id) || (sessionModel.id == nil && sessionModel.identifier == session.identifier)
        })
        
        if let index = found {
            self.sessions[index] = session
            NotificationCenter.default.post(name: Notification.Name(NotificationNames.modelChanged), object: self, userInfo: [Keys.sessions : self.sessions])
        }
    }
    
    /// Changes structure with passed properties.
    ///
    /// - parameter sessions: Array of course sessions.
    ///
    func update(withSessions sessions: [CourseSessionModel]) {
        self.sessions = sessions
        
        NotificationCenter.default.post(name: Notification.Name(NotificationNames.modelChanged), object: self, userInfo: [Keys.sessions : self.sessions])
    }
    
    /// Changes structure with passed properties.
    ///
    /// - parameter session: Session to append.
    ///
    func update(byAppendingSession session: CourseSessionModel) {
        self.sessions.append(session)
        
        NotificationCenter.default.post(name: Notification.Name(NotificationNames.modelChanged), object: self, userInfo: [Keys.sessions : self.sessions])
    }
    
    /// Changes structure with passed properties.
    ///
    /// - parameter model: Course model.
    ///
    func update(withModel model: CourseModel) {
        self.copyProperties(fromModel: model)
        
        NotificationCenter.default.post(name: Notification.Name(NotificationNames.modelChanged), object: self, userInfo: [Keys.model : model])
    }
    
    /// Changes structure with passed properties.
    ///
    /// - parameter subscribed: Indicates whether the user has purchased this course.
    ///
    func update(withSubscribed subscribed: Bool) {
        self.subscribed = subscribed
        
        NotificationCenter.default.post(name: Notification.Name(NotificationNames.modelChanged), object: self, userInfo: [Keys.subscribed : subscribed])
    }
    
    /// Changes structure with passed properties.
    ///
    /// - parameter price: Course price.
    ///
    func update(withPrice price: NSDecimalNumber) {
        self.price = price
        
        NotificationCenter.default.post(name: Notification.Name(NotificationNames.modelChanged), object: self, userInfo: [Keys.price : price])
    }
    
    /// Changes structure with passed properties.
    ///
    /// - parameter priceTier: price Tier identifier
    ///
    func update(withPriceTier priceTier: String) {
        self.priceTier = priceTier
        
        NotificationCenter.default.post(name: Notification.Name(NotificationNames.modelChanged), object: self, userInfo: [Keys.priceTier : priceTier])
    }
    
    /// Changes structure with passed properties.
    ///
    /// - parameter earnings: Course earnings.
    ///
    func update(withEarnings earnings: NSDecimalNumber) {
        self.earnings = earnings
        
        NotificationCenter.default.post(name: Notification.Name(NotificationNames.modelChanged), object: self, userInfo: [Keys.earnings : earnings])
    }
    
    /// Removes delegate from the delegates list.
    ///
    /// - parameter delegate: Delegate. Responds to CourseModelDelegate.
    ///
    func removeDelegate(_ delegate: CourseModelDelegate?) {
        guard let object = delegate else {
            return
        }
        
        self.delegates.removeDelegate(delegate: object)
    }
    
    // MARK: Private Methods
    
    private func copyProperties(fromModel model: CourseModel) {
        self.id = model.id
        self.creatorID = model.creatorID
        self.creatorName = model.creatorName
        self.title = model.title
        self.specification = model.specification
        self.price = model.price
        self.priceTier = model.priceTier
        self.state = model.state
        self.earnings = model.earnings
        self.sessions = model.sessions
        self.attachments = model.attachments
        self.updatedTimestamp = model.updatedTimestamp
        self.createdTimestamp = model.createdTimestamp
        self.nearestSessionTimestamp = model.nearestSessionTimestamp
        self.previewImageURL = model.previewImageURL
        self.intros = model.intros
        self.webPage = model.webPage
        self.subscribed = model.subscribed
        self.imageSharingURL = model.imageSharingURL
        self.subscribersCount = model.subscribersCount
    }
    
    private func saveDelegate(_ delegate: CourseModelDelegate?) {
        guard let object = delegate else {
            return
        }
        
        self.delegates.addDelegate(delegate: object)
    }
    
}
