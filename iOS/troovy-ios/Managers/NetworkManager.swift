//
//  NetworkManager.swift
//  troovy-ios
//
//  Created by Daniil on 11.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import Foundation
import UIKit

import Alamofire

class NetworkManager: RequestAdapter {
    
    /// Gets called after request is finished processing.
    /// - response: String or dictionary if any.
    /// - errorMessage: Error string if any.
    /// - isCancelled: Determines if request was cancelled and shouldn't be processed.
    ///
    typealias NetworkCompletionBlock = ((_ response: Any?, _ errorMessage: String?, _ isCancelled: Bool) -> (Void))
    
    let getQueue = DispatchQueue(label: "com.troovy.get-response-queue", qos: .utility, attributes: [.concurrent])
    let postQueue = DispatchQueue(label: "com.troovy.post-response-queue", qos: .utility, attributes: [.concurrent])
    let putQueue = DispatchQueue(label: "com.troovy.put-response-queue", qos: .utility, attributes: [.concurrent])
    let deleteQueue = DispatchQueue(label: "com.troovy.delete-response-queue", qos: .utility, attributes: [.concurrent])
    
    private enum FileType: String {
        case PNG = "image/png"
        case JPEG = "image/jpeg"
        case MP4 = "video/mp4"
        case MOV = "video/quicktime"
        case chunk = "application/octet-stream"
        
        static func fileExtension(forType type: FileType) -> String {
            switch type {
            case .PNG:
                return ".png"
            case .JPEG:
                return ".jpeg"
            case .MP4:
                return ".mp4"
            case .MOV:
                return ".mov"
            case .chunk:
                return ""
            }
        }
        
        static func fileType(forExtension fileExtension: String) -> FileType {
            if fileExtension == "PNG" || fileExtension == "png" {
                return FileType.PNG
            } else if fileExtension == "JPEG" || fileExtension == "jpeg" {
                return FileType.JPEG
            } else if fileExtension == "MP4" || fileExtension == "mp4" {
                return FileType.MP4
            } else if fileExtension == "MOV" || fileExtension == "mov" {
                return FileType.MOV
            } else {
                return FileType.chunk
            }
        }
    }
    
    private enum ReportType: Int {
        case course = 1
    }
    
    private enum CourseBigFileType: Int {
        case introVideo = 1
        case attachmentVideo = 2
        case introImage = 3
    }
    
    private enum CoursesSortingMode: Int {
        case create = 0
        case update = 1
        case nearestSession = 2
    }
    
    private struct Keys {
        static let error = "error"
        static let stack = "stack"
        static let message = "message"
        static let result = "result"
        static let code = "code"
        
        static let userID = "userId"
        static let accessToken = "accessToken"
        
        static let userToken = "appGeneratedToken"
        static let callingCode = "dialCode"
        static let phoneNumber = "phoneNumber"
        static let username = "name"
        static let email = "email"
        static let receipt = "receipt"
        static let shouldDeletePicture = "isUserAvatarShouldDelete"
        
        static let attachmentType = "type"
        static let introType = "type"
        
        static let order = "order"
        
        static let pushToken = "pushToken"
        static let timezoneOffset = "timezone"
        
        static let image = "image"
        static let video = "video"
        static let orderData = "orderData"
        
        static let ignoreSubscribers = "ignoreSubscribers"
        
        static let uploadDataID = "entityId"
        static let uploadingDataType = "entityType"
        static let uploadID = "dataId"
        static let chunk = "chunk"
        static let isLastChunk = "isLast"
        
        static let reason = "reason"
        
        static let verificationCode = "confirmationCode"
        
        static let reportTargetID = "targetId"
        static let reportTargetType = "targetType"
        
        static let courseID = "courseId"
        static let sessionID = "sessionId"
        
        static let title = "title"
        static let description = "description"
        static let price = "price"
        static let tier = "tier"
        static let currency = "currency"
        static let sessions = "sessions"
        static let publish = "status"
        static let startTimestamp = "startAt"
        static let duration = "duration"
        static let deleteImagePreview = "isCourseImageShouldDelete"
        static let deleteVideoPreview = "isCourseIntroVideoShouldDelete"
        
        static let amountFromCard = "amountFromCard"
        static let stripeToken = "stripeToken"
        
        static let identifiers = "ids"
        static let count = "count"
        static let page = "page"
        static let subscribed = "subscribed"
        static let sortingMode = "sortMod"
        static let withoutMyCourses = "withoutMyCourses"
        
        static let amountCredits = "amountCredits"
        static let bankAccountNumber = "bankAccountNumber"
    }
    
    private struct Paths {
        struct POST {
            static let requestVerificationCode = "api/v1/users/verify"
            static let confirmPhoneNumber = "api/v1/users/confirm"
            static let registerUser = "api/v1/users"
            static let logoutUser = "api/v1/users/logout"
            static let loadUsers = "api/v1/users/all"
            static let configureUser = "api/v1/users/config"
            
            static let createCourse = "api/v1/courses"
            static let loadCourses = "api/v1/courses/list"
            
            static let createCourseSession = "api/v1/sessions"
            static let startSession = "api/v1/sessions/start/"
            static let finishSession = "api/v1/sessions/finish/"
            
            static let buyCourseFromBalance = "api/v1/payments/balance/course/"
            static let buyCourseFromWalletAndValidate = "api/v1/payments/app/"
            static let buyCourseEmailReceipt = "api/v1/payments/receipt/"
            
            static let createCourseIntro = "api/v1/intro/"
            static let createCourseAttachment = "api/v1/attachments/"
            
            static let reportCourse = "api/v1/reports"
            
            static let chunkUploading = "api/v1/upload"
            static let finishChunkUploading = "api/v1/upload/finish"
            
            static let requestWithdrawal = "api/v1/withdrawals"
        }
        
        struct GET {
            static let loadRegisteredUser = "api/v1/users"
            
            static let loadSessions = "api/v1/sessions/upcoming"
            
            static let loadCoursesIdentifiers = "api/v1/courses/list"
            static let loadCourse = "api/v1/courses/"
            static let loadCourseSessions = "api/v1/courses/sessions/"
            
            static let loadCourseAttachments = "api/v1/attachments/all/"
            
            static let loadSessionAttachments = "api/v1/sessions/attachments"
            
            static let loadSessionMessages = "api/v1/messages/"
        }
        
        struct PUT {
            static let editCourse = "api/v1/courses/"
            static let editIntrosOrder = "api/v1/intro/"
            
            static let editCourseSession = "api/v1/sessions/"
            
            static let editUser = "api/v1/users/"
        }
        
        struct DELETE {
            static let deleteCourse = "api/v1/courses/"
            static let deleteSession = "api/v1/sessions/"
            static let deleteIntro = "api/v1/intro/"
        }
    }
    
    // MARK: Public Properties
    
    var userBannedAction: ((_ message: String?) -> (Void))?
    
