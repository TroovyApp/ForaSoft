//
//  CoursesService.swift
//  troovy-ios
//
//  Created by Daniil on 30.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import Foundation

enum CoursesReceiverTaskResult: Error {
    case methodSucceededWithObject(method: String, object: Any)
    case methodFailedWithObject(method: String, error: String?, object: Any)
}

protocol CoursesReceiverDelegate: class {
    func coursesReceiverHandle(taskResult result: CoursesReceiverTaskResult)
}

class CoursesService: TroovyService {

    private struct UserDefaultsKeys {
        static let coursesAllIdentifiers = "troovy_coursesAllIdentifiers"
        static let coursesSubscribedIdentifiers = "troovy_coursesSubscribedIdentifiers"
        static let coursesOwnIdentifiers = "troovy_coursesOwnIdentifiers"
    }
    
    // MARK: Public Properties
    
    /// Delegate. Responds to CoursesReceiverDelegate and processes CoursesReceiverTaskResult.
    weak var coursesReceiver: CoursesReceiverDelegate? {
        didSet {
            self.saveCoursesReceiver(self.coursesReceiver)
        }
    }
    
    // MARK: Private Properties
    
    private var coursesReceivers = MulticastDelegate<CoursesReceiverDelegate>()
    
    private var courseIdentifiersQueue: DispatchQueue! = DispatchQueue(label: "CourseIdentifiersQueue")
    private var coursesListDataServiceQueue: DispatchQueue! = DispatchQueue(label: "CoursesListDataServiceQueue")
    
    private let networkManager = NetworkManager.shared
    private let coreDataManager = CoreDataManager()
    
    private var coursesAllIdentifiersList = OrderedSet<CourseIdentifier>()
    private var coursesSubscribedIdentifiersList = OrderedSet<CourseIdentifier>()
    private var coursesOwnIdentifiersList = OrderedSet<CourseIdentifier>()
    private var coursesOtherIdentifiersList = OrderedSet<CourseIdentifier>()
    
    private var allCoursesHasNextPage = false
    private var subscribedCoursesHasNextPage = false
    private var ownCoursesHasNextPage = false
    private var otherCoursesHasNextPage = false
    
    private var otherCoursesUserID: String?
    
    private var loadAllCoursesTask: URLSessionTask?
    private var loadSubscribedCoursesTask: URLSessionTask?
    private var loadOwnCoursesTask: URLSessionTask?
    private var loadOtherCoursesTask: URLSessionTask?
    private var loadCourseTask: URLSessionTask?
    
    private var loadAllIdentifiersTask: URLSessionTask?
    private var loadSubscribedIdentifiersTask: URLSessionTask?
    private var loadOwnIdentifiersTask: URLSessionTask?
    private var loadOtherIdentifiersTask: URLSessionTask?
    
    // MARK: Init Methods & Superclass Overriders
    
    override init() {
        super.init()
        
        self.courseIdentifiersQueue.async {
            self.loadSavedCoursesIdentifiers()
        }
    }

    // MARK: Public Methods
    
    /// Updates course if exists.
    ///
    /// - parameter model: Course model.
    ///
    func updateCourse(withModel model: CourseModel) {
        self.coursesListDataServiceQueue.async {
            self.coreDataManager.saveCourseIfExists(withModel: model)
        }
    }
    
    /// Updates course sessions if exists.
    ///
    /// - parameter models: New course session models.
    /// - parameter courseID: Course server ID.
    ///
    func updateCourseSessions(withModels models: [CourseSessionModel], forCourseID courseID: String) {
        self.coursesListDataServiceQueue.async {
            self.coreDataManager.saveCourseSessionsIfExists(withCourseID: courseID, sessions: models)
        }
    }
    
    /// Updates course attachments if exists.
    ///
    /// - parameter models: New course attachment models.
    /// - parameter courseID: Course server ID.
    ///
    func updateCourseAttachments(withModels models: [CourseAttachmentModel], forCourseID courseID: String) {
        self.coursesListDataServiceQueue.async {
            self.coreDataManager.saveCourseAttachmentsIfExists(withCourseID: courseID, attachments: models)
        }
    }
    
    /// Updates course intros if exists.
    ///
    /// - parameter models: New course intro models.
    /// - parameter courseID: Course server ID.
    ///
    func updateCourseIntros(withModels models: [CourseIntroModel], forCourseID courseID: String) {
        self.coursesListDataServiceQueue.async {
            self.coreDataManager.saveCourseIntrosIfExists(withCourseID: courseID, intros: models)
        }
    }
    
