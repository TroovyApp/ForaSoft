//
//  CoreDataManager.swift
//  troovy-ios
//
//  Created by Daniil on 30.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import CoreData

class CoreDataManager {
    
    private struct UserDefaultsKeys {
        static let coursesIdentifiers = "troovy_coursesIdentifiers"
    }

    private struct CoreData {
        static let name = "TroovyCoreData"
        
        struct Entities {
            
            struct Courses {
                static let name = "Courses"
                
                struct Fields {
                    static let id = "identifier"
                    static let creatorID = "creatorID"
                    static let creatorName = "creatorName"
                    static let title = "title"
                    static let specification = "details"
                    static let price = "price"
                    static let priceTier = "priceTier"
                    static let state = "state"
                    static let earnings = "earnings"
                    static let updatedTimestamp = "updatedAt"
                    static let createdTimestamp = "createdAt"
                    static let nearestSessionTimestamp = "nearestSessionAt"
                    static let webPage = "webPage"
                    static let subscribed = "subscribed"
                    static let previewImageURL = "previewImageURL"
                    static let imageSharingURL = "courseImageSharingUrl"
                    static let subscribersCount = "subscribersCount"
                }
                
                struct Relations {
                    static let attachments = "attachments"
                    static let sessions = "sessions"
                    static let intros = "intros"
                }
            }
            
            struct Sessions {
                static let name = "Sessions"
                
                struct Fields {
                    static let id = "identifier"
                    static let title = "title"
                    static let specification = "details"
                    static let duration = "duration"
                    static let startTimestamp = "startAt"
                    static let updatedTimestamp = "updatedAt"
                }
            }
            
            struct Attachments {
                static let name = "Attachments"
                
                struct Fields {
                    static let id = "identifier"
                    static let type = "type"
                    static let fileAddress = "fileUrl"
                    static let thumbnailAddress = "thumbnailUrl"
                    static let filePath = "filePath"
                    static let createdTimestamp = "createdAt"
                }
            }
            
            struct Intros {
                static let name = "Intros"
                
                struct Fields {
                    static let id = "identifier"
                    static let type = "type"
                    static let fileAddress = "fileUrl"
                    static let thumbnailAddress = "thumbnailUrl"
                    static let order = "order"
                }
            }
        }
    }

    // MARK: Private Properties
    
    private var writerContext: NSManagedObjectContext!
    
    // MARK: Init Methods & Superclass Overriders
    
    init() {
        self.setupCoreDataStack()
    }
    
    // MARK: Public Methods
    
    /// Removes courses entities from the core data. Relations deletes with cascade mode.
    func removeCoursesCoreDataEntities() {
        let context = NSManagedObjectContext.init(concurrencyType: .privateQueueConcurrencyType)
        context.parent = self.writerContext
        
        context.perform {
            let deleteFetchRequest = NSFetchRequest<NSFetchRequestResult>.init(entityName: CoreData.Entities.Courses.name)
            let deleteBatchRequest = NSBatchDeleteRequest(fetchRequest: deleteFetchRequest)
            
            do {
                try context.execute(deleteBatchRequest)
            } catch {
                let nserror = error as NSError
                print("Unresolved error \(nserror), \(nserror.userInfo)")
            }
            
            self.coreDataSave(context: context)
            
            self.writerContext.perform {
                self.coreDataSave(context: self.writerContext)
            }
        }
    }
    
    /// Fetches courses with passed identifiers.
    ///
    /// - parameter type: Type of courses list.
    /// - parameter identifiers: Array of server identifiers of the courses.
    /// - parameter completion: Completion block. Calls with array of course models after fetching completed.
    ///
    func fetchCoursesCoreDataModels(forListType type: CourseListProperties.CourseListType, identifiers: [String], completion: @escaping (_ models: [CourseModel]) -> (Void)) {
        let context = NSManagedObjectContext.init(concurrencyType: .privateQueueConcurrencyType)
        context.parent = self.writerContext
        
        context.perform {
            let predicate = NSPredicate(format: "\(CoreData.Entities.Courses.Fields.id) IN %@", identifiers)
            
            let fetchRequest = NSFetchRequest<NSManagedObject>.init(entityName: CoreData.Entities.Courses.name)
            fetchRequest.predicate = predicate
            fetchRequest.sortDescriptors = self.coursesSortDescriptors(forListType: type)
            
            var courses: [CourseModel] = []
            if let fetchRequestResult = try? context.fetch(fetchRequest) {
                for coreDataCourse in fetchRequestResult {
                    let course = self.courseModel(fromManagedObject: coreDataCourse)
                    courses.append(course)
                }
            }
            
            completion(courses)
        }
    }
    
    /// Fetches courses timestamps.
    ///
    /// - parameter type: Type of courses list.
    /// - parameter identifiers: Array of server identifiers of the courses.
    /// - parameter completion: Completion block. Calls with dictionary with pairs of courses identifiers and courses update timestamps after fetching completed.
    ///
    func fetchCoursesTimestamps(forListType type: CourseListProperties.CourseListType, identifiers: [String], completion: @escaping (_ identifiersToTimestamps: [String:Int64]) -> (Void)) {
        let context = NSManagedObjectContext.init(concurrencyType: .privateQueueConcurrencyType)
        context.parent = self.writerContext
        
        context.perform {
            let predicate = NSPredicate(format: "\(CoreData.Entities.Courses.Fields.id) IN %@", identifiers)
            
            let fetchRequest = NSFetchRequest<NSDictionary>.init(entityName: CoreData.Entities.Courses.name)
            fetchRequest.resultType = .dictionaryResultType
            fetchRequest.propertiesToFetch = [CoreData.Entities.Courses.Fields.id, CoreData.Entities.Courses.Fields.updatedTimestamp]
            fetchRequest.predicate = predicate
            fetchRequest.sortDescriptors = self.coursesSortDescriptors(forListType: type)
            
            var identifiersToTimestamps: [String:Int64] = [:]
            if let fetchRequestResult = try? context.fetch(fetchRequest) {
                for object in fetchRequestResult {
                    let identifier = object.value(forKey: CoreData.Entities.Courses.Fields.id) as! String
                    let updatedTimestamp = object.value(forKey: CoreData.Entities.Courses.Fields.updatedTimestamp) as! Int64
                    identifiersToTimestamps[identifier] = updatedTimestamp
                }
            }
            
            completion(identifiersToTimestamps)
        }
    }
    