    // MARK: Private Properties
    
    private let infoPlistService = InfoPlistService()
    
    private var activeMethodsCount: Int = 0
    
    // MARK: Init Methods & Superclass Overriders
    
    static let shared = NetworkManager()
    
    /// Creates network manager instance with default session setups.
    init() {
        SessionManager.default.session.configuration.requestCachePolicy = .reloadIgnoringCacheData
        SessionManager.default.session.configuration.urlCache = nil
        SessionManager.default.adapter = self
    }
    
    // MARK: Public Methods
    
    // MARK: Unauthorised User Service
    
    /// Requests sms with verification code.
    ///
    /// - parameter token: User token from UnauthorisedUserModel.
    /// - parameter callingCode: Country calling code from UnauthorisedUserModel.
    /// - parameter phoneNumber: Phone number from UnauthorisedUserModel.
    /// - parameter completion: Completion block. For more look at NetworkCompletionBlock.
    ///
    func requestVerificationCode(withUserToken token: String, callingCode: String, phoneNumber: String, completion: NetworkCompletionBlock?) {
        let parameters = [Keys.userToken : token,
                          Keys.callingCode : callingCode,
                          Keys.phoneNumber : phoneNumber]
        
        _ = self.postRequest(withMethod: Paths.POST.requestVerificationCode, parameters: parameters, completion: completion)
    }
    
    /// Confirms phone number. Gets user info if already registered.
    ///
    /// - parameter token: User token from UnauthorisedUserModel.
    /// - parameter verificationCode: Verification code from sms.
    /// - parameter completion: Completion block. For more look at NetworkCompletionBlock.
    ///
    func confirmPhoneNumber(withUserToken token: String, verificationCode: String, completion: NetworkCompletionBlock?) {
        let parameters = [Keys.userToken : token,
                          Keys.verificationCode : verificationCode]
        
        _ = self.postRequest(withMethod: Paths.POST.confirmPhoneNumber, parameters: parameters, completion: completion)
    }
    
    /// Registers user.
    ///
    /// - parameter token: User token from UnauthorisedUserModel.
    /// - parameter callingCode: Country calling code from UnauthorisedUserModel.
    /// - parameter phoneNumber: Phone number from UnauthorisedUserModel.
    /// - parameter username: Username from UnauthorisedUserModel.
    /// - parameter profilePicture: Profile picture from UnauthorisedUserModel.
    /// - parameter completion: Completion block. For more look at NetworkCompletionBlock.
    ///
    func registerUser(withUserToken token: String, callingCode: String, phoneNumber: String, username: String, profilePicture: UIImage?, completion: NetworkCompletionBlock?) {
        let parameters = [Keys.userToken : token,
                          Keys.callingCode : callingCode,
                          Keys.phoneNumber : phoneNumber,
                          Keys.username : username]
        
        if let image = profilePicture, let data = UIImagePNGRepresentation(image) {
            self.postRequestWithFileUploading(withMethod: Paths.POST.registerUser, data: data, fileType: .PNG, parameters: parameters, networkToken: nil, encodeFinished: nil, progress: nil, completion: completion)
        } else {
            _ = self.postRequest(withMethod: Paths.POST.registerUser, parameters: parameters, completion: completion)
        }
    }
    
    /// Edits user.
    ///
    /// - parameter token: User token from UnauthorisedUserModel.
    /// - parameter userID: User server ID.
    /// - parameter username: Username.
    /// - parameter email: Email
    /// - parameter profilePicture: Profile picture.
    /// - parameter shouldDeletePicture: True if user deleted his profile picture. False otherwise.
    /// - parameter completion: Completion block. For more look at NetworkCompletionBlock.
    ///
    func editUser(withUserToken token: String, userID: String, username: String?, email: String?, profilePicture: UIImage?, shouldDeletePicture: Bool, completion: NetworkCompletionBlock?) {
        var parameters = [Keys.shouldDeletePicture : (shouldDeletePicture ? "1" : "0")]
        let method = Paths.PUT.editUser + userID
        
        if let name = username {
            parameters[Keys.username] = name
        }
        
        if let email = email {
            parameters[Keys.email] = email
        }
        
        if let image = profilePicture, let data = UIImagePNGRepresentation(image) {
            self.putRequestWithFileUploading(withMethod: method, data: data, fileType: .PNG, parameters: parameters, networkToken: token, encodeFinished: nil, progress: nil, completion: completion)
        } else {
            _ = self.putRequest(withMethod: method, parameters: parameters, networkToken: token, completion: completion)
        }
    }
    
    // MARK: Authorised User Service
    
    /// Configures user with parameters and get server configuration.
    ///
    /// - parameter token: Network token from AuthorisedUserModel.
    /// - parameter pushToken: Device push token.
    /// - parameter timezoneOffset: Device timezone offset from UTC in seconds.
    /// - parameter completion: Completion block. For more look at NetworkCompletionBlock.
    ///
    func configureUser(withNetworkToken token: String?, pushToken: String?, timezoneOffset: Int?, completion: NetworkCompletionBlock?) {
        var parameters: [String:Any] = [:]
        if let pushTokenString = pushToken {
            parameters[Keys.pushToken] = pushTokenString
        }
        
        if let offset = timezoneOffset {
            parameters[Keys.timezoneOffset] = offset
        }
        
        let method = Paths.POST.configureUser
        
        _ = self.postRequest(withMethod: method, parameters: parameters, networkToken: token, completion: completion)
    }
    
    /// Deauthorise user.
    ///
    /// - parameter token: Network token from AuthorisedUserModel.
    ///
    func logout(withNetworkToken token: String?) {
        let parameters: [String:Any] = [:]
        
        _ = self.postRequest(withMethod: Paths.POST.logoutUser, parameters: parameters, networkToken: token, completion: nil)
    }
    
    /// Loads user info.
    ///
    /// - parameter token: Network token from AuthorisedUserModel.
    /// - parameter userID: User server ID.
    /// - parameter completion: Completion block. For more look at NetworkCompletionBlock.
    ///
    func loadRegisteredUser(withNetworkToken token: String?, userID: String, completion: NetworkCompletionBlock?) {
        let parameters: [String:Any] = [:]
        
        _ = self.getRequest(withMethod: Paths.GET.loadRegisteredUser, parameters: parameters, networkToken: token, completion: completion)
    }
    
    /// Requests withdrawal and block credits.
    ///
    /// - parameter token: Network token from AuthorisedUserModel.
    /// - parameter amountCredits: Amount of credits to block.
    /// - parameter bankAccountNumber: Bank account number to withdraw.
    /// - parameter completion: Completion block. For more look at NetworkCompletionBlock.
    ///
    func requestWithdrawal(withNetworkToken token: String?, amountCredits: String, bankAccountNumber: String, completion: NetworkCompletionBlock?) {
        let parameters: [String:Any] = [Keys.amountCredits : amountCredits,
                                        Keys.bankAccountNumber : bankAccountNumber]
        
        _ = self.postRequest(withMethod: Paths.POST.requestWithdrawal, parameters: parameters, networkToken: token, completion: completion)
    }
    