    /// Updates course session if exists.
    ///
    /// - parameter model: Course model.
    ///
    func updateCourseSession(withModel model: CourseSessionModel) {
        self.coursesListDataServiceQueue.async {
            self.coreDataManager.updateCourseSessionIfExists(withSession: model)
        }
    }
    
    /// Loads course attachments from server and saves it to the core data.
    ///
    /// - parameter courseID: Course server ID.
    /// - parameter user: Authorised user model.
    /// - returns: Method name.
    ///
    func loadCourseAttachments(withCourseID courseID: String, user: AuthorisedUserModel?) -> String {
        let method = "loadCourseAttachments"
        self.serviceResultChanged(withResult: ServiceActionResult.methodStarted(method: method))
        
        self.networkManager.loadCourseAttachments(withNetworkToken: user?.networkToken, courseID: courseID) { (response, errorMessage, isCancelled) -> (Void) in
            if let result = response as? [[String:Any]] {
                self.saveCourseAttachmentsInfo(result, courseID: courseID)
                self.serviceResultChanged(withResult: ServiceActionResult.methodSucceededWithResponseArray(method: method, resultArray: result))
            } else {
                self.serviceResultChanged(withResult: ServiceActionResult.methodFailed(method: method, error: errorMessage))
            }
        }
        
        return method
    }
    
    /// Loads session attachments from server.
    ///
    /// - parameter courseID: Course server ID.
    /// - parameter user: Authorised user model.
    /// - returns: Method name.
    ///
    func loadSessionAttachments(withSessionID sessionID: String, user: AuthorisedUserModel?) -> String {
        let method = "loadSessionAttachments"
        self.serviceResultChanged(withResult: ServiceActionResult.methodStarted(method: method))
        
        self.networkManager.loadSessionAttachments(withNetworkToken: user?.networkToken, sessionID: sessionID) { (response, errorMessage, isCancelled) -> (Void) in
            if let result = response as? [[String:Any]] {
                self.serviceResultChanged(withResult: ServiceActionResult.methodSucceededWithResponseArray(method: method, resultArray: result))
            } else {
                self.serviceResultChanged(withResult: ServiceActionResult.methodFailed(method: method, error: errorMessage))
            }
        }
        
        return method
    }
    
    /// Loads course sessions from server and saves it to the core data.
    ///
    /// - parameter courseID: Course server ID.
    /// - parameter user: Authorised user model.
    /// - returns: Method name.
    ///
    func loadCourseSessions(withCourseID courseID: String, user: AuthorisedUserModel?) -> String {
        let method = "loadCourseSessions"
        self.serviceResultChanged(withResult: ServiceActionResult.methodStarted(method: method))
        
        self.networkManager.loadCourseSessions(withNetworkToken: user?.networkToken, courseID: courseID) { (response, errorMessage, isCancelled) -> (Void) in
            if let result = response as? [[String:Any]] {
                self.saveCourseSessionsInfo(result, courseID: courseID)
                self.serviceResultChanged(withResult: ServiceActionResult.methodSucceededWithResponseArray(method: method, resultArray: result))
            } else {
                self.serviceResultChanged(withResult: ServiceActionResult.methodFailed(method: method, error: errorMessage))
            }
        }
        
        return method
    }
    
    /// Loads course from server and saves it to the core data.
    ///
    /// - parameter courseID: Course server ID.
    /// - parameter user: Authorised user model.
    /// - returns: Method name.
    ///
    func loadCourseInfo(withCourseID courseID: String, user: AuthorisedUserModel?) -> String {
        let method = "loadCourse"
        self.serviceResultChanged(withResult: ServiceActionResult.methodStarted(method: method))
        
        if self.loadCourseTask != nil {
            self.loadCourseTask?.suspend()
            self.loadCourseTask?.cancel()
            self.loadCourseTask = nil
        }
        
        self.loadCourseTask = self.networkManager.loadCourse(withNetworkToken: user?.networkToken, courseID: courseID) { (response, errorMessage, isCancelled) -> (Void) in
            if isCancelled {
                self.serviceResultChanged(withResult: ServiceActionResult.methodCancelled(method: method))
            } else {
                if let result = response as? [String:Any] {
                    self.saveCourseInfo(result)
                    self.serviceResultChanged(withResult: ServiceActionResult.methodSucceededWithResponseDictionary(method: method, resultDictionary: result))
                } else {
                    self.serviceResultChanged(withResult: ServiceActionResult.methodFailed(method: method, error: errorMessage))
                }
            }
        }
        
        return method
    }
    
