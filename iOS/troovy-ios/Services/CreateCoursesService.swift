//
//  CreateCoursesService.swift
//  troovy-ios
//
//  Created by Daniil on 23.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

struct CreateCoursesNotificationNames {
    static let subscribedSessionsChanged = "troovy_subscribedSessionsChanged"
    static let subscribedSessionFinished = "troovy_subscribedSessionFinished"
}

class CreateCoursesService: TroovyService {
    
    private struct UserDefaultsKeys {
        static let unfinishedCourseModel = "troovy_unfinishedCourseModel"
    }
    
    // MARK: Private Properties
    
    private let networkManager = NetworkManager.shared

    private var bigFileUploadTask: URLSessionTask?
    
    private var bigFileUploadCancelled = false
    private var bigFileUploadPaused = false
    
    private var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    
    // MARK: Public Methods
    
    /// Cancels upload course attachment.
    func cancelUploadCourseResources() {
        if self.bigFileUploadTask != nil {
            self.bigFileUploadTask?.suspend()
            self.bigFileUploadTask?.cancel()
            self.bigFileUploadTask = nil
        } else {
            self.bigFileUploadCancelled = true
        }
    }
    
    /// Pauses upload course attachment.
    func pauseUploadCourseResources() {
        self.backgroundTask = UIApplication.shared.beginBackgroundTask(expirationHandler: { [weak self] in
            self?.stopBackgroundTask()
        })
        
        self.bigFileUploadPaused = true
        self.bigFileUploadTask?.suspend()
    }
    
    /// Resumes upload course attachment.
    func resumeUploadCourseResources() {
        self.bigFileUploadPaused = false
        self.bigFileUploadTask?.resume()
        
        self.stopBackgroundTask()
    }
    
    /// Deletes course.
    ///
    /// - parameter courseID: Course server ID.
    /// - parameter ignoreSubscribers: Determines if subscribers should be ignored.
    /// - parameter user: Authorised user model.
    /// - returns: Method name.
    ///
    func deleteCourse(withCourseID courseID: String, ignoreSubscribers: Bool, user: AuthorisedUserModel?) -> String? {
        let method = "deleteCourse"
        self.serviceResultChanged(withResult: ServiceActionResult.methodStarted(method: method))
        
        self.networkManager.deleteCourse(withNetworkToken: user?.networkToken, courseID: courseID, ignoreSubscribers: ignoreSubscribers) { (response, errorMessage, isCancelled) -> (Void) in
            if let responseDictionary = response as? [String:Any] {
                self.serviceResultChanged(withResult: ServiceActionResult.methodSucceededWithResponseDictionary(method: method, resultDictionary: responseDictionary))
            } else {
                self.serviceResultChanged(withResult: ServiceActionResult.methodFailed(method: method, error: errorMessage))
            }
        }
        
        return method
    }
    
    /// Deletes course intro.
    ///
    /// - parameter introID: Course intro server ID.
    /// - parameter user: Authorised user model.
    /// - returns: Method name.
    ///
    func deleteCourseIntro(withIntroID introID: String, user: AuthorisedUserModel?) -> String? {
        let method = "deleteCourseIntro"
        self.serviceResultChanged(withResult: ServiceActionResult.methodStarted(method: method))
        
        self.networkManager.deleteCourseIntro(withNetworkToken: user?.networkToken, introID: introID) { (response, errorMessage, isCancelled) -> (Void) in
            if (response as? [String:Any]) != nil {
                self.serviceResultChanged(withResult: ServiceActionResult.methodSucceeded(method: method))
            } else {
                self.serviceResultChanged(withResult: ServiceActionResult.methodFailed(method: method, error: errorMessage))
            }
        }
        
        return method
    }
    