    /// Loads users with identifiers.
    ///
    /// - parameter token: Network token from AuthorisedUserModel.
    /// - parameter usersIdentifiers: Array of users server identifiers.
    /// - parameter completion: Completion block. For more look at NetworkCompletionBlock.
    ///
    func loadUsers(withNetworkToken token: String?, usersIdentifiers: [String], completion: NetworkCompletionBlock?) -> URLSessionTask? {
        let parameters: [String:Any] = [Keys.identifiers : usersIdentifiers]
        
        let request = self.postRequest(withMethod: Paths.POST.loadUsers, parameters: parameters, networkToken: token, completion: completion)
        return request.task
    }
    
    // MARK: CreateCoursesService
    
    /// Creates course intro.
    ///
    /// - parameter token: Network token from AuthorisedUserModel.
    /// - parameter courseID: Course server ID.
    /// - parameter introType: Course intro type.
    /// - parameter introOrder: Course intro order.
    /// - parameter completion: Completion block. For more look at NetworkCompletionBlock.
    ///
    func createCourseIntro(withNetworkToken token: String?, courseID: String, introType: Int, introOrder: Int, completion: NetworkCompletionBlock?) -> URLSessionTask? {
        let parameters: [String:Any] = [Keys.introType : introType,
                                        Keys.order : introOrder]
        let method = Paths.POST.createCourseIntro + courseID
        
        let request = self.postRequest(withMethod: method, parameters: parameters, networkToken: token, completion: completion)
        return request.task
    }
    
    /// Uploads course intro.
    ///
    /// - parameter token: Network token from AuthorisedUserModel.
    /// - parameter introID: Course intro server ID.
    /// - parameter introType: Course intro type.
    /// - parameter filePath: Attachment file path.
    /// - parameter encodeFinished: Block. Returns session task for each chunk upload.
    /// - parameter progress: Block. Returns upload progress value.
    /// - parameter completion: Completion block. For more look at NetworkCompletionBlock.
    ///
    func uploadCourseIntro(withNetworkToken token: String?, introID: String, introType: Int, filePath: String, encodeFinished: ((_ uploadTask: URLSessionTask?) -> ())?, progress: ((_ progress: Double) -> ())?, completion: NetworkCompletionBlock?) {
        let parameters: [String:Any] = [Keys.uploadDataID : introID,
                                        Keys.uploadingDataType : introType]
        let fileURL = URL(fileURLWithPath: filePath)
        
        self.postRequestWithChunkUploading(withFileURL: fileURL, parameters: parameters, networkToken: token, encodeFinished: encodeFinished, progress: progress, completion: completion)
    }
    
    /// Creates course session.
    ///
    /// - parameter token: Network token from AuthorisedUserModel.
    /// - parameter title: Title of the course session.
    /// - parameter description: Description of the course session.
    /// - parameter startTimestamp: Course session start timestamp.
    /// - parameter duration: Course session duration.createCourseSession
    /// - parameter courseID: Course server ID.
    /// - parameter completion: Completion block. For more look at NetworkCompletionBlock.
    ///
    func createCourseSession(withNetworkToken token: String?, title: String, description: String, startTimestamp: Int64, duration: Int, forCourseID courseID: String, completion: NetworkCompletionBlock?) {
        let parameters: [String:Any] = [Keys.courseID : courseID,
                                        Keys.title : title,
                                        Keys.description : description,
                                        Keys.startTimestamp : startTimestamp,
                                        Keys.duration : duration]
        
        _ = self.postRequest(withMethod: Paths.POST.createCourseSession, parameters: parameters, networkToken: token, completion: completion)
    }
    
    /// Creates course video attachment.
    ///
    /// - parameter token: Network token from AuthorisedUserModel.
    /// - parameter courseID: Course server ID.
    /// - parameter attachmentType: Course attachment type.
    /// - parameter completion: Completion block. For more look at NetworkCompletionBlock.
    ///
    func createCourseAttachment(withNetworkToken token: String?, courseID: String, attachmentType: Int, completion: NetworkCompletionBlock?) {
        let parameters: [String:Any] = [Keys.attachmentType : attachmentType]
        let method = Paths.POST.createCourseAttachment + courseID
        
        _ = self.postRequest(withMethod: method, parameters: parameters, networkToken: token, completion: completion)
    }
    
    /// Uploads course video attachment.
    ///
    /// - parameter token: Network token from AuthorisedUserModel.
    /// - parameter attachmentID: Course attachment server ID.
    /// - parameter filePath: Attachment file path.
    /// - parameter encodeFinished: Block. Returns session task for each chunk upload.
    /// - parameter progress: Block. Returns upload progress value.
    /// - parameter completion: Completion block. For more look at NetworkCompletionBlock.
    ///
    func createAttachmentVideo(withNetworkToken token: String?, attachmentID: String, filePath: String, encodeFinished: ((_ uploadTask: URLSessionTask?) -> ())?, progress: ((_ progress: Double) -> ())?, completion: NetworkCompletionBlock?) {
        let parameters: [String:Any] = [Keys.uploadDataID : attachmentID,
                                        Keys.uploadingDataType : CourseBigFileType.attachmentVideo.rawValue]
        let fileURL = URL(fileURLWithPath: filePath)
        
        self.postRequestWithChunkUploading(withFileURL: fileURL, parameters: parameters, networkToken: token, encodeFinished: encodeFinished, progress: progress, completion: completion)
    }
    
    /// Edits course session.
    ///
    /// - parameter token: Network token from AuthorisedUserModel.
    /// - parameter title: Title of the course session.
    /// - parameter description: Description of the course session.
    /// - parameter startTimestamp: Course session start timestamp.
    /// - parameter duration: Course session duration.createCourseSession
    /// - parameter courseID: Course server ID.
    /// - parameter completion: Completion block. For more look at NetworkCompletionBlock.
    ///
    func editCourseSession(withNetworkToken token: String?, sessionID: String, title: String?, description: String?, startTimestamp: Int64?, duration: Int?, forCourseID courseID: String, completion: NetworkCompletionBlock?) {
        var parameters: [String:Any] = [Keys.courseID : courseID]
        if let sessionTitle = title {
            parameters[Keys.title] = sessionTitle
        }
        if let sessionDescription = description {
            parameters[Keys.description] = sessionDescription
        }
        if let sessionStartTimestamp = startTimestamp {
            parameters[Keys.startTimestamp] = sessionStartTimestamp
        }
        if let sessionDuration = duration {
            parameters[Keys.duration] = sessionDuration
        }
        let method = Paths.PUT.editCourseSession + sessionID
        
        _ = self.putRequest(withMethod: method, parameters: parameters, networkToken: token, completion: completion)
    }
    