    /// Saves own course attachment to core data.
    ///
    /// - parameter model: Course attachment model.
    /// - parameter course: Course model.
    ///
    func saveOwnCourseAttachment(withModel model: CourseAttachmentModel, forCourse course: CourseModel) {
        self.coursesListDataServiceQueue.async {
            self.coreDataManager.appendCourseAttachmentIfExists(withCourseID: course.id, attachment: model)
        }
    }
    
    /// Saves own course session to core data.
    ///
    /// - parameter model: Course session model.
    /// - parameter course: Course model.
    ///
    func saveOwnCourseSession(withModel model: CourseSessionModel, forCourse course: CourseModel) {
        self.coursesListDataServiceQueue.async {
            self.coreDataManager.appendCourseSessionIfExists(withCourseID: course.id, session: model)
        }
    }
    
    /// Saves own course to core data and identifier to identifiers list.
    ///
    /// - parameter course: Course model.
    /// - returns: Method name.
    ///
    func saveOwnCourse(_ course: CourseModel) -> String {
        let method = "saveOwnCourse"
        let coursesServiceModel = CoursesServiceModel(listType: CourseListProperties.CourseListType.own, methodType: CourseListProperties.CourseListMethodType.addNewCourses)
        
        let identifier = CourseIdentifier(identifier: course.id, lastUpdateTimestamp: course.updatedTimestamp, sortingTimestamp: course.createdTimestamp)
        self.courseIdentifiersQueue.async {
            self.addOwnCourseIdentifier(identifier)
        }
        
        self.coursesListDataServiceQueue.async {
            self.coreDataManager.saveCourses(withModels: [course], completion: {
                let coursesModel = CoursesModel(withCourses: [course], coursesServiceModel: coursesServiceModel)
                self.coursesReceiverHandle(taskResult: CoursesReceiverTaskResult.methodSucceededWithObject(method: method, object: coursesModel))
            })
        }
        
        return method
    }
    
    /// Deletes own course from core data and identifier from identifiers list.
    ///
    /// - parameter course: Course model.
    ///
    func deleteOwnCourse(_ course: CourseModel) {
        let method = "deleteOwnCourse"
        let coursesServiceModel = CoursesServiceModel(listType: CourseListProperties.CourseListType.own, methodType: CourseListProperties.CourseListMethodType.deleteCourse)
        
        let identifier = CourseIdentifier(identifier: course.id, lastUpdateTimestamp: course.updatedTimestamp, sortingTimestamp: course.createdTimestamp)
        self.courseIdentifiersQueue.async {
            self.deleteOwnCourseIdentifier(identifier)
        }
        
        self.coursesListDataServiceQueue.async {
            self.coreDataManager.deleteCourseIfExists(withModel: course)
        }
        
        let coursesModel = CoursesModel(withCourses: [course], coursesServiceModel: coursesServiceModel)
        self.coursesReceiverHandle(taskResult: CoursesReceiverTaskResult.methodSucceededWithObject(method: method, object: coursesModel))
    }
    
    /// Deletes own session from core data.
    ///
    /// - parameter session: Course model.
    ///
    func deleteOwnSession(_ session: CourseSessionModel) {
        self.coursesListDataServiceQueue.async {
            self.coreDataManager.deleteSessionIfExists(withModel: session)
        }
    }
    
    /// Removes all courses and identifiers and cancels load courses tasks.
    func removeCoursesAndIdentifiers() {
        self.cancelCoursesLoading(forListType: CourseListProperties.CourseListType.all)
        self.cancelCoursesLoading(forListType: CourseListProperties.CourseListType.subscribed)
        self.cancelCoursesLoading(forListType: CourseListProperties.CourseListType.own)
        self.cancelCoursesLoading(forListType: CourseListProperties.CourseListType.other)
        
        self.coursesListDataServiceQueue.async {
            self.coreDataManager.removeCoursesCoreDataEntities()
        }
        
        self.courseIdentifiersQueue.async {
            self.removeCoursesIdentifiers()
        }
    }
    