    /// Appends course attachment if such course exists.
    ///
    /// - parameter courseID: Course server ID.
    /// - parameter attachment: Course attachment.
    ///
    func appendCourseAttachmentIfExists(withCourseID courseID: String, attachment: CourseAttachmentModel) {
        let context = NSManagedObjectContext.init(concurrencyType: .privateQueueConcurrencyType)
        context.parent = self.writerContext
        
        context.perform {
            guard let _ = NSEntityDescription.entity(forEntityName: CoreData.Entities.Courses.name, in: context), let _ = NSEntityDescription.entity(forEntityName: CoreData.Entities.Sessions.name, in: context), let attachmentsEntity = NSEntityDescription.entity(forEntityName: CoreData.Entities.Attachments.name, in: context) else {
                return
            }
            
            let fetchRequest = NSFetchRequest<NSManagedObject>.init(entityName: CoreData.Entities.Courses.name)
            fetchRequest.predicate = NSPredicate(format: "\(CoreData.Entities.Courses.Fields.id) = %@", courseID)
            fetchRequest.fetchLimit = 1
            
            let fetchRequestResult = try? context.fetch(fetchRequest)
            if let coreDataCourse = fetchRequestResult?.first {
                let coreDataAttachment = self.createAttachmentManagedObject(fromModel: attachment, inContext: context, entity: attachmentsEntity)
                self.configure(coreDataAttachment: coreDataAttachment, withModel: attachment)
                
                if var coreDataAttachments = coreDataCourse.value(forKey: CoreData.Entities.Courses.Relations.attachments) as? Set<NSManagedObject> {
                    coreDataAttachments.insert(coreDataAttachment)
                    coreDataCourse.setValue(coreDataAttachments, forKeyPath: CoreData.Entities.Courses.Relations.attachments)
                } else {
                    var coreDataAttachments = Set<NSManagedObject>()
                    coreDataAttachments.insert(coreDataAttachment)
                    coreDataCourse.setValue(coreDataAttachments, forKeyPath: CoreData.Entities.Courses.Relations.attachments)
                }
                
                self.coreDataSave(context: context)
                
                self.writerContext.perform {
                    self.coreDataSave(context: self.writerContext)
                }
            }
        }
    }
    
    /// Saves course attachments if such course exists.
    ///
    /// - parameter courseID: Course server ID.
    /// - parameter attachments: Array of course attachments.
    ///
    func saveCourseAttachmentsIfExists(withCourseID courseID: String, attachments: [CourseAttachmentModel]) {
        let context = NSManagedObjectContext.init(concurrencyType: .privateQueueConcurrencyType)
        context.parent = self.writerContext
        
        context.perform {
            guard let _ = NSEntityDescription.entity(forEntityName: CoreData.Entities.Courses.name, in: context), let _ = NSEntityDescription.entity(forEntityName: CoreData.Entities.Sessions.name, in: context), let attachmentsEntity = NSEntityDescription.entity(forEntityName: CoreData.Entities.Attachments.name, in: context) else {
                return
            }
            
            let fetchRequest = NSFetchRequest<NSManagedObject>.init(entityName: CoreData.Entities.Courses.name)
            fetchRequest.predicate = NSPredicate(format: "\(CoreData.Entities.Courses.Fields.id) = %@", courseID)
            fetchRequest.fetchLimit = 1
            
            let fetchRequestResult = try? context.fetch(fetchRequest)
            if let coreDataCourse = fetchRequestResult?.first {
                if let coreDataAttachments = coreDataCourse.value(forKey: CoreData.Entities.Courses.Relations.attachments) as? Set<NSManagedObject> {
                    var identifiers: [String] = []
                    for coreDataAttachment in coreDataAttachments {
                        let identifier = coreDataAttachment.value(forKey: CoreData.Entities.Attachments.Fields.id) as! String
                        identifiers.append(identifier)
                    }
                    
                    if identifiers.count > 0 {
                        let deleteFetchRequest = NSFetchRequest<NSFetchRequestResult>.init(entityName: CoreData.Entities.Attachments.name)
                        deleteFetchRequest.predicate = NSPredicate(format: "\(CoreData.Entities.Attachments.Fields.id) IN %@", identifiers)
                        let deleteBatchRequest = NSBatchDeleteRequest(fetchRequest: deleteFetchRequest)
                        
                        do {
                            try context.execute(deleteBatchRequest)
                        } catch {
                            let nserror = error as NSError
                            print("Unresolved error \(nserror), \(nserror.userInfo)")
                        }
                    }
                }
                
                var coreDataAttachments = Set<NSManagedObject>()
                for attachment in attachments {
                    let coreDataAttachment = self.createAttachmentManagedObject(fromModel: attachment, inContext: context, entity: attachmentsEntity)
                    self.configure(coreDataAttachment: coreDataAttachment, withModel: attachment)
                    coreDataAttachments.insert(coreDataAttachment)
                }
                
                coreDataCourse.setValue(coreDataAttachments, forKeyPath: CoreData.Entities.Courses.Relations.attachments)
                
                self.coreDataSave(context: context)
                
                self.writerContext.perform {
                    self.coreDataSave(context: self.writerContext)
                }
            }
        }
    }
    