    /// Deletes course.
    ///
    /// - parameter token: Network token from AuthorisedUserModel.
    /// - parameter courseID: Course server ID.
    /// - parameter ignoreSubscribers: Determines if subscribers should be ignored.
    /// - parameter completion: Completion block. For more look at NetworkCompletionBlock.
    ///
    func deleteCourse(withNetworkToken token: String?, courseID: String, ignoreSubscribers: Bool, completion: NetworkCompletionBlock?) {
        let parameters: [String:Any] = [Keys.ignoreSubscribers : (ignoreSubscribers ? "1" : "0")]
        let method = Paths.DELETE.deleteCourse + courseID
        
        _ = self.deleteRequest(withMethod: method, parameters: parameters, networkToken: token, completion: completion)
    }
    
    /// Deletes course intro.
    ///
    /// - parameter token: Network token from AuthorisedUserModel.
    /// - parameter introID: Course intro server ID.
    /// - parameter completion: Completion block. For more look at NetworkCompletionBlock.
    ///
    func deleteCourseIntro(withNetworkToken token: String?, introID: String, completion: NetworkCompletionBlock?) {
        let parameters: [String:Any] = [:]
        let method = Paths.DELETE.deleteIntro + introID
        
        _ = self.deleteRequest(withMethod: method, parameters: parameters, networkToken: token, completion: completion)
    }
    
    /// Deletes course session.
    ///
    /// - parameter token: Network token from AuthorisedUserModel.
    /// - parameter sessionID: Course session server ID.
    /// - parameter completion: Completion block. For more look at NetworkCompletionBlock.
    ///
    func deleteSession(withNetworkToken token: String?, sessionID: String, completion: NetworkCompletionBlock?) {
        let parameters: [String:Any] = [:]
        let method = Paths.DELETE.deleteSession + sessionID
        
        _ = self.deleteRequest(withMethod: method, parameters: parameters, networkToken: token, completion: completion)
    }
    
    /// Reports course.
    ///
    /// - parameter token: Network token from AuthorisedUserModel.
    /// - parameter courseID: Course server ID.
    /// - parameter reason: Report reason.
    /// - parameter completion: Completion block. For more look at NetworkCompletionBlock.
    ///
    func reportCourse(withNetworkToken token: String?, courseID: String, reason: String, completion: NetworkCompletionBlock?) {
        let parameters: [String:Any] = [Keys.reportTargetID : courseID,
                                        Keys.reportTargetType : ReportType.course.rawValue,
                                        Keys.reason : reason]
        
        _ = self.postRequest(withMethod: Paths.POST.reportCourse, parameters: parameters, networkToken: token, completion: completion)
    }
    
    /// Creates course.
    ///
    /// - parameter token: Network token from AuthorisedUserModel.
    /// - parameter title: Title of the course.
    /// - parameter description: Description of the course.
    /// - parameter previewImage: Preview image of the course.
    /// - parameter price: Price of the course. String from NSDecimalNumber.
    /// - parameter sessions: Array of course session models converted to dictionaries.
    /// - parameter publish: Determines should or should not publish this course right after creation.
    /// - parameter completion: Completion block. For more look at NetworkCompletionBlock.
    ///
    func createCourse(withNetworkToken token: String?, title: String, description: String, previewImage: UIImage?, priceTier: String?, sessions: [[String:Any]], publish: Bool, completion: NetworkCompletionBlock?) {
        var parameters: [String:Any] = [Keys.title : title,
                                        Keys.description : description,
                                        Keys.sessions : sessions,
                                        Keys.publish : (publish ? "1" : "0")]
        
        if let coursePriceTier = priceTier, let coursePrice = TroovyProducts.shared.priceForProductIdentifier(coursePriceTier) {
            parameters[Keys.tier] = coursePriceTier
            parameters[Keys.price] = coursePrice.stringValue
        }
        
        if let currencyCode = TroovyProducts.shared.getCurrentCurrency() {
            parameters[Keys.currency] = currencyCode
        }
        
        if let image = previewImage, let data = UIImageJPEGRepresentation(image, 1.0) {
            self.postRequestWithFileUploading(withMethod: Paths.POST.createCourse, data: data, fileType: .JPEG, parameters: parameters, networkToken: token, encodeFinished: nil, progress: nil, completion: completion)
        } else {
            _ = self.postRequest(withMethod: Paths.POST.createCourse, parameters: parameters, networkToken: token, completion: completion)
        }
    }
    
    /// Edits course.
    ///
    /// - parameter token: Network token from AuthorisedUserModel.
    /// - parameter courseID: Course server ID.
    /// - parameter title: Title of the course.
    /// - parameter description: Description of the course.
    /// - parameter previewImage: Preview image of the course.
    /// - parameter price: Price of the course. String from NSDecimalNumber.
    /// - parameter deletePreview: If true preview image and/or video will be deleted.
    /// - parameter completion: Completion block. For more look at NetworkCompletionBlock.
    ///
    func editCourse(withNetworkToken token: String?, courseID: String, title: String?, description: String?, previewImage: UIImage?, price: String?, priceTier: String?, deletePreview: Bool, completion: NetworkCompletionBlock?) {
        var parameters: [String:Any] = [Keys.deleteImagePreview : (deletePreview ? "1" : "0"),
                                        Keys.deleteVideoPreview : (deletePreview ? "1" : "0")]
        if let courseTitle = title {
            parameters[Keys.title] = courseTitle
        }
        if let courseDescription = description {
            parameters[Keys.description] = courseDescription
        }
        if let coursePrice = price {
            parameters[Keys.price] = coursePrice
        }
        if let coursePriceTier = priceTier {
            parameters[Keys.tier] = coursePriceTier
        }
        let method = Paths.PUT.editCourse + courseID
        
        if let image = previewImage, let data = UIImageJPEGRepresentation(image, 1.0) {
            self.putRequestWithFileUploading(withMethod: method, data: data, fileType: .JPEG, parameters: parameters, networkToken: token, encodeFinished: nil, progress: nil, completion: completion)
        } else {
            _ = self.putRequest(withMethod: method, parameters: parameters, networkToken: token, completion: completion)
        }
    }
    
    /// Edits course.
    ///
    /// - parameter token: Network token from AuthorisedUserModel.
    /// - parameter courseID: Course server ID.
    /// - parameter status: true/false (published/unpublished)
    /// - parameter completion: Completion block. For more look at NetworkCompletionBlock.
    ///
    func editCourse(withNetworkToken token: String?, courseID: String, status: Bool, completion: NetworkCompletionBlock?) {
        let parameters: [String:Any] = [Keys.publish : (status ? "1" : "0")]
        let method = Paths.PUT.editCourse + courseID
        
        _ = self.putRequest(withMethod: method, parameters: parameters, networkToken: token, completion: completion)
    }
    