    /// Cancels processing of all courses network tasks.
    func cancelAllCoursesLoading() {
        self.loadCourseTask?.suspend()
        self.loadCourseTask?.cancel()
        self.loadCourseTask = nil
        
        self.cancelCoursesLoading(forListType: CourseListProperties.CourseListType.all)
        self.cancelCoursesLoading(forListType: CourseListProperties.CourseListType.subscribed)
        self.cancelCoursesLoading(forListType: CourseListProperties.CourseListType.own)
        self.cancelCoursesLoading(forListType: CourseListProperties.CourseListType.other)
    }
    
    /// Cancels processing of load course network task.
    func cancelCourseLoading() {
        self.loadCourseTask?.suspend()
        self.loadCourseTask?.cancel()
        self.loadCourseTask = nil
    }
    
    /// Cancels processing of courses network task with specified type.
    ///
    /// - parameter type: Type of the courses list.
    ///
    func cancelCoursesLoading(forListType type: CourseListProperties.CourseListType) {
        switch type {
        case .all:
            self.loadAllIdentifiersTask?.suspend()
            self.loadAllIdentifiersTask?.cancel()
            self.loadAllIdentifiersTask = nil
            
            self.loadAllCoursesTask?.suspend()
            self.loadAllCoursesTask?.cancel()
            self.loadAllCoursesTask = nil
            break
        case .subscribed:
            self.loadSubscribedIdentifiersTask?.suspend()
            self.loadSubscribedIdentifiersTask?.cancel()
            self.loadSubscribedIdentifiersTask = nil
            
            self.loadSubscribedCoursesTask?.suspend()
            self.loadSubscribedCoursesTask?.cancel()
            self.loadSubscribedCoursesTask = nil
            break
        case .own:
            self.loadOwnIdentifiersTask?.suspend()
            self.loadOwnIdentifiersTask?.cancel()
            self.loadOwnIdentifiersTask = nil
            
            self.loadOwnCoursesTask?.suspend()
            self.loadOwnCoursesTask?.cancel()
            self.loadOwnCoursesTask = nil
            break
        case .other:
            self.loadOtherIdentifiersTask?.suspend()
            self.loadOtherIdentifiersTask?.cancel()
            self.loadOtherIdentifiersTask = nil
            
            self.loadOtherCoursesTask?.suspend()
            self.loadOtherCoursesTask?.cancel()
            self.loadOtherCoursesTask = nil
            break
        }
    }
    
    /// Finds courses identifiers to load and to fetch from saved identifiers.
    ///
    /// - parameter listType: Type of the courses list.
    /// - parameter methodType: Type of the courses list method.
    /// - parameter userID: User server ID of courses owner.
    /// - parameter shouldReloadData: If true begins search from start. If false begins search from coursesLoadedCount.
    /// - parameter coursesLoadedCount: Count of already fetched courses.
    /// - parameter coursesCountToLoad: Count of courses to fetch and load.
    /// - returns: Method name.
    ///
    func coursesIdentifiersToLoadAndFetch(forListType listType: CourseListProperties.CourseListType, methodType: CourseListProperties.CourseListMethodType, userID: String?, shouldReloadData: Bool, coursesLoadedCount: Int, coursesCountToLoad: Int) -> String {
        if listType == .other && self.otherCoursesUserID != userID {
            self.otherCoursesUserID = userID
            self.cancelCoursesLoading(forListType: CourseListProperties.CourseListType.other)
            
            self.courseIdentifiersQueue.async {
                self.coursesOtherIdentifiersList = OrderedSet<CourseIdentifier>()
            }
        }
        
        let method = "coursesIdentifiersToLoadAndFetch"
        let coursesServiceModel = CoursesServiceModel(listType: listType, methodType: methodType)
        let loadedCount = (shouldReloadData ? 0 : coursesLoadedCount)
        
        self.courseIdentifiersQueue.async {
            self.findCoursesIdentifiersToLoadAndFetch(forListType: listType, coursesLoadedCount: loadedCount, coursesCountToLoad: coursesCountToLoad) { (coursesIdentifiersToLoad, coursesIdentifiersToFetch, loadNextPage) -> (Void) in
                let coursesIdentifiersModel = CoursesIdentifiersModel(withIdentifiersToLoad: coursesIdentifiersToLoad, identifiersToFetch: coursesIdentifiersToFetch, shouldLoadNextPage: loadNextPage, coursesServiceModel: coursesServiceModel)
                
                self.coursesReceiverHandle(taskResult: CoursesReceiverTaskResult.methodSucceededWithObject(method: method, object: coursesIdentifiersModel))
            }
        }
        
        return method
    }
    