    /// Saves course intros if such course exists.
    ///
    /// - parameter courseID: Course server ID.
    /// - parameter intros: Array of course intros.
    ///
    func saveCourseIntrosIfExists(withCourseID courseID: String, intros: [CourseIntroModel]) {
        let context = NSManagedObjectContext.init(concurrencyType: .privateQueueConcurrencyType)
        context.parent = self.writerContext
        
        context.perform {
            guard let _ = NSEntityDescription.entity(forEntityName: CoreData.Entities.Courses.name, in: context), let _ = NSEntityDescription.entity(forEntityName: CoreData.Entities.Sessions.name, in: context), let _ = NSEntityDescription.entity(forEntityName: CoreData.Entities.Attachments.name, in: context), let introsEntity = NSEntityDescription.entity(forEntityName: CoreData.Entities.Intros.name, in: context) else {
                return
            }
            
            let fetchRequest = NSFetchRequest<NSManagedObject>.init(entityName: CoreData.Entities.Courses.name)
            fetchRequest.predicate = NSPredicate(format: "\(CoreData.Entities.Courses.Fields.id) = %@", courseID)
            fetchRequest.fetchLimit = 1
            
            let fetchRequestResult = try? context.fetch(fetchRequest)
            if let coreDataCourse = fetchRequestResult?.first {
                if let coreDataIntros = coreDataCourse.value(forKey: CoreData.Entities.Courses.Relations.intros) as? Set<NSManagedObject> {
                    var identifiers: [String] = []
                    for coreDataIntro in coreDataIntros {
                        let identifier = coreDataIntro.value(forKey: CoreData.Entities.Intros.Fields.id) as! String
                        identifiers.append(identifier)
                    }
                    
                    if identifiers.count > 0 {
                        let deleteFetchRequest = NSFetchRequest<NSFetchRequestResult>.init(entityName: CoreData.Entities.Intros.name)
                        deleteFetchRequest.predicate = NSPredicate(format: "\(CoreData.Entities.Intros.Fields.id) IN %@", identifiers)
                        let deleteBatchRequest = NSBatchDeleteRequest(fetchRequest: deleteFetchRequest)
                        
                        do {
                            try context.execute(deleteBatchRequest)
                        } catch {
                            let nserror = error as NSError
                            print("Unresolved error \(nserror), \(nserror.userInfo)")
                        }
                    }
                }
                
                var coreDataIntros = Set<NSManagedObject>()
                for intro in intros {
                    let coreDataIntro = self.createIntroManagedObject(fromModel: intro, inContext: context, entity: introsEntity)
                    self.configure(coreDataIntro: coreDataIntro, withModel: intro)
                    coreDataIntros.insert(coreDataIntro)
                }
                
                coreDataCourse.setValue(coreDataIntros, forKeyPath: CoreData.Entities.Courses.Relations.intros)
                
                self.coreDataSave(context: context)
                
                self.writerContext.perform {
                    self.coreDataSave(context: self.writerContext)
                }
            }
        }
    }
    
    /// Appends course session if such course exists.
    ///
    /// - parameter courseID: Course server ID.
    /// - parameter session: Course session.
    ///
    func appendCourseSessionIfExists(withCourseID courseID: String, session: CourseSessionModel) {
        let context = NSManagedObjectContext.init(concurrencyType: .privateQueueConcurrencyType)
        context.parent = self.writerContext
        
        context.perform {
            guard let _ = NSEntityDescription.entity(forEntityName: CoreData.Entities.Courses.name, in: context), let sessionsEntity = NSEntityDescription.entity(forEntityName: CoreData.Entities.Sessions.name, in: context), let _ = NSEntityDescription.entity(forEntityName: CoreData.Entities.Attachments.name, in: context) else {
                return
            }
            
            let fetchRequest = NSFetchRequest<NSManagedObject>.init(entityName: CoreData.Entities.Courses.name)
            fetchRequest.predicate = NSPredicate(format: "\(CoreData.Entities.Courses.Fields.id) = %@", courseID)
            fetchRequest.fetchLimit = 1
            
            let fetchRequestResult = try? context.fetch(fetchRequest)
            if let coreDataCourse = fetchRequestResult?.first {
                let coreDataSession = self.createSessionManagedObject(fromModel: session, inContext: context, entity: sessionsEntity)
                self.configure(coreDataSession: coreDataSession, withModel: session)
                
                if var coreDataSessions = coreDataCourse.value(forKey: CoreData.Entities.Courses.Relations.sessions) as? Set<NSManagedObject> {
                    coreDataSessions.insert(coreDataSession)
                    coreDataCourse.setValue(coreDataSessions, forKeyPath: CoreData.Entities.Courses.Relations.sessions)
                } else {
                    var coreDataSessions = Set<NSManagedObject>()
                    coreDataSessions.insert(coreDataSession)
                    coreDataCourse.setValue(coreDataSessions, forKeyPath: CoreData.Entities.Courses.Relations.sessions)
                }
                
                self.coreDataSave(context: context)
                
                self.writerContext.perform {
                    self.coreDataSave(context: self.writerContext)
                }
            }
        }
    }
    
    /// Updates course sessions if such course exists.
    ///
    /// - parameter session: Course sessions.
    ///
    func updateCourseSessionIfExists(withSession session: CourseSessionModel) {
        let context = NSManagedObjectContext.init(concurrencyType: .privateQueueConcurrencyType)
        context.parent = self.writerContext
        
        context.perform {
            guard let _ = NSEntityDescription.entity(forEntityName: CoreData.Entities.Courses.name, in: context), let _ = NSEntityDescription.entity(forEntityName: CoreData.Entities.Sessions.name, in: context), let _ = NSEntityDescription.entity(forEntityName: CoreData.Entities.Attachments.name, in: context) else {
                return
            }
            
            let fetchRequest = NSFetchRequest<NSManagedObject>.init(entityName: CoreData.Entities.Sessions.name)
            fetchRequest.predicate = NSPredicate(format: "\(CoreData.Entities.Sessions.Fields.id) = %@", session.id!)
            fetchRequest.fetchLimit = 1
            
            let fetchRequestResult = try? context.fetch(fetchRequest)
            if let coreDataSession = fetchRequestResult?.first {
                self.configure(coreDataSession: coreDataSession, withModel: session)
                
                self.coreDataSave(context: context)
                
                self.writerContext.perform {
                    self.coreDataSave(context: self.writerContext)
                }
            }
        }
    }
    