    /// Deletes course esssion.
    ///
    /// - parameter sessionID: Course server ID.
    /// - parameter user: Authorised user model.
    /// - returns: Method name.
    ///
    func deleteSession(withSessionID sessionID: String, user: AuthorisedUserModel?) -> String? {
        let method = "deleteSession"
        self.serviceResultChanged(withResult: ServiceActionResult.methodStarted(method: method))
        
        self.networkManager.deleteSession(withNetworkToken: user?.networkToken, sessionID: sessionID) { (response, errorMessage, isCancelled) -> (Void) in
            if response != nil {
                self.serviceResultChanged(withResult: ServiceActionResult.methodSucceeded(method: method))
            } else {
                self.serviceResultChanged(withResult: ServiceActionResult.methodFailed(method: method, error: errorMessage))
            }
        }
        
        return method
    }
    
    /// Reports course.
    ///
    /// - parameter courseID: Course server ID.
    /// - parameter reason: Report reason.
    /// - parameter user: Authorised user model.
    /// - returns: Method name.
    ///
    func reportCourse(withCourseID courseID: String, reason: String, user: AuthorisedUserModel?) -> String? {
        let method = "reportCourse"
        self.serviceResultChanged(withResult: ServiceActionResult.methodStarted(method: method))
        
        self.networkManager.reportCourse(withNetworkToken: user?.networkToken, courseID: courseID, reason: reason) { (response, errorMessage, isCancelled) -> (Void) in
            if response != nil {
                self.serviceResultChanged(withResult: ServiceActionResult.methodSucceeded(method: method))
            } else {
                self.serviceResultChanged(withResult: ServiceActionResult.methodFailed(method: method, error: errorMessage))
            }
        }
        
        return method
    }
    
    /// Creates attachment.
    ///
    /// - parameter courseID: Course server ID.
    /// - parameter user: Authorised user model.
    /// - returns: Method name.
    ///
    func createCourseVideoAttachment(withCourseID courseID: String, user: AuthorisedUserModel?) -> String {
        let method = "createCourseAttachment"
        self.serviceResultChanged(withResult: ServiceActionResult.methodStarted(method: method))
        
        self.networkManager.createCourseAttachment(withNetworkToken: user?.networkToken, courseID: courseID, attachmentType: CourseAttachmentType.video.rawValue) { (response, errorMessage, isCancelled) -> (Void) in
            if let result = response as? [String:Any] {
                self.serviceResultChanged(withResult: ServiceActionResult.methodSucceededWithResponseDictionary(method: method, resultDictionary: result))
            } else {
                self.serviceResultChanged(withResult: ServiceActionResult.methodFailed(method: method, error: errorMessage))
            }
        }
        
        return method
    }
    
    /// Uploads file for existed attachment.
    ///
    /// - parameter model: Course attachment model, kind of CourseAttachmentModel.
    /// - parameter user: Authorised user model.
    /// - returns: Method name.
    ///
    func uploadCourseAttachment(withModel model: CourseAttachmentModel, user: AuthorisedUserModel?) -> String {
        self.bigFileUploadCancelled = false
        self.bigFileUploadPaused = false
        
        let method = "uploadCourseAttachment"
        self.serviceResultChanged(withResult: ServiceActionResult.methodStarted(method: method))
        
        self.networkManager.createAttachmentVideo(withNetworkToken: user?.networkToken, attachmentID: model.id, filePath: model.filePath!, encodeFinished: { (sessionTask) in
            self.uploadTaskEncoded(sessionTask)
        }, progress: { (value) in
            self.serviceResultChanged(withResult: ServiceActionResult.methodProgressedWithProgress(method: method, progress: value))
        }) { (response, errorMessage, isCancelled) -> (Void) in
            if isCancelled {
                self.serviceResultChanged(withResult: ServiceActionResult.methodCancelled(method: method))
            } else if let result = response as? [String:Any] {
                self.serviceResultChanged(withResult: ServiceActionResult.methodSucceededWithResponseDictionary(method: method, resultDictionary: result))
            } else {
                self.serviceResultChanged(withResult: ServiceActionResult.methodFailed(method: method, error: errorMessage))
            }
        }
        
        return method
    }
    