    /// Loads courses identifiers from server.
    ///
    /// - parameter listType: Type of courses list.
    /// - parameter methodType: Type of the courses list method.
    /// - parameter user: Authorised user model.
    /// - parameter userID: User server ID of courses owner.
    /// - parameter page: Page of identifiers to load.
    /// - parameter count: Count of identifiers to load.
    /// - returns: Method name.
    ///
    func loadCoursesIdentifiers(forListType listType: CourseListProperties.CourseListType, methodType: CourseListProperties.CourseListMethodType, user: AuthorisedUserModel?, userID: String?, page: Int, count: Int) -> String {
        let method = "loadCoursesIdentifiers"
        let coursesServiceModel = CoursesServiceModel(listType: listType, methodType: methodType)
        let ownerID = (listType == .other ? userID : nil)
        
        let loadIdentifiersTask = self.networkManager.loadCoursesIdentifiers(withNetworkToken: user?.networkToken, userID: ownerID, page: page, count: count, type: listType) { (response, errorMessage, isCancelled) -> (Void) in
            if isCancelled {
                return
            } else {
                if let result = response as? [[String:Any]] {
                    let hasNextPage = (result.count >= count)
                    
                    var identifiers: [CourseIdentifier] = []
                    for identifierDictionary in result {
                        let identifier = CourseIdentifier(dictionary: identifierDictionary)
                        identifiers.append(identifier)
                    }
                    
                    self.courseIdentifiersQueue.async {
                        self.saveCoursesIdentifiers(identifiers, forListType: listType, page: page, hasNextPage: hasNextPage)
                    }
                    
                    self.coursesReceiverHandle(taskResult: CoursesReceiverTaskResult.methodSucceededWithObject(method: method, object: coursesServiceModel))
                } else {
                    self.coursesReceiverHandle(taskResult: CoursesReceiverTaskResult.methodFailedWithObject(method: method, error: errorMessage, object: coursesServiceModel))
                }
            }
        }
        
        switch listType {
        case .all:
            self.loadAllIdentifiersTask = loadIdentifiersTask
            break
        case .subscribed:
            self.loadSubscribedIdentifiersTask = loadIdentifiersTask
            break
        case .own:
            self.loadOwnIdentifiersTask = loadIdentifiersTask
            break
        case .other:
            self.loadOtherIdentifiersTask = loadIdentifiersTask
            break
        }
        
        return method
    }
    
    /// Fetches courses from core data with passed identifiers.
    ///
    /// - parameter listType: Type of courses list.
    /// - parameter methodType: Type of the courses list method.
    /// - parameter identifiers: Array of server identifiers of the courses.
    /// - returns: Method name.
    ///
    func fetchCourses(forListType listType: CourseListProperties.CourseListType, methodType: CourseListProperties.CourseListMethodType, identifiers: [String]) -> String {
        let method = "fetchCourses"
        let coursesServiceModel = CoursesServiceModel(listType: listType, methodType: methodType)
        
        self.coursesListDataServiceQueue.async {
            self.coreDataManager.fetchCoursesCoreDataModels(forListType: listType, identifiers: identifiers, completion: { (courseModels) -> (Void) in
                let coursesModel = CoursesModel(withCourses: courseModels, coursesServiceModel: coursesServiceModel)
                
                self.coursesReceiverHandle(taskResult: CoursesReceiverTaskResult.methodSucceededWithObject(method: method, object: coursesModel))
            })
        }
        
        return method
    }
    
    /// Loads sessions for user.
    ///
    /// - parameter user: Authorised user model.
    /// - returns: Method name.
    ///
    func loadSessions(forUser user: AuthorisedUserModel?) -> String {
        let method = "loadSessions"
        self.serviceResultChanged(withResult: ServiceActionResult.methodStarted(method: method))
        
        self.networkManager.loadSessions(withNetworkToken: user?.networkToken) { (response, errorMessage, isCancelled) -> (Void) in
            if let result = response as? [[String:Any]] {
                self.serviceResultChanged(withResult: ServiceActionResult.methodSucceededWithResponseArray(method: method, resultArray: result))
            } else {
                self.serviceResultChanged(withResult: ServiceActionResult.methodFailed(method: method, error: errorMessage))
            }
        }
        return method
    }
    