    /// Saves course sessions if such course exists.
    ///
    /// - parameter courseID: Course server ID.
    /// - parameter sessions: Array of course sessions.
    ///
    func saveCourseSessionsIfExists(withCourseID courseID: String, sessions: [CourseSessionModel]) {
        let context = NSManagedObjectContext.init(concurrencyType: .privateQueueConcurrencyType)
        context.parent = self.writerContext
        
        context.perform {
            guard let _ = NSEntityDescription.entity(forEntityName: CoreData.Entities.Courses.name, in: context), let sessionsEntity = NSEntityDescription.entity(forEntityName: CoreData.Entities.Sessions.name, in: context), let _ = NSEntityDescription.entity(forEntityName: CoreData.Entities.Attachments.name, in: context) else {
                return
            }
            
            let fetchRequest = NSFetchRequest<NSManagedObject>.init(entityName: CoreData.Entities.Courses.name)
            fetchRequest.predicate = NSPredicate(format: "\(CoreData.Entities.Courses.Fields.id) = %@", courseID)
            fetchRequest.fetchLimit = 1
            
            let fetchRequestResult = try? context.fetch(fetchRequest)
            if let coreDataCourse = fetchRequestResult?.first {
                if let coreDataSessions = coreDataCourse.value(forKey: CoreData.Entities.Courses.Relations.sessions) as? Set<NSManagedObject> {
                    var identifiers: [String] = []
                    for coreDataSession in coreDataSessions {
                        let identifier = coreDataSession.value(forKey: CoreData.Entities.Sessions.Fields.id) as! String
                        identifiers.append(identifier)
                    }
                    
                    if identifiers.count > 0 {
                        let deleteFetchRequest = NSFetchRequest<NSFetchRequestResult>.init(entityName: CoreData.Entities.Sessions.name)
                        deleteFetchRequest.predicate = NSPredicate(format: "\(CoreData.Entities.Sessions.Fields.id) IN %@", identifiers)
                        let deleteBatchRequest = NSBatchDeleteRequest(fetchRequest: deleteFetchRequest)
                        
                        do {
                            try context.execute(deleteBatchRequest)
                        } catch {
                            let nserror = error as NSError
                            print("Unresolved error \(nserror), \(nserror.userInfo)")
                        }
                    }
                }
                
                var coreDataSessions = Set<NSManagedObject>()
                for session in sessions {
                    let coreDataSession = self.createSessionManagedObject(fromModel: session, inContext: context, entity: sessionsEntity)
                    self.configure(coreDataSession: coreDataSession, withModel: session)
                    coreDataSessions.insert(coreDataSession)
                }
                
                coreDataCourse.setValue(coreDataSessions, forKeyPath: CoreData.Entities.Courses.Relations.sessions)
                
                self.coreDataSave(context: context)
                
                self.writerContext.perform {
                    self.coreDataSave(context: self.writerContext)
                }
            }
        }
    }
    
    /// Saves course info if such course exists.
    ///
    /// - parameter course: Course model.
    ///
    func saveCourseIfExists(withModel course: CourseModel) {
        let context = NSManagedObjectContext.init(concurrencyType: .privateQueueConcurrencyType)
        context.parent = self.writerContext
        
        context.perform {
            guard let _ = NSEntityDescription.entity(forEntityName: CoreData.Entities.Courses.name, in: context), let sessionsEntity = NSEntityDescription.entity(forEntityName: CoreData.Entities.Sessions.name, in: context), let attachmentsEntity = NSEntityDescription.entity(forEntityName: CoreData.Entities.Attachments.name, in: context), let introsEntity = NSEntityDescription.entity(forEntityName: CoreData.Entities.Intros.name, in: context) else {
                return
            }
            
            let fetchRequest = NSFetchRequest<NSManagedObject>.init(entityName: CoreData.Entities.Courses.name)
            fetchRequest.predicate = NSPredicate(format: "\(CoreData.Entities.Courses.Fields.id) = %@", course.id)
            fetchRequest.fetchLimit = 1
            
            let fetchRequestResult = try? context.fetch(fetchRequest)
            if let coreDataCourse = fetchRequestResult?.first {
                let savedUpdatedTimestamp = coreDataCourse.value(forKey: CoreData.Entities.Courses.Fields.updatedTimestamp) as! Int64
                let savedCoreDataSessions = coreDataCourse.value(forKey: CoreData.Entities.Courses.Relations.sessions) as? Set<NSManagedObject>
                let savedCoreDataAttachments = coreDataCourse.value(forKey: CoreData.Entities.Courses.Relations.attachments) as? Set<NSManagedObject>
                let savedCoreDataIntros = coreDataCourse.value(forKey: CoreData.Entities.Courses.Relations.intros) as? Set<NSManagedObject>
                
                let rewriteValues = (savedUpdatedTimestamp < course.updatedTimestamp) || (savedCoreDataSessions?.count != course.sessions.count) || (savedCoreDataAttachments?.count != course.attachments.count) || (savedCoreDataIntros?.count != course.intros.count)
                
                var coreDataSessions = Set<NSManagedObject>()
                if rewriteValues {
                    for session in course.sessions {
                        let coreDataSession = self.createSessionManagedObject(fromModel: session, inContext: context, entity: sessionsEntity)
                        self.configure(coreDataSession: coreDataSession, withModel: session)
                        coreDataSessions.insert(coreDataSession)
                    }
                }
                
                var coreDataAttachments = Set<NSManagedObject>()
                if rewriteValues {
                    for attachment in course.attachments {
                        let coreDataAttachment = self.createAttachmentManagedObject(fromModel: attachment, inContext: context, entity: attachmentsEntity)
                        self.configure(coreDataAttachment: coreDataAttachment, withModel: attachment)
                        coreDataAttachments.insert(coreDataAttachment)
                    }
                }
                
                var coreDataIntros = Set<NSManagedObject>()
                if rewriteValues {
                    for intro in course.intros {
                        let coreDataIntro = self.createIntroManagedObject(fromModel: intro, inContext: context, entity: introsEntity)
                        self.configure(coreDataIntro: coreDataIntro, withModel: intro)
                        coreDataIntros.insert(coreDataIntro)
                    }
                }
                
                self.configure(coreDataCourse: coreDataCourse, withModel: course, coreDataSessions: coreDataSessions, coreDataAttachments: coreDataAttachments, coreDataIntros: coreDataIntros, rewriteValues: rewriteValues)
                
                self.coreDataSave(context: context)
                
                self.writerContext.perform {
                    self.coreDataSave(context: self.writerContext)
                }
            }
        }
    }
    