    /// Edits course intros order.
    ///
    /// - parameter token: Network token from AuthorisedUserModel.
    /// - parameter courseID: Course server ID.
    /// - parameter order: Pairs of intro id and order.
    /// - parameter completion: Completion block. For more look at NetworkCompletionBlock.
    ///
    func editCourseIntrosOrder(withNetworkToken token: String?, courseID: String, order: [[String:Any]], completion: NetworkCompletionBlock?) {
        let parameters: [String:Any] = [Keys.orderData : order]
        let method = Paths.PUT.editIntrosOrder
        
        _ = self.putRequest(withMethod: method, parameters: parameters, networkToken: token, completion: completion)
    }
    
    // MARK: CoursesService
    
    /// Loads course attachments.
    ///
    /// - parameter token: Network token from AuthorisedUserModel.
    /// - parameter courseID: Course server ID.
    /// - parameter completion: Completion block. For more look at NetworkCompletionBlock.
    ///
    func loadCourseAttachments(withNetworkToken token: String?, courseID: String, completion: NetworkCompletionBlock?) {
        let parameters: [String:Any] = [:]
        let method = Paths.GET.loadCourseAttachments + courseID
        
        _ = self.getRequest(withMethod: method, parameters: parameters, networkToken: token, completion: completion)
    }
    
    /// Loads session attachments.
    ///
    /// - parameter token: Network token from AuthorisedUserModel.
    /// - parameter sessionID: Course session server ID.
    /// - parameter completion: Completion block. For more look at NetworkCompletionBlock.
    ///
    func loadSessionAttachments(withNetworkToken token: String?, sessionID: String, completion: NetworkCompletionBlock?) {
        let parameters: [String:Any] = [Keys.sessionID : sessionID]
        
        _ = self.getRequest(withMethod: Paths.GET.loadSessionAttachments, parameters: parameters, networkToken: token, completion: completion)
    }
    
    /// Loads course sessions.
    ///
    /// - parameter token: Network token from AuthorisedUserModel.
    /// - parameter courseID: Course server ID.
    /// - parameter completion: Completion block. For more look at NetworkCompletionBlock.
    ///
    func loadCourseSessions(withNetworkToken token: String?, courseID: String, completion: NetworkCompletionBlock?) {
        let parameters: [String:Any] = [:]
        let method = Paths.GET.loadCourseSessions + courseID
        
        _ = self.getRequest(withMethod: method, parameters: parameters, networkToken: token, completion: completion)
    }
    
    /// Loads course.
    ///
    /// - parameter token: Network token from AuthorisedUserModel.
    /// - parameter courseID: Course server ID.
    /// - parameter completion: Completion block. For more look at NetworkCompletionBlock.
    ///
    func loadCourse(withNetworkToken token: String?, courseID: String, completion: NetworkCompletionBlock?) -> URLSessionTask? {
        let parameters: [String:Any] = [:]
        let method = Paths.GET.loadCourse + courseID
        
        let request = self.getRequest(withMethod: method, parameters: parameters, networkToken: token, completion: completion)
        return request.task
    }
    
    /// Loads courses identifiers.
    ///
    /// - parameter token: Network token from AuthorisedUserModel.
    /// - parameter userID: User server ID of courses owner.
    /// - parameter page: Page to load.
    /// - parameter count: Count to load.
    /// - parameter type: Type of courses list.
    /// - parameter completion: Completion block. For more look at NetworkCompletionBlock.
    ///
    func loadCoursesIdentifiers(withNetworkToken token: String?, userID: String?, page: Int, count: Int, type: CourseListProperties.CourseListType, completion: NetworkCompletionBlock?) -> URLSessionTask? {
        var sortingMode: CoursesSortingMode = .nearestSession
        if type == .own {
            sortingMode = .create
        }
        
        var parameters: [String:Any] = [Keys.count : count,
                                        Keys.page : (page + 1),
                                        Keys.subscribed : (type == .subscribed ? "1" : "0"),
                                        Keys.sortingMode : sortingMode.rawValue,
                                        Keys.withoutMyCourses : (type == .own ? "0" : "1")]
        
        if let ownerID = userID {
            parameters[Keys.userID] = ownerID
        }
        
        let request = self.getRequest(withMethod: Paths.GET.loadCoursesIdentifiers, parameters: parameters, networkToken: token, completion: completion)
        return request.task
    }
    
    /// Loads sessions for user.
    ///
    /// - parameter token: Network token from AuthorisedUserModel.
    /// - parameter completion: Completion block. For more look at NetworkCompletionBlock.
    ///
    func loadSessions(withNetworkToken token: String?, completion: NetworkCompletionBlock?) {
        let parameters: [String:Any] = [:]
        _ = self.getRequest(withMethod: Paths.GET.loadSessions, parameters: parameters, networkToken: token, completion: completion)
    }
    
    /// Loads courses with passed identifiers.
    ///
    /// - parameter token: Network token from AuthorisedUserModel.
    /// - parameter identifiers: Array of server identifiers of the courses.
    /// - parameter type: Type of courses list.
    /// - parameter completion: Completion block. For more look at NetworkCompletionBlock.
    ///
    func loadCourses(withNetworkToken token: String?, identifiers: [String], type: CourseListProperties.CourseListType, completion: NetworkCompletionBlock?) -> URLSessionTask? {
        let parameters: [String:Any] = [Keys.identifiers : identifiers]
        
        let request = self.postRequest(withMethod: Paths.POST.loadCourses, parameters: parameters, networkToken: token, completion: completion)
        return request.task
    }
    
    // MARK: PaymentService
    
    /// Buy course with balance.
    ///
    /// - parameter token: Network token from AuthorisedUserModel.
    /// - parameter courseID: Course server ID.
    /// - parameter coursePrice: Price of the course.
    /// - parameter completion: Completion block. For more look at NetworkCompletionBlock.
    ///
    func buyCourse(withNetworkToken token: String?, courseID: String, usingBalanceWithCoursePrice coursePrice: String, completion: NetworkCompletionBlock?) {
        let parameters: [String:Any] = [Keys.price : coursePrice]
        let method = Paths.POST.buyCourseFromBalance + courseID
        
        _ = self.postRequest(withMethod: method, parameters: parameters, networkToken: token, completion: completion)
    }
    
    
    /// Buy course with wallet and validates receipt
    ///
    /// - parameter token: Network token from AuthorisedUserModel.
    /// - parameter courseID: Course server ID.
    /// - parameter coursePrice: Price of the course.
    /// - parameter receiptData: receipt data
    /// - parameter completion: Completion block. For more look at NetworkCompletionBlock.
    ///
    func buyCourseAndValidateReceipt(withNetworkToken token: String?, courseID: String, usingWalletWithCoursePrice coursePrice: String, receiptData: Data, completion: NetworkCompletionBlock?) {
        let parameters: [String:Any] = [Keys.price  : coursePrice,
                                        Keys.receipt: receiptData.base64EncodedString()]

        let method = Paths.POST.buyCourseFromWalletAndValidate + courseID
        
        _ = self.postRequest(withMethod: method, parameters: parameters, networkToken: token, completion: completion)
    }
    