    /// Loads courses from server with passed identifiers.
    ///
    /// - parameter listType: Type of courses list.
    /// - parameter methodType: Type of the courses list method.
    /// - parameter user: Authorised user model.
    /// - parameter identifiers: Array of server identifiers of the courses.
    /// - returns: Method name.
    ///
    func loadCourses(forListType listType: CourseListProperties.CourseListType, methodType: CourseListProperties.CourseListMethodType, user: AuthorisedUserModel?, identifiers: [String]) -> String {
        let method = "loadCourses"
        let coursesServiceModel = CoursesServiceModel(listType: listType, methodType: methodType)
        
        let loadCoursesTask = self.networkManager.loadCourses(withNetworkToken: user?.networkToken, identifiers: identifiers, type: listType) { (response, errorMessage, isCancelled) -> (Void) in
            if isCancelled {
                return
            } else {
                if let result = response as? [[String:Any]] {
                    self.processCoursesResponse(result, completion: {
                        self.coursesReceiverHandle(taskResult: CoursesReceiverTaskResult.methodSucceededWithObject(method: method, object: coursesServiceModel))
                    })
                } else {
                    self.coursesReceiverHandle(taskResult: CoursesReceiverTaskResult.methodFailedWithObject(method: method, error: errorMessage, object: coursesServiceModel))
                }
            }
        }
        
        switch listType {
        case .all:
            self.loadAllCoursesTask = loadCoursesTask
            break
        case .subscribed:
            self.loadSubscribedCoursesTask = loadCoursesTask
            break
        case .own:
            self.loadOwnCoursesTask = loadCoursesTask
            break
        case .other:
            self.loadOtherCoursesTask = loadCoursesTask
            break
        }
        
        return method
    }
    
    // MARK: Private Methods
    
    // MARK: Courses
    
    private func saveCourseAttachmentsInfo(_ attachmentsInfo: [[String:Any]], courseID: String) {
        var attachments: [CourseAttachmentModel] = []
        for info in attachmentsInfo {
            let attachment = CourseAttachmentModel(withDictionary: info)
            attachments.append(attachment)
        }
        
        self.coursesListDataServiceQueue.async {
            self.coreDataManager.saveCourseAttachmentsIfExists(withCourseID: courseID, attachments: attachments)
        }
    }
    
    private func saveCourseSessionsInfo(_ sessionsInfo: [[String:Any]], courseID: String) {
        var sessions: [CourseSessionModel] = []
        for info in sessionsInfo {
            let session = CourseSessionModel(withDictionary: info)
            sessions.append(session)
        }
        
        self.coursesListDataServiceQueue.async {
            self.coreDataManager.saveCourseSessionsIfExists(withCourseID: courseID, sessions: sessions)
        }
    }
    
    private func saveCourseInfo(_ info: [String:Any]) {
        let course = CourseModel(withDictionary: info)
        
        self.coursesListDataServiceQueue.async {
            self.coreDataManager.saveCourseIfExists(withModel: course)
        }
    }
    
    private func processCoursesResponse(_ reponse: [[String:Any]], completion: @escaping () -> ()) {
        var courses: [CourseModel] = []
        for object in reponse {
            let course = CourseModel(withDictionary: object)
            courses.append(course)
        }
        
        self.coursesListDataServiceQueue.async {
            self.coreDataManager.saveCourses(withModels: courses, completion: { 
                DispatchQueue.global().async {
                    completion()
                }
            })
        }
    }
    
    // MARK: Courses Identifiers
    