    /// Creates course image intro.
    ///
    /// - parameter courseID: Course server ID.
    /// - parameter introOrder: Course intro order.
    /// - parameter user: Authorised user model.
    /// - returns: Method name.
    ///
    func createCourseImageIntro(orCourseID courseID: String, introOrder: Int, user: AuthorisedUserModel?) -> String {
        return self.createCourseIntro(orCourseID: courseID, introOrder: introOrder, introType: CourseIntroType.image.rawValue, user: user)
    }
    
    /// Creates course video intro.
    ///
    /// - parameter courseID: Course server ID.
    /// - parameter introOrder: Course intro order.
    /// - parameter user: Authorised user model.
    /// - returns: Method name.
    ///
    func createCourseVideoIntro(orCourseID courseID: String, introOrder: Int, user: AuthorisedUserModel?) -> String {
        return self.createCourseIntro(orCourseID: courseID, introOrder: introOrder, introType: CourseIntroType.video.rawValue, user: user)
    }
    
    /// Uploads course intro by chunks.
    ///
    /// - parameter filePath: Course intro file path.
    /// - parameter introID: Course intro server ID.
    /// - parameter introType: Course intro server type.
    /// - parameter user: Authorised user model.
    /// - returns: Method name.
    ///
    func uploadCourseIntro(withFilePath filePath: String, introID: String, introType: Int, user: AuthorisedUserModel?) -> String {
        self.bigFileUploadCancelled = false
        self.bigFileUploadPaused = false
        
        let method = "uploadCourseIntro"
        self.serviceResultChanged(withResult: ServiceActionResult.methodStarted(method: method))
        
        self.networkManager.uploadCourseIntro(withNetworkToken: user?.networkToken, introID: introID, introType: introType, filePath: filePath, encodeFinished: { (sessionTask) in
            self.uploadTaskEncoded(sessionTask)
        }, progress: { (value) in
            self.serviceResultChanged(withResult: ServiceActionResult.methodProgressedWithProgress(method: method, progress: value))
        }) { (response, errorMessage, isCancelled) -> (Void) in
            if isCancelled {
                self.serviceResultChanged(withResult: ServiceActionResult.methodCancelled(method: method))
            } else if let result = response as? [String:Any] {
                self.serviceResultChanged(withResult: ServiceActionResult.methodSucceededWithResponseDictionary(method: method, resultDictionary: result))
            } else {
                self.serviceResultChanged(withResult: ServiceActionResult.methodFailed(method: method, error: errorMessage))
            }
        }
        
        return method
    }
    
    /// Creates course session for existed course.
    ///
    /// - parameter model: Course session model, kind of CourseSessionModel.
    /// - parameter courseID: Course server ID.
    /// - parameter user: Authorised user model.
    /// - returns: Method name.
    ///
    func createCourseSession(withModel model: CourseSessionModel, forCourseID courseID: String, user: AuthorisedUserModel?) -> String {
        let method = "createCourseSession"
        self.serviceResultChanged(withResult: ServiceActionResult.methodStarted(method: method))
        
        self.networkManager.createCourseSession(withNetworkToken: user?.networkToken, title: model.title, description: model.specification, startTimestamp: model.startTimestamp, duration: model.duration, forCourseID: courseID) { (response, errorMessage, isCancelled) -> (Void) in
            if isCancelled {
                return
            } else {
                if let result = response as? [String:Any] {
                    self.serviceResultChanged(withResult: ServiceActionResult.methodSucceededWithResponseDictionary(method: method, resultDictionary: result))
                } else {
                    self.serviceResultChanged(withResult: ServiceActionResult.methodFailed(method: method, error: errorMessage))
                }
            }
        }
        
        return method
    }
    