    /// Send confirmation about purchasing a course to email
    ///
    /// - parameter token: Network token from AuthorisedUserModel.
    /// - parameter courseID: Course server ID.
    /// - parameter email: User's email address.
    /// - parameter completion: Completion block. For more look at NetworkCompletionBlock.
    ///
    func sendCoursePurchaseConfirmation(withNetworkToken token: String?, courseID: String, email: String, completion: NetworkCompletionBlock?) {
        let parameters: [String:Any] = [Keys.email : email]
        let method = Paths.POST.buyCourseEmailReceipt + courseID
        
        _ = self.postRequest(withMethod: method, parameters: parameters, networkToken: token, completion: completion)
    }
    
    // MARK: VideoStreamService
    
    /// Starts the session stream.
    ///
    /// - parameter token: Network token from AuthorisedUserModel.
    /// - parameter sessionID: Course session server ID.
    /// - parameter completion: Completion block. For more look at NetworkCompletionBlock.
    ///
    func startSession(withNetworkToken token: String?, sessionID: String, completion: NetworkCompletionBlock?) {
        let parameters: [String:Any] = [:]
        let method = Paths.POST.startSession + sessionID
        
        _ = self.postRequest(withMethod: method, parameters: parameters, networkToken: token, completion: completion)
    }
    
    /// Finishes the session stream.
    ///
    /// - parameter token: Network token from AuthorisedUserModel.
    /// - parameter sessionID: Course session server ID.
    /// - parameter completion: Completion block. For more look at NetworkCompletionBlock.
    ///
    func finishSession(withNetworkToken token: String?, sessionID: String, completion: NetworkCompletionBlock?) {
        let parameters: [String:Any] = [:]
        let method = Paths.POST.finishSession + sessionID
        
        _ = self.postRequest(withMethod: method, parameters: parameters, networkToken: token, completion: completion)
    }
    
    /// Loads session messages.
    ///
    /// - parameter token: Network token from AuthorisedUserModel.
    /// - parameter sessionID: Course session server ID.
    /// - parameter completion: Completion block. For more look at NetworkCompletionBlock.
    ///
    func loadSessionMessages(withNetworkToken token: String?, sessionID: String, completion: NetworkCompletionBlock?) {
        let parameters: [String:Any] = [:]
        let method = Paths.GET.loadSessionMessages + sessionID
        
        _ = self.getRequest(withMethod: method, parameters: parameters, networkToken: token, completion: completion)
    }
    
    // MARK: Private Methods
    
    // MARK: Make Request
    
    private func methodPath(withMethod method: String, networkToken: String?) -> String {
        self.methodStarted()
        
        if let token = networkToken {
            let tokenString = "?" + Keys.accessToken + "=" + token
            let urlString = self.infoPlistService.serverURL() + method + tokenString
            return urlString
        } else {
            let urlString = self.infoPlistService.serverURL() + method
            return urlString
        }
    }
    
    private func postRequest(withMethod method: String, parameters: [String:Any], completion: NetworkCompletionBlock?) -> DataRequest {
        return self.postRequest(withMethod: method, parameters: parameters, networkToken: nil, completion: completion)
    }
    
    private func getRequest(withMethod method: String, parameters: [String:Any], completion: NetworkCompletionBlock?) -> DataRequest {
        return self.getRequest(withMethod: method, parameters: parameters, networkToken: nil, completion: completion)
    }
    