    /// Deletes course info if such course exists.
    ///
    /// - parameter course: Course model.
    ///
    func deleteCourseIfExists(withModel course: CourseModel) {
        let context = NSManagedObjectContext.init(concurrencyType: .privateQueueConcurrencyType)
        context.parent = self.writerContext
        
        context.perform {
            let deleteFetchRequest = NSFetchRequest<NSFetchRequestResult>.init(entityName: CoreData.Entities.Courses.name)
            deleteFetchRequest.predicate = NSPredicate(format: "\(CoreData.Entities.Courses.Fields.id) = %@", course.id)
            let deleteBatchRequest = NSBatchDeleteRequest(fetchRequest: deleteFetchRequest)
            
            do {
                try context.execute(deleteBatchRequest)
            } catch {
                let nserror = error as NSError
                print("Unresolved error \(nserror), \(nserror.userInfo)")
            }
            
            self.coreDataSave(context: context)
            
            self.writerContext.perform {
                self.coreDataSave(context: self.writerContext)
            }
        }
    }
    
    /// Deletes session info if such course exists.
    ///
    /// - parameter course: Course model.
    ///
    func deleteSessionIfExists(withModel session: CourseSessionModel) {
        guard let sessionID = session.id else {
            return
        }
        
        let context = NSManagedObjectContext.init(concurrencyType: .privateQueueConcurrencyType)
        context.parent = self.writerContext
        
        context.perform {
            let deleteFetchRequest = NSFetchRequest<NSFetchRequestResult>.init(entityName: CoreData.Entities.Sessions.name)
            deleteFetchRequest.predicate = NSPredicate(format: "\(CoreData.Entities.Sessions.Fields.id) = %@", sessionID)
            let deleteBatchRequest = NSBatchDeleteRequest(fetchRequest: deleteFetchRequest)
            
            do {
                try context.execute(deleteBatchRequest)
            } catch {
                let nserror = error as NSError
                print("Unresolved error \(nserror), \(nserror.userInfo)")
            }
            
            self.coreDataSave(context: context)
            
            self.writerContext.perform {
                self.coreDataSave(context: self.writerContext)
            }
        }
    }
    
    /// Saves courses.
    ///
    /// - parameter courses: Array of CourseModel objects.
    /// - parameter completion: Completion block. Calls after saving completed.
    ///
    func saveCourses(withModels courses: [CourseModel], completion: (() -> ())?) {
        let context = NSManagedObjectContext.init(concurrencyType: .privateQueueConcurrencyType)
        context.parent = self.writerContext
        
        context.perform {
            guard let coursesEntity = NSEntityDescription.entity(forEntityName: CoreData.Entities.Courses.name, in: context), let sessionsEntity = NSEntityDescription.entity(forEntityName: CoreData.Entities.Sessions.name, in: context), let attachmentsEntity = NSEntityDescription.entity(forEntityName: CoreData.Entities.Attachments.name, in: context), let introsEntity = NSEntityDescription.entity(forEntityName: CoreData.Entities.Intros.name, in: context) else {
                return
            }
            
            for course in courses {
                let coreDataCourse = self.createCourseManagedObject(fromModel: course, inContext: context, entity: coursesEntity)
                let savedUpdatedTimestamp = coreDataCourse.value(forKey: CoreData.Entities.Courses.Fields.updatedTimestamp) as! Int64
                let savedCoreDataSessions = coreDataCourse.value(forKey: CoreData.Entities.Courses.Relations.sessions) as? Set<NSManagedObject>
                let savedCoreDataAttachments = coreDataCourse.value(forKey: CoreData.Entities.Courses.Relations.attachments) as? Set<NSManagedObject>
                let savedCoreDataIntros = coreDataCourse.value(forKey: CoreData.Entities.Courses.Relations.intros) as? Set<NSManagedObject>
                
                let rewriteValues = (savedUpdatedTimestamp < course.updatedTimestamp) || (savedCoreDataSessions?.count != course.sessions.count) || (savedCoreDataAttachments?.count != course.attachments.count) || (savedCoreDataIntros?.count != course.intros.count)
                
                var coreDataSessions = Set<NSManagedObject>()
                if rewriteValues {
                    for session in course.sessions {
                        let coreDataSession = self.createSessionManagedObject(fromModel: session, inContext: context, entity: sessionsEntity)
                        self.configure(coreDataSession: coreDataSession, withModel: session)
                        coreDataSessions.insert(coreDataSession)
                    }
                }
                
                var coreDataAttachments = Set<NSManagedObject>()
                if rewriteValues {
                    for attachment in course.attachments {
                        let coreDataAttachment = self.createAttachmentManagedObject(fromModel: attachment, inContext: context, entity: attachmentsEntity)
                        self.configure(coreDataAttachment: coreDataAttachment, withModel: attachment)
                        coreDataAttachments.insert(coreDataAttachment)
                    }
                }
                
                var coreDataIntros = Set<NSManagedObject>()
                if rewriteValues {
                    for intro in course.intros {
                        let coreDataIntro = self.createIntroManagedObject(fromModel: intro, inContext: context, entity: introsEntity)
                        self.configure(coreDataIntro: coreDataIntro, withModel: intro)
                        coreDataIntros.insert(coreDataIntro)
                    }
                }
                
                self.configure(coreDataCourse: coreDataCourse, withModel: course, coreDataSessions: coreDataSessions, coreDataAttachments: coreDataAttachments, coreDataIntros: coreDataIntros, rewriteValues: rewriteValues)
            }
            
            self.coreDataSave(context: context)
            
            self.writerContext.perform {
                self.coreDataSave(context: self.writerContext)
                completion?()
            }
        }
    }
    
    // MARK: Private Methods
    