    /// Edits course session for existed course.
    ///
    /// - parameter model: Course session model, kind of CourseSessionModel.
    /// - parameter courseID: Course server ID.
    /// - parameter user: Authorised user model.
    /// - returns: Method name.
    ///
    func editCourseSession(withSessionID sessionID: String, title: String?, description: String?, startTimestamp: Int64?, duration: Int?, forCourseID courseID: String, user: AuthorisedUserModel?) -> String {
        let method = "editCourseSession"
        self.serviceResultChanged(withResult: ServiceActionResult.methodStarted(method: method))
        
        self.networkManager.editCourseSession(withNetworkToken: user?.networkToken, sessionID: sessionID, title: title, description: description, startTimestamp: startTimestamp, duration: duration, forCourseID: courseID) { (response, errorMessage, isCancelled) -> (Void) in
            if let result = response as? [String:Any] {
                self.serviceResultChanged(withResult: ServiceActionResult.methodSucceededWithResponseDictionary(method: method, resultDictionary: result))
            } else {
                self.serviceResultChanged(withResult: ServiceActionResult.methodFailed(method: method, error: errorMessage))
            }
        }
        
        return method
    }
    
    /// Edits course intros order.
    ///
    /// - parameter courseID: Course server ID.
    /// - parameter order: Pairs of intro id and order.
    /// - parameter user: Authorised user model.
    /// - returns: Method name.
    ///
    func editCourseIntrosOrder(withCourseID courseID: String, order: [[String:Any]], user: AuthorisedUserModel?) -> String {
        let method = "editCourseIntrosOrder"
        self.serviceResultChanged(withResult: ServiceActionResult.methodStarted(method: method))
        
        self.networkManager.editCourseIntrosOrder(withNetworkToken: user?.networkToken, courseID: courseID, order: order) { (response, errorMessage, isCancelled) -> (Void) in
            if let result = response as? [[String:Any]] {
                self.serviceResultChanged(withResult: ServiceActionResult.methodSucceededWithResponseArray(method: method, resultArray: result))
            } else {
                self.serviceResultChanged(withResult: ServiceActionResult.methodFailed(method: method, error: errorMessage))
            }
        }
        
        return method
    }
    
    /// Creates course and publish it if needed.
    ///
    /// - parameter course: Course model, kind of UnfinishedCourseModel.
    /// - parameter user: Authorised user model.
    /// - parameter publish: If true course will be published right after creating.
    /// - returns: Method name.
    ///
    func createCourse(withUnfinishedCourse course: UnfinishedCourseModel, user: AuthorisedUserModel?, andPublish publish: Bool) -> String {
        let method = "createCourse"
        self.serviceResultChanged(withResult: ServiceActionResult.methodStarted(method: method))
        
        var sessionDictionaries: [[String:Any]] = []
        for session in course.sessions {
            let sessionDictionary = session.modelAsDictionary()
            sessionDictionaries.append(sessionDictionary)
        }
        
        self.networkManager.createCourse(withNetworkToken: user?.networkToken, title: course.title!, description: course.description!, previewImage: nil, priceTier: course.priceTier, sessions: sessionDictionaries, publish: publish) { (response, errorMessage, isCancelled) -> (Void) in
            if let result = response as? [String:Any] {
                self.serviceResultChanged(withResult: ServiceActionResult.methodSucceededWithResponseDictionary(method: method, resultDictionary: result))
            } else {
                self.serviceResultChanged(withResult: ServiceActionResult.methodFailed(method: method, error: errorMessage))
            }
        }
        
        return method
    }
    
    /// Edits course.
    ///
    /// - parameter course: Course model, kind of UnfinishedCourseModel.
    /// - parameter courseID: Course server ID.
    /// - parameter user: Authorised user model.
    /// - returns: Method name.
    ///
    func editCourse(withUnfinishedCourse course: UnfinishedCourseModel, forCourseID courseID: String, user: AuthorisedUserModel?) -> String {
        let method = "editCourse"
        self.serviceResultChanged(withResult: ServiceActionResult.methodStarted(method: method))
        
        let deletePreview = false
       
        self.networkManager.editCourse(withNetworkToken: user?.networkToken, courseID: courseID, title: course.title, description: course.description, previewImage: nil, price: course.price?.stringValue, priceTier: course.priceTier, deletePreview: deletePreview) { (response, errorMessage, isCancelled) -> (Void) in
            if let result = response as? [String:Any] {
                self.serviceResultChanged(withResult: ServiceActionResult.methodSucceededWithResponseDictionary(method: method, resultDictionary: result))
            } else {
                self.serviceResultChanged(withResult: ServiceActionResult.methodFailed(method: method, error: errorMessage))
            }
        }
        
        return method
    }
    