    private func findCoursesIdentifiersToLoadAndFetch(forListType type: CourseListProperties.CourseListType, coursesLoadedCount: Int, coursesCountToLoad: Int, completion: @escaping (_ coursesIdentifiersToLoad: [String], _ coursesIdentifiersToFetch: [String], _ loadNextPage: Bool) -> (Void)) {
        var coursesIdentifiersToLoad: [String] = []
        var coursesIdentifiersToFetch: [String] = []
        var coursesTimestamps: [Int64] = []
        
        var contentIdentifiersList: OrderedSet<CourseIdentifier>?
        var hasNextPage = false
        switch type {
        case .all:
            contentIdentifiersList = self.coursesAllIdentifiersList
            hasNextPage = self.allCoursesHasNextPage
            break
        case .subscribed:
            contentIdentifiersList = self.coursesSubscribedIdentifiersList
            hasNextPage = self.subscribedCoursesHasNextPage
            break
        case .own:
            contentIdentifiersList = self.coursesOwnIdentifiersList
            hasNextPage = self.ownCoursesHasNextPage
            break
        case .other:
            contentIdentifiersList = self.coursesOtherIdentifiersList
            hasNextPage = self.otherCoursesHasNextPage
            break
        }
        
        if contentIdentifiersList != nil && contentIdentifiersList!.count > coursesLoadedCount {
            let startCount = coursesLoadedCount
            let endCount = coursesLoadedCount + coursesCountToLoad
            for index in startCount..<endCount {
                if index >= contentIdentifiersList!.count {
                    break
                }
                
                let identifier = contentIdentifiersList![index]
                coursesIdentifiersToLoad.append(identifier.identifier)
                coursesTimestamps.append(identifier.lastUpdateTimestamp)
            }
            
            self.coursesListDataServiceQueue.async {
                self.coreDataManager.fetchCoursesTimestamps(forListType: type, identifiers: coursesIdentifiersToLoad, completion: { (identifiersToTimestamps) -> (Void) in
                    var contentIdentifiersToRemove: [String] = []
                    for (identifier, courseTimestamp) in identifiersToTimestamps {
                        if let index = coursesIdentifiersToLoad.index(of: identifier) {
                            let timestamp = coursesTimestamps[index]
                            if courseTimestamp >= timestamp {
                                contentIdentifiersToRemove.append(identifier)
                            }
                        }
                    }
                    
                    for identifier in contentIdentifiersToRemove {
                        if let index = coursesIdentifiersToLoad.index(of: identifier) {
                            coursesIdentifiersToLoad.remove(at: index)
                            coursesIdentifiersToFetch.append(identifier)
                        }
                    }
                    
                    DispatchQueue.global().async {
                        completion(coursesIdentifiersToLoad, coursesIdentifiersToFetch, false)
                    }
                })
            }
        } else {
            DispatchQueue.global().async {
                completion(coursesIdentifiersToLoad, coursesIdentifiersToFetch, hasNextPage)
            }
        }
    }
    
    private func addOwnCourseIdentifier(_ identifier: CourseIdentifier) {
        self.coursesOwnIdentifiersList.insert(item: identifier)
        
        self.saveCoursesOwnIdentifiers()
    }
    
    private func deleteOwnCourseIdentifier(_ identifier: CourseIdentifier) {
        self.coursesOwnIdentifiersList.remove(item: identifier)
        
        self.saveCoursesOwnIdentifiers()
    }
    
    private func saveCoursesIdentifiers(_ identifiers: [CourseIdentifier], forListType type: CourseListProperties.CourseListType, page: Int, hasNextPage: Bool) {
        switch type {
        case .all:
            if page == 0 {
                var contentIdentifiersList = OrderedSet<CourseIdentifier>()
                for identifier in identifiers {
                    contentIdentifiersList.insert(item: identifier)
                }
                self.coursesAllIdentifiersList = contentIdentifiersList
            } else {
                for identifier in identifiers {
                    self.coursesAllIdentifiersList.insert(item: identifier)
                }
            }
            
            self.allCoursesHasNextPage = hasNextPage
            self.saveCoursesAllIdentifiers()
            break
        case .subscribed:
            if page == 0 {
                var contentIdentifiersList = OrderedSet<CourseIdentifier>()
                for identifier in identifiers {
                    contentIdentifiersList.insert(item: identifier)
                }
                self.coursesSubscribedIdentifiersList = contentIdentifiersList
            } else {
                for identifier in identifiers {
                    self.coursesSubscribedIdentifiersList.insert(item: identifier)
                }
            }
            self.subscribedCoursesHasNextPage = hasNextPage
            self.saveCoursesSubscribedIdentifiers()
            break
        case .own:
            if page == 0 {
                var contentIdentifiersList = OrderedSet<CourseIdentifier>()
                for identifier in identifiers {
                    contentIdentifiersList.insert(item: identifier)
                }
                self.coursesOwnIdentifiersList = contentIdentifiersList
            } else {
                for identifier in identifiers {
                    self.coursesOwnIdentifiersList.insert(item: identifier)
                }
            }
            
            self.ownCoursesHasNextPage = hasNextPage
            self.saveCoursesOwnIdentifiers()
            break
        case .other:
            if page == 0 {
                var contentIdentifiersList = OrderedSet<CourseIdentifier>()
                for identifier in identifiers {
                    contentIdentifiersList.insert(item: identifier)
                }
                self.coursesOtherIdentifiersList = contentIdentifiersList
            } else {
                for identifier in identifiers {
                    self.coursesOtherIdentifiersList.insert(item: identifier)
                }
            }
            
            self.otherCoursesHasNextPage = hasNextPage
            break
        }
    }
    