    // MARK: Core Data Stack
    
    private func setupCoreDataStack() {
        self.writerContext = NSManagedObjectContext.init(concurrencyType: .privateQueueConcurrencyType)
        
        let persistentContainer = NSPersistentContainer(name: CoreData.name)
        persistentContainer.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        self.writerContext.persistentStoreCoordinator = persistentContainer.persistentStoreCoordinator
    }
    
    // MARK: Core Data Methods
    
    private func createCourseManagedObject(fromModel course: CourseModel, inContext context: NSManagedObjectContext, entity: NSEntityDescription) -> NSManagedObject {
        let fetchRequest = NSFetchRequest<NSManagedObject>.init(entityName: CoreData.Entities.Courses.name)
        fetchRequest.predicate = NSPredicate(format: "\(CoreData.Entities.Courses.Fields.id) = %@", course.id)
        fetchRequest.fetchLimit = 1
        
        let fetchRequestResult = try? context.fetch(fetchRequest)
        if let courseFetchedModel = fetchRequestResult?.first {
            return courseFetchedModel
        } else {
            let coreDataCourse = NSManagedObject(entity: entity, insertInto: context)
            return coreDataCourse
        }
    }
    
    private func createSessionManagedObject(fromModel session: CourseSessionModel, inContext context: NSManagedObjectContext, entity: NSEntityDescription) -> NSManagedObject {
        let fetchRequest = NSFetchRequest<NSManagedObject>.init(entityName: CoreData.Entities.Sessions.name)
        fetchRequest.predicate = NSPredicate(format: "\(CoreData.Entities.Sessions.Fields.id) = %@", session.id!)
        fetchRequest.fetchLimit = 1
        
        let sessionFetchRequestResult = try? context.fetch(fetchRequest)
        if let sessionFetchedModel = sessionFetchRequestResult?.first {
            return sessionFetchedModel
        } else {
            let coreDataSession = NSManagedObject(entity: entity, insertInto: context)
            return coreDataSession
        }
    }
    
    private func createAttachmentManagedObject(fromModel attachment: CourseAttachmentModel, inContext context: NSManagedObjectContext, entity: NSEntityDescription) -> NSManagedObject {
        let fetchRequest = NSFetchRequest<NSManagedObject>.init(entityName: CoreData.Entities.Attachments.name)
        fetchRequest.predicate = NSPredicate(format: "\(CoreData.Entities.Attachments.Fields.id) = %@", attachment.id!)
        fetchRequest.fetchLimit = 1
        
        let attachmentFetchRequestResult = try? context.fetch(fetchRequest)
        if let attachmentFetchedModel = attachmentFetchRequestResult?.first {
            return attachmentFetchedModel
        } else {
            let coreDataAttachment = NSManagedObject(entity: entity, insertInto: context)
            return coreDataAttachment
        }
    }
    
    private func createIntroManagedObject(fromModel intro: CourseIntroModel, inContext context: NSManagedObjectContext, entity: NSEntityDescription) -> NSManagedObject {
        let fetchRequest = NSFetchRequest<NSManagedObject>.init(entityName: CoreData.Entities.Intros.name)
        fetchRequest.predicate = NSPredicate(format: "\(CoreData.Entities.Intros.Fields.id) = %@", intro.id!)
        fetchRequest.fetchLimit = 1
        
        let introFetchRequestResult = try? context.fetch(fetchRequest)
        if let introFetchedModel = introFetchRequestResult?.first {
            return introFetchedModel
        } else {
            let coreDataIntro = NSManagedObject(entity: entity, insertInto: context)
            return coreDataIntro
        }
    }
    
    private func configure(coreDataCourse: NSManagedObject, withModel model: CourseModel, coreDataSessions: Set<NSManagedObject>, coreDataAttachments: Set<NSManagedObject>, coreDataIntros: Set<NSManagedObject>, rewriteValues: Bool) {
        if rewriteValues {
            coreDataCourse.setValue(model.id, forKeyPath: CoreData.Entities.Courses.Fields.id)
            coreDataCourse.setValue(model.creatorID, forKeyPath: CoreData.Entities.Courses.Fields.creatorID)
            coreDataCourse.setValue(model.creatorName, forKey: CoreData.Entities.Courses.Fields.creatorName)
            coreDataCourse.setValue(model.title, forKeyPath: CoreData.Entities.Courses.Fields.title)
            coreDataCourse.setValue(model.specification, forKeyPath: CoreData.Entities.Courses.Fields.specification)
            coreDataCourse.setValue(model.price?.stringValue, forKeyPath: CoreData.Entities.Courses.Fields.price)
            coreDataCourse.setValue(model.priceTier, forKeyPath: CoreData.Entities.Courses.Fields.priceTier)
            coreDataCourse.setValue(model.state, forKeyPath: CoreData.Entities.Courses.Fields.state)
            coreDataCourse.setValue(model.earnings?.stringValue, forKeyPath: CoreData.Entities.Courses.Fields.earnings)
            coreDataCourse.setValue(model.updatedTimestamp, forKeyPath: CoreData.Entities.Courses.Fields.updatedTimestamp)
            coreDataCourse.setValue(model.createdTimestamp, forKeyPath: CoreData.Entities.Courses.Fields.createdTimestamp)
            coreDataCourse.setValue(model.nearestSessionTimestamp, forKeyPath: CoreData.Entities.Courses.Fields.nearestSessionTimestamp)
            coreDataCourse.setValue(model.webPage, forKey: CoreData.Entities.Courses.Fields.webPage)
            coreDataCourse.setValue(model.subscribed, forKey: CoreData.Entities.Courses.Fields.subscribed)
            coreDataCourse.setValue(model.previewImageURL, forKey: CoreData.Entities.Courses.Fields.previewImageURL)
            coreDataCourse.setValue(model.imageSharingURL, forKey: CoreData.Entities.Courses.Fields.imageSharingURL)
            
            coreDataCourse.setValue(coreDataSessions, forKeyPath: CoreData.Entities.Courses.Relations.sessions)
            coreDataCourse.setValue(coreDataAttachments, forKeyPath: CoreData.Entities.Courses.Relations.attachments)
            coreDataCourse.setValue(coreDataIntros, forKeyPath: CoreData.Entities.Courses.Relations.intros)
        } else {
            if model.earnings != nil {
                coreDataCourse.setValue(model.earnings?.stringValue, forKeyPath: CoreData.Entities.Courses.Fields.earnings)
            }
            
            if model.creatorID != nil {
                coreDataCourse.setValue(model.creatorID, forKeyPath: CoreData.Entities.Courses.Fields.creatorID)
            }
            
            coreDataCourse.setValue(model.price?.stringValue, forKeyPath: CoreData.Entities.Courses.Fields.price)
            coreDataCourse.setValue(model.priceTier, forKeyPath: CoreData.Entities.Courses.Fields.priceTier)
            coreDataCourse.setValue(model.webPage, forKey: CoreData.Entities.Courses.Fields.webPage)
            coreDataCourse.setValue(model.nearestSessionTimestamp, forKeyPath: CoreData.Entities.Courses.Fields.nearestSessionTimestamp)
            coreDataCourse.setValue(model.state, forKeyPath: CoreData.Entities.Courses.Fields.state)
            coreDataCourse.setValue(model.subscribed, forKey: CoreData.Entities.Courses.Fields.subscribed)
            coreDataCourse.setValue(model.previewImageURL, forKey: CoreData.Entities.Courses.Fields.previewImageURL)
            coreDataCourse.setValue(model.imageSharingURL, forKey: CoreData.Entities.Courses.Fields.imageSharingURL)
        }
    }
    