    /// Publish course.
    ///
    /// - parameter course: Course model, kind of CourseModel.
    /// - parameter user: Authorised user model.
    /// - returns: Method name.
    ///
    func publishCourse(withCourseModel course: CourseModel, user: AuthorisedUserModel?) -> String {
        let method = "publishCourse"
        self.serviceResultChanged(withResult: ServiceActionResult.methodStarted(method: method))
        
        self.networkManager.editCourse(withNetworkToken: user?.networkToken, courseID: course.id, status: true) { (response, errorMessage, isCancelled) -> (Void) in
            if let result = response as? [String:Any] {
                self.serviceResultChanged(withResult: ServiceActionResult.methodSucceededWithResponseDictionary(method: method, resultDictionary: result))
            } else {
                self.serviceResultChanged(withResult: ServiceActionResult.methodFailed(method: method, error: errorMessage))
            }
        }
        
        return method
    }
    
    /// Checks saved unfinished course model.
    ///
    /// - returns: Saved unfinished course model if exists or nil otherwise.
    ///
    func savedCourseModel() -> UnfinishedCourseModel? {
        return self.loadCourseModel()
    }
    
    /// Deletes saved unfinished course model and preview image if exists.
    func deleteSavedCourseModel() {
        self.removeSavedCourseModel()
    }
    
    /// Saves unfinished course model.
    ///
    /// - parameter model: Model of the unfinished course model.
    ///
    func saveCourseModel(withCourseModel model: UnfinishedCourseModel) {
        self.saveCourseModel(model)
    }
    
    /// Deletes course images and/or videos from the disk.
    ///
    /// - parameter model: Model of the unfinished course model.
    ///
    func deleteCourseMedia(withCourseModel model: UnfinishedCourseModel) {
        for filename in model.mediaFilenames ?? [] {
            self.removeCoursePreview(wihtName: filename)
        }
    }
    
    /// Deletes course image and/or video from the disk.
    ///
    /// - parameter model: Model of the unfinished course model.
    /// - parameter index: Media index to delete.
    ///
    func deleteCourseMedia(withCourseModel model: UnfinishedCourseModel, atIndex index: Int) {
        guard let mediaFilenames = model.mediaFilenames, mediaFilenames.count > index else {
            return
        }
        
        let filename = mediaFilenames[index]
        self.removeCoursePreview(wihtName: filename)
    }
    
    /// Writes course image to the disk.
    ///
    /// - parameter image: Image to write.
    /// - parameter video: Video to write.
    /// - returns: Filename of the image or video saved.
    ///
    func saveCoursePreview(withImage image: UIImage?, videoURL: URL?) -> String? {
        if let courseImage = image, let imageData = UIImageJPEGRepresentation(courseImage, 0.6) {
            let fileName = UUID().uuidString + ".jpeg"
            do {
                try self.saveCourseImage(wihtData: imageData, fileName: fileName)
                return fileName
            } catch {
                return nil
            }
        }
        
        if let url = videoURL, let videoData = try? Data(contentsOf: url) {
            let fileExtension = url.pathExtension
            let fileName = UUID().uuidString + "." + fileExtension
            do {
                try self.saveCourseVideo(wihtData: videoData, fileName: fileName)
                return fileName
            } catch {
                return nil
            }
        }
        
        return nil
    }
    
    // MARK: Private Methods
    