    private func loadSavedCoursesIdentifiers() {
        if let coursesIdentifiersData = UserDefaults.standard.object(forKey: UserDefaultsKeys.coursesAllIdentifiers) as? Data {
            if let coursesIdentifiersList = NSKeyedUnarchiver.unarchiveObject(with: coursesIdentifiersData) as? [CourseIdentifier] {
                self.coursesAllIdentifiersList = OrderedSet.init(withSet: coursesIdentifiersList)
            }
        }
        
        if let coursesIdentifiersData = UserDefaults.standard.object(forKey: UserDefaultsKeys.coursesSubscribedIdentifiers) as? Data {
            if let coursesIdentifiersList = NSKeyedUnarchiver.unarchiveObject(with: coursesIdentifiersData) as? [CourseIdentifier] {
                self.coursesSubscribedIdentifiersList = OrderedSet.init(withSet: coursesIdentifiersList)
            }
        }
        
        if let coursesIdentifiersData = UserDefaults.standard.object(forKey: UserDefaultsKeys.coursesOwnIdentifiers) as? Data {
            if let coursesIdentifiersList = NSKeyedUnarchiver.unarchiveObject(with: coursesIdentifiersData) as? [CourseIdentifier] {
                self.coursesOwnIdentifiersList = OrderedSet.init(withSet: coursesIdentifiersList)
            }
        }
    }
    
    private func removeCoursesIdentifiers() {
        if UserDefaults.standard.object(forKey: UserDefaultsKeys.coursesAllIdentifiers) != nil {
            UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.coursesAllIdentifiers)
        }
        self.coursesAllIdentifiersList = OrderedSet<CourseIdentifier>()
        
        if UserDefaults.standard.object(forKey: UserDefaultsKeys.coursesSubscribedIdentifiers) != nil {
            UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.coursesSubscribedIdentifiers)
        }
        self.coursesSubscribedIdentifiersList = OrderedSet<CourseIdentifier>()
        
        if UserDefaults.standard.object(forKey: UserDefaultsKeys.coursesOwnIdentifiers) != nil {
            UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.coursesOwnIdentifiers)
        }
        self.coursesOwnIdentifiersList = OrderedSet<CourseIdentifier>()
        
        UserDefaults.standard.synchronize()
    }
    
    private func saveCoursesAllIdentifiers() {
        let coursesIdentifiersData = NSKeyedArchiver.archivedData(withRootObject: self.coursesAllIdentifiersList.internalSet)
        UserDefaults.standard.set(coursesIdentifiersData, forKey: UserDefaultsKeys.coursesAllIdentifiers)
        UserDefaults.standard.synchronize()
    }
    
    private func saveCoursesSubscribedIdentifiers() {
        let coursesIdentifiersData = NSKeyedArchiver.archivedData(withRootObject: self.coursesSubscribedIdentifiersList.internalSet)
        UserDefaults.standard.set(coursesIdentifiersData, forKey: UserDefaultsKeys.coursesSubscribedIdentifiers)
        UserDefaults.standard.synchronize()
    }
    
    private func saveCoursesOwnIdentifiers() {
        let coursesIdentifiersData = NSKeyedArchiver.archivedData(withRootObject: self.coursesOwnIdentifiersList.internalSet)
        UserDefaults.standard.set(coursesIdentifiersData, forKey: UserDefaultsKeys.coursesOwnIdentifiers)
        UserDefaults.standard.synchronize()
    }
    
    // MARK: Other Methods
    
    private func saveCoursesReceiver(_ receiver: CoursesReceiverDelegate?) {
        guard let object = receiver else {
            return
        }
        
        self.coursesReceivers.addDelegate(delegate: object)
    }
    
    private func coursesReceiverHandle(taskResult result: CoursesReceiverTaskResult) {
        self.coursesReceivers.invoke { (coursesReceiver) in
            if Thread.isMainThread {
                coursesReceiver.coursesReceiverHandle(taskResult: result)
            } else {
                DispatchQueue.main.async {
                    coursesReceiver.coursesReceiverHandle(taskResult: result)
                }
            }
        }
    }
    
}