    private func configure(coreDataSession: NSManagedObject, withModel model: CourseSessionModel) {
        coreDataSession.setValue(model.id, forKeyPath: CoreData.Entities.Sessions.Fields.id)
        coreDataSession.setValue(model.title, forKeyPath: CoreData.Entities.Sessions.Fields.title)
        coreDataSession.setValue(model.specification, forKeyPath: CoreData.Entities.Sessions.Fields.specification)
        coreDataSession.setValue(model.duration, forKeyPath: CoreData.Entities.Sessions.Fields.duration)
        coreDataSession.setValue(model.startTimestamp, forKeyPath: CoreData.Entities.Sessions.Fields.startTimestamp)
        coreDataSession.setValue(model.updatedTimestamp, forKeyPath: CoreData.Entities.Sessions.Fields.updatedTimestamp)
    }
    
    private func configure(coreDataAttachment: NSManagedObject, withModel model: CourseAttachmentModel) {
        coreDataAttachment.setValue(model.id, forKeyPath: CoreData.Entities.Attachments.Fields.id)
        coreDataAttachment.setValue(model.type.rawValue, forKeyPath: CoreData.Entities.Attachments.Fields.type)
        coreDataAttachment.setValue(model.fileAddress, forKeyPath: CoreData.Entities.Attachments.Fields.fileAddress)
        coreDataAttachment.setValue(model.thumbnailAddress, forKeyPath: CoreData.Entities.Attachments.Fields.thumbnailAddress)
        coreDataAttachment.setValue(model.filePath, forKeyPath: CoreData.Entities.Attachments.Fields.filePath)
        coreDataAttachment.setValue(model.createdTimestamp, forKeyPath: CoreData.Entities.Attachments.Fields.createdTimestamp)
    }
    
    private func configure(coreDataIntro: NSManagedObject, withModel model: CourseIntroModel) {
        coreDataIntro.setValue(model.id, forKeyPath: CoreData.Entities.Intros.Fields.id)
        coreDataIntro.setValue(model.type.rawValue, forKeyPath: CoreData.Entities.Intros.Fields.type)
        coreDataIntro.setValue(model.fileAddress, forKeyPath: CoreData.Entities.Intros.Fields.fileAddress)
        coreDataIntro.setValue(model.thumbnailAddress, forKeyPath: CoreData.Entities.Intros.Fields.thumbnailAddress)
        coreDataIntro.setValue(model.order, forKeyPath: CoreData.Entities.Intros.Fields.order)
    }
    