    private func createCourseIntro(orCourseID courseID: String, introOrder: Int, introType: Int, user: AuthorisedUserModel?) -> String {
        self.bigFileUploadCancelled = false
        self.bigFileUploadPaused = false
        
        let method = "createCourseIntro"
        self.serviceResultChanged(withResult: ServiceActionResult.methodStarted(method: method))
        
        let createCourseIntroTask = self.networkManager.createCourseIntro(withNetworkToken: user?.networkToken, courseID: courseID, introType: introType, introOrder: introOrder) { (response, errorMessage, isCancelled) -> (Void) in
            if isCancelled {
                self.serviceResultChanged(withResult: ServiceActionResult.methodCancelled(method: method))
            } else if let result = response as? [String:Any] {
                self.serviceResultChanged(withResult: ServiceActionResult.methodSucceededWithResponseDictionary(method: method, resultDictionary: result))
            } else {
                self.serviceResultChanged(withResult: ServiceActionResult.methodFailed(method: method, error: errorMessage))
            }
        }
        self.uploadTaskEncoded(createCourseIntroTask)
        
        return method
    }
    
    private func stopBackgroundTask() {
        if self.backgroundTask == UIBackgroundTaskInvalid {
            return
        }
        
        UIApplication.shared.endBackgroundTask(self.backgroundTask)
        self.backgroundTask = UIBackgroundTaskInvalid
    }
    
    private func uploadTaskEncoded(_ sessionTask: URLSessionTask?) {
        if self.bigFileUploadCancelled {
            sessionTask?.suspend()
            sessionTask?.cancel()
            self.bigFileUploadTask = nil
        } else {
            if self.bigFileUploadPaused {
                sessionTask?.suspend()
            }
            
            self.bigFileUploadTask = sessionTask
        }
    }
    
    private func loadCourseModel() -> UnfinishedCourseModel? {
        if let dictionary = UserDefaults.standard.object(forKey: UserDefaultsKeys.unfinishedCourseModel) as? [String:Any] {
            let courseModel = UnfinishedCourseModel(withDictionary: dictionary)
            return courseModel
        } else {
            return nil
        }
    }
    
    private func saveCourseModel(_ model: UnfinishedCourseModel) {
        let dictionary = model.modelAsDictionary()
        UserDefaults.standard.setValue(dictionary, forKey: UserDefaultsKeys.unfinishedCourseModel)
        UserDefaults.standard.synchronize()
    }
    
    private func removeSavedCourseModel() {
        if let dictionary = UserDefaults.standard.object(forKey: UserDefaultsKeys.unfinishedCourseModel) as? [String:Any] {
            let courseModel = UnfinishedCourseModel(withDictionary: dictionary)
            self.deleteCourseMedia(withCourseModel: courseModel)
        }
        
        if UserDefaults.standard.object(forKey: UserDefaultsKeys.unfinishedCourseModel) != nil {
            UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.unfinishedCourseModel)
            UserDefaults.standard.synchronize()
        }
    }
    
    private func removeCoursePreview(wihtName fileName: String) {
        guard let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            return
        }
        
        let filePath = documentsPath + "/" + fileName
        if FileManager.default.fileExists(atPath: filePath) {
            _ = try? FileManager.default.removeItem(atPath: filePath)
        }
    }
    
    private func saveCourseImage(wihtData imageData: Data, fileName: String) throws {
        guard let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            throw NSError()
        }
        
        let filePath = documentsPath + "/" + fileName
        if FileManager.default.fileExists(atPath: filePath) {
            _ = try? FileManager.default.removeItem(atPath: filePath)
        }
        
        let filePathURL = URL(fileURLWithPath: filePath)
        try imageData.write(to: filePathURL)
    }
    
    private func saveCourseVideo(wihtData videoData: Data, fileName: String) throws {
        guard let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            throw NSError()
        }
        
        let filePath = documentsPath + "/" + fileName
        if FileManager.default.fileExists(atPath: filePath) {
            _ = try? FileManager.default.removeItem(atPath: filePath)
        }
        
        let filePathURL = URL(fileURLWithPath: filePath)
        try videoData.write(to: filePathURL)
    }
    
}