    private func postRequest(withMethod method: String, parameters: [String:Any], networkToken: String?, completion: NetworkCompletionBlock?) -> DataRequest {
        #if DEBUG
            print("\(Date()) POST \(method) with \(parameters)")
        #endif
        
        let urlString = self.methodPath(withMethod: method, networkToken: networkToken)
        let url = URL(string: urlString)
        
        return Alamofire.request(url!, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .response(
                queue: self.postQueue,
                completionHandler: { (result) in
                    self.perform(completion: completion, data: result.data, response: result.response, error: result.error, method: method)
            })
    }
    
    private func deleteRequest(withMethod method: String, parameters: [String:Any], networkToken: String?, completion: NetworkCompletionBlock?) -> DataRequest {
        #if DEBUG
            print("\(Date()) DELETE \(method) with \(parameters)")
        #endif
        
        let urlString = self.methodPath(withMethod: method, networkToken: networkToken)
        let url = URL(string: urlString)
        
        return Alamofire.request(url!, method: .delete, parameters: parameters, encoding: JSONEncoding.default)
            .response(
                queue: self.deleteQueue,
                completionHandler: { (result) in
                    self.perform(completion: completion, data: result.data, response: result.response, error: result.error, method: method)
            })
    }
    
    private func getRequest(withMethod method: String, parameters: [String:Any], networkToken: String?, completion: NetworkCompletionBlock?) -> DataRequest {
        #if DEBUG
            print("\(Date()) GET \(method) with \(parameters)")
        #endif
        
        let urlString = self.methodPath(withMethod: method, networkToken: networkToken)
        let url = URL(string: urlString)
        
        return Alamofire.request(url!, method: .get, parameters: parameters, encoding: URLEncoding.default)
            .response(
                queue: self.getQueue,
                completionHandler: { (result) in
                    self.perform(completion: completion, data: result.data, response: result.response, error: result.error, method: method)
            })
    }
    
    private func putRequest(withMethod method: String, parameters: [String:Any], networkToken: String?, completion: NetworkCompletionBlock?) -> DataRequest {
        #if DEBUG
            print("\(Date()) PUT \(method) with \(parameters)")
        #endif
        
        let urlString = self.methodPath(withMethod: method, networkToken: networkToken)
        let url = URL(string: urlString)
        
        return Alamofire.request(url!, method: .put, parameters: parameters, encoding: JSONEncoding.default)
            .response(
                queue: self.putQueue,
                completionHandler: { (result) in
                    self.perform(completion: completion, data: result.data, response: result.response, error: result.error, method: method)
            })
    }
    
    private func postRequestWithFileUploading(withMethod method: String, data: Data, fileType: FileType, parameters: [String:Any], networkToken: String?, encodeFinished: ((_ uploadTask: URLSessionTask?) -> ())?, progress: ((_ progress: Double) -> ())?, completion: NetworkCompletionBlock?) {
        let fileExtension = FileType.fileExtension(forType: fileType)
        
        self.postRequestWithFileUploading(withMethod: method, data: data, fileType: fileType, fileExtension: fileExtension, parameters: parameters, networkToken: networkToken, encodeFinished: encodeFinished, progress: progress, completion: completion)
    }
    
    private func postRequestWithFileUploading(withMethod method: String, data: Data, fileType: FileType, fileExtension: String, parameters: [String:Any], networkToken: String?, encodeFinished: ((_ uploadTask: URLSessionTask?) -> ())?, progress: ((_ progress: Double) -> ())?, completion: NetworkCompletionBlock?) {
        #if DEBUG
            print("\(Date()) POST \(method) and upload file with type \(fileType.rawValue), extension \(fileExtension), size \(self.bytesString(fromData: data)) and properties \(parameters)")
        #endif
        
        let urlString = self.methodPath(withMethod: method, networkToken: networkToken)
        let url = URL(string: urlString)
        let request = try? URLRequest(url: url!, method: .post)
        let filename = UUID().uuidString + fileExtension
        let mimeType = fileType.rawValue
        let name = ((fileType == .JPEG || fileType == .PNG) ? Keys.image : ((fileType == .MP4 || fileType == .MOV) ? Keys.video : Keys.chunk))
        
        self.uploadData(data, withRequest: request!, method: method, name: name, filename: filename, mimeType: mimeType, parameters: parameters, encodeFinished: encodeFinished, progress: progress, completion: completion)
    }
    
    private func putRequestWithFileUploading(withMethod method: String, data: Data, fileType: FileType, parameters: [String:Any], networkToken: String?, encodeFinished: ((_ uploadTask: URLSessionTask?) -> ())?, progress: ((_ progress: Double) -> ())?, completion: NetworkCompletionBlock?) {
        #if DEBUG
            print("\(Date()) PUT \(method) and upload file with type \(fileType.rawValue), size \(self.bytesString(fromData: data)) and properties \(parameters)")
        #endif
        
        let fileExtension = FileType.fileExtension(forType: fileType)
        let urlString = self.methodPath(withMethod: method, networkToken: networkToken)
        let url = URL(string: urlString)
        let request = try? URLRequest(url: url!, method: .put)
        let filename = UUID().uuidString + fileExtension
        let mimeType = fileType.rawValue
        let name = ((fileType == .JPEG || fileType == .PNG) ? Keys.image : ((fileType == .MP4 || fileType == .MOV) ? Keys.video : Keys.chunk))
        
        self.uploadData(data, withRequest: request!, method: method, name: name, filename: filename, mimeType: mimeType, parameters: parameters, encodeFinished: encodeFinished, progress: progress, completion: completion)
    }
    
    private func uploadData(_ data: Data, withRequest request: URLRequest, method: String, name: String, filename: String, mimeType: String, parameters: [String:Any], encodeFinished: ((_ uploadTask: URLSessionTask?) -> ())?, progress: ((_ progress: Double) -> ())?, completion: NetworkCompletionBlock?) {
        Alamofire.upload(multipartFormData: { (multipartFormData) in
            for (key, value) in parameters {
                if value is [[String:Any]] {
                    let valueArray = value as! [[String:Any]]
                    
                    var index = 0
                    for valueObject in valueArray {
                        for (objectKey, objectValue) in valueObject {
                            let valueString = "\(objectValue)"
                            if let encodedStringAsData = valueString.data(using: String.Encoding.utf8) {
                                multipartFormData.append(encodedStringAsData, withName: "\(key)[\(index)][\(objectKey)]")
                            }
                        }
                        
                        index += 1
                    }
                } else {
                    let valueString = "\(value)"
                    if let encodedStringAsData = valueString.data(using: String.Encoding.utf8) {
                        multipartFormData.append(encodedStringAsData, withName: key)
                    }
                }
            }
            
            multipartFormData.append(data, withName: name, fileName: filename, mimeType: mimeType)
        }, with: request, encodingCompletion: { (encodingResult) in
            switch encodingResult {
            case .success(let upload, _, _):
                encodeFinished?(upload.task)
                
                upload.uploadProgress(closure: { (value) in
                    progress?(value.fractionCompleted)
                })
                
                upload.response(completionHandler: { (result) in
                    self.perform(completion: completion, data: result.data, response: result.response, error: result.error, method: method)
                })
            case .failure(let error):
                self.perform(completion: completion, data: nil, response: nil, error: error, method: method)
            }
        })
    }
    
    // MARK: Chunk Upload
    
    private func postRequestWithChunkUploading(withFileURL fileURL: URL, parameters: [String:Any], networkToken: String?, encodeFinished: ((_ uploadTask: URLSessionTask?) -> ())?, progress: ((_ progress: Double) -> ())?, completion: NetworkCompletionBlock?) {
        if let fileHandle = try? FileHandle.init(forReadingFrom: fileURL) {
            let fileExtension = "." + fileURL.pathExtension.lowercased()
            
            fileHandle.seekToEndOfFile()
            let maximumOffset: UInt64 = fileHandle.offsetInFile
            
            self.runChunkUploading(withUploadingID: nil, fileHandle: fileHandle, offset: 0, maximumOffset: maximumOffset, currentProgress: 0.0, fileExtension: fileExtension, parameters: parameters, networkToken: networkToken, encodeFinished: encodeFinished, progress: progress, completion: completion)
        } else {
            DispatchQueue.global().async {
                self.perform(completion: completion, data: nil, response: nil, error: nil, method: Paths.POST.chunkUploading)
            }
        }
    }
    
    private func runChunkUploading(withUploadingID uploadingID: String?, fileHandle: FileHandle, offset: UInt64, maximumOffset: UInt64, currentProgress: Double, fileExtension: String, parameters: [String:Any], networkToken: String?, encodeFinished: ((_ uploadTask: URLSessionTask?) -> ())?, progress: ((_ progress: Double) -> ())?, completion: NetworkCompletionBlock?) {
        fileHandle.seek(toFileOffset: offset)
        
        let chunkSize = 1024 * 1024
        var dataLength = chunkSize
        let dataLeft = maximumOffset - offset
        var isLastChunk = false
        if dataLeft < chunkSize {
            dataLength = Int(dataLeft)
            isLastChunk = true
        }
        let chunk = (currentProgress >= 1.0 ? nil : fileHandle.readData(ofLength: dataLength))
        
        var chunkParameters = parameters
        chunkParameters[Keys.isLastChunk] = (isLastChunk ? "1" : "0")
        
        if let id = uploadingID {
            chunkParameters[Keys.uploadID] = id
        }
        
        let chunkProgressPart = Double(dataLength) / Double(maximumOffset)
        var newProgress = currentProgress
        
        self.appendChunkUploading(withChunk: chunk, fileExtension: fileExtension, parameters: chunkParameters, networkToken: networkToken, encodeFinished: encodeFinished, progress: { (value) in
            newProgress = currentProgress + chunkProgressPart * value
            
            if newProgress > 1.0 {
                newProgress = 1.0
            }
            
            progress?(newProgress)
        }) { (response, errorMessage, isCancelled) -> (Void) in
            if response != nil && !isCancelled {
                let dataID = (response as? [String:Any])?[Keys.uploadID] as? String
                
                let newOffset = offset + UInt64(dataLength)
                if newOffset >= maximumOffset {
                    self.finishChunkUploading(parameters: chunkParameters, networkToken: networkToken, completion: nil)
                    completion?(response, errorMessage, isCancelled)
                } else {
                    self.runChunkUploading(withUploadingID: dataID, fileHandle: fileHandle, offset: newOffset, maximumOffset: maximumOffset, currentProgress: newProgress, fileExtension: fileExtension, parameters: parameters, networkToken: networkToken, encodeFinished: encodeFinished, progress: progress, completion: completion)
                }
            } else {
                if isCancelled || errorMessage != ApplicationMessages.ErrorMessages.requestTimedOut {
                    completion?(response, errorMessage, isCancelled)
                } else {
                    self.runChunkUploading(withUploadingID: uploadingID, fileHandle: fileHandle, offset: offset, maximumOffset: maximumOffset, currentProgress: newProgress, fileExtension: fileExtension, parameters: parameters, networkToken: networkToken, encodeFinished: encodeFinished, progress: progress, completion: completion)
                }
            }
        }
    }
    
    private func appendChunkUploading(withChunk chunk: Data?, fileExtension: String, parameters: [String:Any], networkToken: String?, encodeFinished: ((_ uploadTask: URLSessionTask?) -> ())?, progress: ((_ progress: Double) -> ())?, completion: NetworkCompletionBlock?) {
        
        if let data = chunk {
            self.postRequestWithFileUploading(withMethod: Paths.POST.chunkUploading, data: data, fileType: .chunk, fileExtension: fileExtension, parameters: parameters, networkToken: networkToken, encodeFinished: encodeFinished, progress: progress, completion: completion)
        } else {
            _ = self.postRequest(withMethod: Paths.POST.chunkUploading, parameters: parameters, networkToken: networkToken, completion: completion)
        }
    }
    
    private func finishChunkUploading(parameters: [String:Any], networkToken: String?, completion: NetworkCompletionBlock?) {
        _ = self.postRequest(withMethod: Paths.POST.finishChunkUploading, parameters: parameters, networkToken: networkToken, completion: completion)
    }
    
    // MARK: Process Response
    
    private func perform(completion: NetworkCompletionBlock?, data: Data?, response: URLResponse?, error: Error?, method: String) {
        #if DEBUG
            print("\(Date()) complete \(method)")
        #endif
        
        var payload = self.payload(fromData: data)
        let errorMessage = self.errorMessage(withData: data, response: response, error: error, payload: payload)
        
        var isCancelled = false
        if let errorWithCode = error as NSError? {
            isCancelled = (errorWithCode.code == NSURLErrorCancelled)
        }
        
        var isBanned = false
        if let payloadDictionary = payload as? [String:Any], let code = payloadDictionary[Keys.code] as? Int {
            isBanned = (code == 405)
        }
        
        if errorMessage != nil || isCancelled {
            payload = nil
        }
        
        self.methodFinished()
        
        if isBanned {
            completion?(nil, nil, isBanned)
            self.userBannedAction?(errorMessage)
        } else {
            completion?(payload, errorMessage, isCancelled)
        }
    }
    
    private func payload(fromData data: Data?) -> Any? {
        var payload: Any? = nil
        if data != nil {
            if let serializedData = try? JSONSerialization.jsonObject(with: data!, options: []) {
                if let serializedDictionary = serializedData as? [String:Any] {
                    if let resultDictionary = serializedDictionary[Keys.result] {
                        payload = resultDictionary
                    } else {
                        payload = serializedDictionary
                    }
                }
            } else if let serializedString = String.init(data: data!, encoding: .utf8) {
                payload = serializedString
            }
        }
        
        return payload
    }
    
    private func errorMessage(withData data: Data?, response: URLResponse?, error: Error?, payload: Any?) -> String? {
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        let isNotReachable = (data == nil) && (response == nil) && (error == nil)
        let isTimedOut = (statusCode == 0)
        let isInternalServerError = (statusCode == 500)
        
        var message: String? = nil
        if isTimedOut {
            message = ApplicationMessages.ErrorMessages.requestTimedOut
        } else if error != nil {
            message = error!.localizedDescription
        } else if isNotReachable {
            message = ApplicationMessages.ErrorMessages.internetNotReachable
        } else if isInternalServerError {
            message = ApplicationMessages.ErrorMessages.serverError
        }
        
        if payload != nil {
            if let dictionary = payload as? [String:Any] {
                if let dictionaryMessage = dictionary[Keys.error] as? String {
                    message = dictionaryMessage
                } else if let dictionaryMessageObject = dictionary[Keys.error] as? [String:Any] {
                    var messages = ""
                    for (key, value) in dictionaryMessageObject {
                        if key == Keys.stack {
                            continue
                        }
                        if dictionaryMessageObject.count > 0 {
                            if value is String {
                                messages.append("\n\(value)")
                            } else if let valueObjects = value as? [[String:Any]] {
                                for valueObject in valueObjects {
                                    if valueObject.count > 0 {
                                        for (_, value) in valueObject {
                                            if value is String {
                                                messages.append("\n\(value)")
                                            } else {
                                                messages = ""
                                                break
                                            }
                                        }
                                    }
                                }
                            } else {
                                messages = ""
                                break
                            }
                        }
                    }
                    
                    if !messages.isEmpty {
                        message = messages
                    }
                } else if let dictionaryMessage = dictionary[Keys.message] as? String {
                    message = dictionaryMessage
                }
            }
        }
        
        if statusCode >= 300 && message == nil {
            message = "\(statusCode) - \(HTTPURLResponse.localizedString(forStatusCode: statusCode))"
        }
        
        return message
    }
    
    // MARK: Support Methods
    
    private func bytesString(fromData data: Data) -> String {
        let bytesCount = NSNumber(value: data.count)
        
        let numberFormatter = NumberFormatter()
        if let bytesString = numberFormatter.string(from: bytesCount) {
            return "\(bytesString) bytes"
        }
        return "\(bytesCount) bytes"
    }
    
    private func methodStarted() {
        DispatchQueue.main.async {
            self.activeMethodsCount += 1
            self.checkActivityIndicator()
        }
        
    }
    
    private func methodFinished() {
        DispatchQueue.main.async {
            self.activeMethodsCount -= 1
            if self.activeMethodsCount < 0 {
                self.activeMethodsCount = 0
            }
            
            self.checkActivityIndicator()
        }
    }
    
    private func checkActivityIndicator() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = (self.activeMethodsCount > 0)
    }
    
    // MARK: Protocols Implementation
    
    // MARK: RequestAdapter
    
    internal func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
        var request = urlRequest
        request.cachePolicy = .reloadIgnoringCacheData
        request.timeoutInterval = 30.0
        
        return request
    }
    
}