    private func courseModel(fromManagedObject coreDataCourse: NSManagedObject) -> CourseModel {
        let id = coreDataCourse.value(forKey: CoreData.Entities.Courses.Fields.id) as! String
        let creatorID = coreDataCourse.value(forKey: CoreData.Entities.Courses.Fields.creatorID) as? String
        let creatorName = coreDataCourse.value(forKey: CoreData.Entities.Courses.Fields.creatorName) as! String
        let title = coreDataCourse.value(forKey: CoreData.Entities.Courses.Fields.title) as! String
        let specification = coreDataCourse.value(forKey: CoreData.Entities.Courses.Fields.specification) as! String
        let priceString = coreDataCourse.value(forKey: CoreData.Entities.Courses.Fields.price) as? String
        let priceTier = coreDataCourse.value(forKey: CoreData.Entities.Courses.Fields.priceTier) as? String
        let state = coreDataCourse.value(forKey: CoreData.Entities.Courses.Fields.state) as? Int
        let earningsString = coreDataCourse.value(forKey: CoreData.Entities.Courses.Fields.earnings) as? String
        let updatedTimestamp = coreDataCourse.value(forKey: CoreData.Entities.Courses.Fields.updatedTimestamp) as! Int64
        let createdTimestamp = coreDataCourse.value(forKey: CoreData.Entities.Courses.Fields.createdTimestamp) as! Int64
        let nearestSessionTimestamp = coreDataCourse.value(forKey: CoreData.Entities.Courses.Fields.nearestSessionTimestamp) as? Int64
        let webPage = coreDataCourse.value(forKey: CoreData.Entities.Courses.Fields.webPage) as? String
        let subscribed = (coreDataCourse.value(forKey: CoreData.Entities.Courses.Fields.subscribed) as? Bool) ?? false
        let previewImageURL = coreDataCourse.value(forKey: CoreData.Entities.Courses.Fields.previewImageURL) as? String
        let courseImageSharingUrl = coreDataCourse.value(forKey: CoreData.Entities.Courses.Fields.imageSharingURL) as? String
        let subscribersCount = coreDataCourse.value(forKey: CoreData.Entities.Courses.Fields.subscribersCount) as? Int
        
        var sessions: [CourseSessionModel] = []
        if let coreDataSessions = coreDataCourse.value(forKey: CoreData.Entities.Courses.Relations.sessions) as? Set<NSManagedObject> {
            for coreDataSession in coreDataSessions {
                let id = coreDataSession.value(forKey: CoreData.Entities.Sessions.Fields.id) as! String
                let title = coreDataSession.value(forKey: CoreData.Entities.Sessions.Fields.title) as! String
                let specification = coreDataSession.value(forKey: CoreData.Entities.Sessions.Fields.specification) as! String
                let duration = coreDataSession.value(forKey: CoreData.Entities.Sessions.Fields.duration) as! Int
                let startTimestamp = coreDataSession.value(forKey: CoreData.Entities.Sessions.Fields.startTimestamp) as! Int64
                let updatedTimestamp = coreDataSession.value(forKey: CoreData.Entities.Sessions.Fields.updatedTimestamp) as? Int64
                
                let session = CourseSessionModel(withID: id, identifier: nil, title: title, specification: specification, startTimestamp: startTimestamp, updatedTimestamp: updatedTimestamp, duration: duration)
                sessions.append(session)
            }
        }
        
        var attachments: [CourseAttachmentModel] = []
        if let coreDataAttachments = coreDataCourse.value(forKey: CoreData.Entities.Courses.Relations.attachments) as? Set<NSManagedObject> {
            for coreDataAttachment in coreDataAttachments {
                let id = coreDataAttachment.value(forKey: CoreData.Entities.Attachments.Fields.id) as! String
                let type = coreDataAttachment.value(forKey: CoreData.Entities.Attachments.Fields.type) as! Int
                let fileAddress = coreDataAttachment.value(forKey: CoreData.Entities.Attachments.Fields.fileAddress) as? String
                let thumbnailAddress = coreDataAttachment.value(forKey: CoreData.Entities.Attachments.Fields.thumbnailAddress) as? String
                let filePath = coreDataAttachment.value(forKey: CoreData.Entities.Attachments.Fields.filePath) as? String
                let createdTimestamp = (coreDataAttachment.value(forKey: CoreData.Entities.Attachments.Fields.createdTimestamp) as? Int64 ?? 0)
                
                let attachment = CourseAttachmentModel(withIdentifier: id, type: type, fileAddress: fileAddress, thumbnailAddress: thumbnailAddress, filePath: filePath, createdTimestamp: createdTimestamp)
                attachments.append(attachment)
            }
        }
        
        var intros: [CourseIntroModel] = []
        if let coreDataIntros = coreDataCourse.value(forKey: CoreData.Entities.Courses.Relations.intros) as? Set<NSManagedObject> {
            for coreDataIntro in coreDataIntros {
                let id = coreDataIntro.value(forKey: CoreData.Entities.Intros.Fields.id) as! String
                let type = coreDataIntro.value(forKey: CoreData.Entities.Intros.Fields.type) as! Int
                let fileAddress = coreDataIntro.value(forKey: CoreData.Entities.Intros.Fields.fileAddress) as? String
                let thumbnailAddress = coreDataIntro.value(forKey: CoreData.Entities.Intros.Fields.thumbnailAddress) as? String
                let order = coreDataIntro.value(forKey: CoreData.Entities.Intros.Fields.order) as! Int
                
                let intro = CourseIntroModel(withIdentifier: id, type: type, fileAddress: fileAddress, thumbnailAddress: thumbnailAddress, order: order)
                intros.append(intro)
            }
        }
        if intros.count > 0 {
            intros.sort(by: { $0.order < $1.order })
        }
        
        let course = CourseModel(withIdentifier: id, creatorID: creatorID, creatorName: creatorName, title: title, specification: specification, priceString: priceString, priceTierString: priceTier, state: state, earningsString: earningsString, sessions: sessions, attachments: attachments, updatedTimestamp: updatedTimestamp, createdTimestamp: createdTimestamp, nearestSessionTimestamp: nearestSessionTimestamp, previewImageURL: previewImageURL, intros: intros, webPage: webPage, subscribed: subscribed, imageSharingURL: courseImageSharingUrl, subscribersCount: subscribersCount ?? 0)
        return course
    }
    
    // MARK: Support Methods
    
    private func coursesSortDescriptors(forListType type: CourseListProperties.CourseListType) -> [NSSortDescriptor] {
        switch type {
        case .all:
            let timestampSortDescriptor = NSSortDescriptor(key: CoreData.Entities.Courses.Fields.nearestSessionTimestamp, ascending: true)
            let identifierSortDescriptor = NSSortDescriptor(key: CoreData.Entities.Courses.Fields.id, ascending: false)
            return [timestampSortDescriptor, identifierSortDescriptor]
        case .subscribed:
            let timestampSortDescriptor = NSSortDescriptor(key: CoreData.Entities.Courses.Fields.nearestSessionTimestamp, ascending: true)
            let identifierSortDescriptor = NSSortDescriptor(key: CoreData.Entities.Courses.Fields.id, ascending: false)
            return [timestampSortDescriptor, identifierSortDescriptor]
        case .own:
            let timestampSortDescriptor = NSSortDescriptor(key: CoreData.Entities.Courses.Fields.createdTimestamp, ascending: false)
            let identifierSortDescriptor = NSSortDescriptor(key: CoreData.Entities.Courses.Fields.id, ascending: false)
            return [timestampSortDescriptor, identifierSortDescriptor]
        case .other:
            let timestampSortDescriptor = NSSortDescriptor(key: CoreData.Entities.Courses.Fields.nearestSessionTimestamp, ascending: true)
            let identifierSortDescriptor = NSSortDescriptor(key: CoreData.Entities.Courses.Fields.id, ascending: false)
            return [timestampSortDescriptor, identifierSortDescriptor]
        }
    }
    
    private func coreDataSave(context: NSManagedObjectContext) {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                print("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
}
