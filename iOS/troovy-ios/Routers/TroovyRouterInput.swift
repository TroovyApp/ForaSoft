//
//  TroovyRouterInput.swift
//  troovy-ios
//
//  Created by Daniil on 11.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import Foundation
import UIKit

protocol TroovyRouterOptionalInput {

    /// This method must be overridden to make "viewControllerInited" from TroovyRouterInput doable.
    func optionalViewControllerInited(viewController: UIViewController) throws
    
    
    
    // MARK: LaunchRouterInput
    
    /// This method must be overridden to make "showTutorialViewController" from TroovyRouterInput doable.
    func optionalShowTutorialViewController() throws
    
    /// This method must be overridden to make "showUnauthorisedViewController" from TroovyRouterInput doable.
    func optionalShowUnauthorisedViewController() throws
    
    /// This method must be overridden to make "showAuthorisedViewController(withAuthorisedUserModel:)" from TroovyRouterInput doable.
    func optionalShowAuthorisedViewController(withAuthorisedUserModel model: AuthorisedUserModel) throws
    
    
    
    // MARK: UnauthorisedRouterInput
    
    /// This method must be overridden to make "showUserVerificationViewController(withUnauthorisedUserModel:)" from TroovyRouterInput doable.
    func optionalShowUserVerificationViewController(withUnauthorisedUserModel model: UnauthorisedUserModel) throws
    
    /// This method must be overridden to make "showUserVerificationViewController(withUnauthorisedUserModel:)" from TroovyRouterInput doable.
    func optionalShowRegistrationViewController(withUnauthorisedUserModel model: UnauthorisedUserModel) throws
    
    /// This method must be overridden to make "takeProfilePictureFromCamera(withDelegate:completion:)" from TroovyRouterInput doable.
    func optionalTakeProfilePictureFromCamera(withDelegate delegate: (UIImagePickerControllerDelegate & UINavigationControllerDelegate), completion: (() -> ())?) throws
    
    /// This method must be overridden to make "takeProfilePictureFromCameraRoll(withDelegate::completion)" from TroovyRouterInput doable.
    func optionalTakeProfilePictureFromCameraRoll(withDelegate delegate: (UIImagePickerControllerDelegate & UINavigationControllerDelegate), completion: (() -> ())?) throws

    
    
    // MARK: AuthorisedRouterInput

    /// This method must be overridden to make "changeChildRouter(withNew:)" from TroovyRouterInput doable.
    func optionalChangeChildRouter(withNew childRouter: TroovyRouter) throws
    
    
    
    // MARK: CoursesRouterInput
    
    /// This method must be overridden to make "showCreateCourseMainInfoScreen(withAuthorisedUserModel:courseModel:)" from TroovyRouterInput doable.
    func optionalShowCreateCourseMainInfoScreen(withAuthorisedUserModel userModel: AuthorisedUserModel, courseModel: UnfinishedCourseModel?) throws
    
    /// This method must be overridden to make "showCourseSessionScreen(withAuthorisedUserModel:sessionModel:courseSessionAlwaysEditable:delegate:)" from TroovyRouterInput doable.
    func optionalShowCourseSessionScreen(withAuthorisedUserModel userModel: AuthorisedUserModel?, sessionModel: CourseSessionModel?, courseSessionAlwaysEditable: Bool, delegate: CreateSessionDelegate?) throws
    
    /// This method must be overridden to make "showOwnCourseScreen(withAuthorisedUserModel:courseModel:)" from TroovyRouterInput doable.
    func optionalShowOwnCourseScreen(withAuthorisedUserModel userModel: AuthorisedUserModel, courseModel: CourseModel) throws
    
    /// This method must be overridden to make "showCommonCourseScreen(withAuthorisedUserModel:courseModel:courseID)" from TroovyRouterInput doable.
    func optionalShowCommonCourseScreen(withAuthorisedUserModel userModel: AuthorisedUserModel?, courseModel: CourseModel?, courseID: String) throws
    
    /// This method must be overridden to make "showVideo(withVideoURL:)" from TroovyRouterInput doable.
    func optionalShowVideo(withVideoURL videoURL: URL) throws
    
    /// This method must be overridden to make "showCourseImage(withImage:)" from TroovyRouterInput doable.
    func optionalShowCourseImage(withImage image: UIImage) throws
    
    /// This method must be overridden to make "showCourseSessionsScreen(withAuthorisedUserModel:courseModel:changePossible:)" from TroovyRouterInput doable.
    func optionalShowCourseSessionsScreen(withAuthorisedUserModel userModel: AuthorisedUserModel?, courseModel: CourseModel, changePossible: Bool) throws
    
    /// This method must be overridden to make "showCourseAttachmentsScreen(withAuthorisedUserModel:courseModel:)" from TroovyRouterInput doable.
    func optionalShowCourseAttachmentsScreen(withAuthorisedUserModel userModel: AuthorisedUserModel?, courseModel: CourseModel) throws
    
    /// This method must be overridden to make "showEditCourseScreen(withAuthorisedUserModel:courseModel:)" from TroovyRouterInput doable.
    func optionalShowEditCourseScreen(withAuthorisedUserModel userModel: AuthorisedUserModel, courseModel: CourseModel) throws
    
    /// This method must be overridden to make "showUploadAttachmentScreen(withAuthorisedUserModel:courseModel:attachmentModel:)" from TroovyRouterInput doable.
    func optionalShowUploadAttachmentScreen(withAuthorisedUserModel userModel: AuthorisedUserModel, courseModel: CourseModel, attachmentModel: CourseAttachmentModel) throws
    
    /// This method must be overridden to make "optionalShowUploadCourseIntroScreen(withAuthorisedUserModel:courseModel:introFilePath:courseCreation:unfinishedCourseModel:)" from TroovyRouterInput doable.
    func optionalShowUploadCourseIntroScreen(withAuthorisedUserModel userModel: AuthorisedUserModel, courseModel: CourseModel, introFilePath: String, courseCreation: Bool, unfinishedCourseModel: UnfinishedCourseModel) throws
    
    /// This method must be overridden to make "takeCoursePreviewFromCamera(withDelegate:completion:)" from TroovyRouterInput doable.
    func optionalTakeCoursePreviewFromCamera(withDelegate delegate: (UIImagePickerControllerDelegate & UINavigationControllerDelegate), completion: (() -> ())?) throws
    
    /// This method must be overridden to make "takeCoursePreviewFromCameraRoll(withDidSelect:maxSelectableCount:completion:)" from TroovyRouterInput doable.
    func optionalTakeCoursePreviewFromCameraRoll(withDidSelect didSelect: ((_ assets: [DKAsset]) -> Void)?, maxSelectableCount: Int, completion: (() -> ())?) throws
    
    /// This method must be overridden to make "takeCourseAttachmentFromCameraRoll(withDelegate:completion:)" from TroovyRouterInput doable.
    func optionalTakeCourseAttachmentFromCameraRoll(withDelegate delegate: (UIImagePickerControllerDelegate & UINavigationControllerDelegate), completion: (() -> ())?) throws
    
    /// This method must be overridden to make "showReportCourseScreen(withAuthorisedUserModel:courseID:)" from TroovyRouterInput doable.
    func optionalShowReportCourseScreen(withAuthorisedUserModel userModel: AuthorisedUserModel, courseID: String) throws
    
    /// This method must be overridden to make "showBuyCourseScreen(withAuthorisedUserModel:course:)" from TroovyRouterInput doable.
    func optionalShowBuyCourseScreen(withAuthorisedUserModel userModel: AuthorisedUserModel, course: CourseModel) throws
    
    /// This method must be overridden to make "showCourseNotEnoughMoneyViewController(withAuthorisedUserModel:notEnoughAmount:cardParameters:delegate:)" from TroovyRouterInput doable.
    func optionalShowCourseNotEnoughMoneyViewController(withAuthorisedUserModel userModel: AuthorisedUserModel, notEnoughAmount: Double, cardParameters: [String:Any], delegate: CourseNotEnoughMoneyDelegate) throws
    
    /// This method must be overridden to make "showOtherProfileViewController(withAuthorisedUserModel:userID:)" from TroovyRouterInput doable.
    func optionalShowOtherProfileViewController(withAuthorisedUserModel userModel: AuthorisedUserModel, userID: String) throws
    
    
    
    // MARK: ScheduleRouterInput
    
    /// This method must be overridden to make "showFuturePastSessionScreen(withAuthorisedUserModel:sessionModel:courseModel:)" from TroovyRouterInput doable.
    func optionalShowFuturePastSessionScreen(withAuthorisedUserModel userModel: AuthorisedUserModel?, sessionModel: CourseSessionModel, courseModel: CourseModel?) throws
    
    /// This method must be overridden to make "showVideoStreamViewController(withAuthorisedUserModel:sessionModel:sessionOwner:)" from TroovyRouterInput doable.
    func optionalShowVideoStreamViewController(withAuthorisedUserModel userModel: AuthorisedUserModel, sessionModel: CourseSessionModel, sessionOwner: Bool) throws
    
    /// This method must be overridden to make "showFinishStreamViewController(withAuthorisedUserModel:streamInfoModel:sessionOwner:)" from TroovyRouterInput doable.
    func optionalShowFinishStreamViewController(withAuthorisedUserModel userModel: AuthorisedUserModel, streamInfoModel: StreamInfoModel, sessionOwner: Bool) throws
    
    /// This method must be overridden to make "showSessionAttachmentViewController(withAuthorisedUserModel:attachmentModel:)" from TroovyRouterInput doable.
    func optionalShowSessionAttachmentViewController(withAuthorisedUserModel userModel: AuthorisedUserModel, attachmentModel: CourseAttachmentModel) throws
    
    
    
    // MARK: SettingsRouterInput
    
    /// This method must be overridden to make "showCreditsViewController(withAuthorisedUserModel:)" from TroovyRouterInput doable.
    func optionalShowCreditsViewController(withAuthorisedUserModel userModel: AuthorisedUserModel) throws
    
    /// This method must be overridden to make "showWithdrawalCardViewController(withAuthorisedUserModel:currentBalance:delegate:)" from TroovyRouterInput doable.
    func optionalShowWithdrawalCardViewController(withAuthorisedUserModel userModel: AuthorisedUserModel, currentBalance: String?, delegate: WithdrawalCardDelegate) throws
    
    /// This method must be overridden to make "showEditProfileViewController(withAuthorisedUserModel:)" from TroovyRouterInput doable.
    func optionalShowEditProfileViewController(withAuthorisedUserModel userModel: AuthorisedUserModel) throws
    
    
    
}

protocol TroovyRouterInput: class, LaunchRouterInput, UnauthorisedRouterInput, AuthorisedRouterInput, CoursesRouterInput, ScheduleRouterInput, SettingsRouterInput {
    
    /// Injects services in passed view controller.
    ///
    /// - parameter viewController: View controller to inject services.
    ///
    func viewControllerInited(viewController: UIViewController)
    
    /// Releases router from his parent router.
    func routerShouldRelease()
    
}

protocol LaunchRouterInput {
    
    /// Shows TutorialViewController.
    func showTutorialViewController()
    
    /// Shows UnauthorisedViewController.
    func showUnauthorisedViewController()
    
    /// Shows AuthorisedViewController.
    ///
    /// - parameter model: Model of the authorised user.
    ///
    func showAuthorisedViewController(withAuthorisedUserModel model: AuthorisedUserModel)
    
}

protocol UnauthorisedRouterInput {
    
    /// Shows UserVerificationViewController.
    ///
    /// - parameter model: Model of the unauthorised user.
    ///
    func showUserVerificationViewController(withUnauthorisedUserModel model: UnauthorisedUserModel)
    
    /// Shows RegistrationViewController.
    ///
    /// - parameter model: Model of the unauthorised user.
    ///
    func showRegistrationViewController(withUnauthorisedUserModel model: UnauthorisedUserModel)
    
    /// Shows UIImagePickerController.
    ///
    /// - parameter delegate: Delegate. Responds to UIImagePickerControllerDelegate and UINavigationControllerDelegate.
    /// - parameter completion: Presentation completion block.
    ///
    func takeProfilePictureFromCamera(withDelegate delegate: (UIImagePickerControllerDelegate & UINavigationControllerDelegate), completion: (() -> ())?)
    func takeProfilePictureFromCameraRoll(withDelegate delegate: (UIImagePickerControllerDelegate & UINavigationControllerDelegate), completion: (() -> ())?)
    
}

protocol AuthorisedRouterInput {
    
    /// Sets new child router.
    ///
    /// - parameter childRouter: New child router.
    ///
    func changeChildRouter(withNew childRouter: TroovyRouter)
    func showScheduleScreen()
    
}

protocol CoursesRouterInput {
    
    /// Shows CreateCourseMainInfoViewController.
    ///
    /// - parameter userModel: Model of the authorised user.
    /// - parameter courseModel: Model of the unfinished course. Course creation continues if model not nil.
    ///
    func showCreateCourseMainInfoScreen(withAuthorisedUserModel userModel: AuthorisedUserModel, courseModel: UnfinishedCourseModel?)
    
    /// Shows CreateSessionViewController.
    ///
    /// - parameter userModel: Model of the authorised user.
    /// - parameter sessionModel: Model of the course session or nil.
    /// - parameter courseSessionAlwaysEditable: True if session should be editable without restrictions.
    /// - delegate: Delegate. Responds to CreateSessionDelegate.
    ///
    func showCourseSessionScreen(withAuthorisedUserModel userModel: AuthorisedUserModel?, sessionModel: CourseSessionModel?, courseSessionAlwaysEditable: Bool, delegate: CreateSessionDelegate?)
    
    /// Shows OwnCourseViewController.
    ///
    /// - parameter userModel: Model of the authorised user.
    /// - parameter courseModel: Model of the course.
    ///
    func showOwnCourseScreen(withAuthorisedUserModel userModel: AuthorisedUserModel, courseModel: CourseModel)
    
    /// Shows CommonCourseViewController.
    ///
    /// - parameter userModel: Model of the authorised user.
    /// - parameter courseModel: Model of the course.
    /// - parameter courseID: Course server ID.
    ///
    func showCommonCourseScreen(withAuthorisedUserModel userModel: AuthorisedUserModel?, courseModel: CourseModel?, courseID: String)
    
    /// Shows TroovyPlayerViewController.
    ///
    /// - parameter videoURL: URL of the video to show.
    ///
    func showVideo(withVideoURL videoURL: URL)
    
    /// Shows ImageScreenViewController.
    ///
    /// - parameter image: Course image to show.
    ///
    func showCourseImage(withImage image: UIImage)
    
    /// Shows CourseAttachmentsViewController.
    ///
    /// - parameter userModel: Model of the authorised user.
    /// - parameter courseModel: Model of the course.
    ///
    func showCourseAttachmentsScreen(withAuthorisedUserModel userModel: AuthorisedUserModel?, courseModel: CourseModel)
    
    /// Shows EditCourseViewController.
    ///
    /// - parameter userModel: Model of the authorised user.
    /// - parameter courseModel: Model of the course.
    ///
    func showEditCourseScreen(withAuthorisedUserModel userModel: AuthorisedUserModel, courseModel: CourseModel)
    
    /// Shows UploadAttachmentViewController.
    ///
    /// - parameter userModel: Model of the authorised user.
    /// - parameter courseModel: Model of the course.
    /// - parameter attachmentModel: Model of the course attachment.
    ///
    func showUploadAttachmentScreen(withAuthorisedUserModel userModel: AuthorisedUserModel, courseModel: CourseModel, attachmentModel: CourseAttachmentModel)
    
    /// Shows UploadCourseIntroViewController.
    ///
    /// - parameter userModel: Model of the authorised user.
    /// - parameter courseModel: Model of the course.
    /// - parameter introFilePath: Intro folder path.
    /// - parameter courseCreation: Determines if a course is being created.
    /// - parameter unfinishedCourseModel: New model of the course.
    ///
    func showUploadCourseIntroScreen(withAuthorisedUserModel userModel: AuthorisedUserModel, courseModel: CourseModel, introFilePath: String, courseCreation: Bool, unfinishedCourseModel: UnfinishedCourseModel)
    
    /// Shows UIImagePickerController.
    ///
    /// - parameter delegate: Delegate. Responds to UIImagePickerControllerDelegate and UINavigationControllerDelegate.
    /// - parameter completion: Presentation completion block.
    ///
    func takeCoursePreviewFromCamera(withDelegate delegate: (UIImagePickerControllerDelegate & UINavigationControllerDelegate), completion: (() -> ())?)
    func takeCourseAttachmentFromCameraRoll(withDelegate delegate: (UIImagePickerControllerDelegate & UINavigationControllerDelegate), completion: (() -> ())?)
    
    /// Shows DKImagePickerController.
    ///
    /// - parameter didSelect: Selection block.
    /// - parameter maxSelectableCount: Maximum count to select.
    /// - parameter completion: Presentation completion block.
    ///
    func takeCoursePreviewFromCameraRoll(withDidSelect didSelect: ((_ assets: [DKAsset]) -> Void)?, maxSelectableCount: Int, completion: (() -> ())?)
    
    /// Shows ReportCourseViewController.
    ///
    /// - parameter userModel: Model of the authorised user.
    /// - parameter courseID: Course server ID.
    ///
    func showReportCourseScreen(withAuthorisedUserModel userModel: AuthorisedUserModel, courseID: String)
    
    /// Shows CoursePaymentViewController.
    ///
    /// - parameter userModel: Model of the authorised user.
    /// - parameter course: Course model.
    ///
    func showBuyCourseScreen(withAuthorisedUserModel userModel: AuthorisedUserModel, course: CourseModel)
    
    /// Shows CourseNotEnoughMoneyViewController.
    ///
    /// - parameter userModel: Model of the authorised user.
    /// - parameter notEnoughAmount: Not enough amount.
    /// - parameter cardParameters: User bank card parameters.
    /// - parameter delegate: Delegate. Responds to CourseNotEnoughMoneyDelegate.
    ///
    func showCourseNotEnoughMoneyViewController(withAuthorisedUserModel userModel: AuthorisedUserModel, notEnoughAmount: Double, cardParameters: [String:Any], delegate: CourseNotEnoughMoneyDelegate)
    
    /// Shows OtherProfileViewController.
    ///
    /// - parameter userModel: Model of the authorised user.
    /// - parameter userID: User ID to show profile.
    ///
    func showOtherProfileViewController(withAuthorisedUserModel userModel: AuthorisedUserModel, userID: String)
    
}

protocol ScheduleRouterInput {
    
    /// Shows SessionPageViewController.
    ///
    /// - parameter userModel: Model of the authorised user.
    /// - parameter sessionModel: Course session model.
    /// - parameter course: Course model.
    ///
    func showFuturePastSessionScreen(withAuthorisedUserModel userModel: AuthorisedUserModel?, sessionModel: CourseSessionModel, courseModel: CourseModel?)
    
    /// Shows VideoStreamViewController.
    ///
    /// - parameter userModel: Model of the authorised user.
    /// - parameter sessionModel: Course session model.
    /// - parameter sessionOwner: Determines if user owns the session.
    ///
    func showVideoStreamViewController(withAuthorisedUserModel userModel: AuthorisedUserModel, sessionModel: CourseSessionModel, sessionOwner: Bool)
    
    /// Shows FinishedStreamViewController.
    ///
    /// - parameter userModel: Model of the authorised user.
    /// - parameter streamInfoModel: Stream info model.
    /// - parameter sessionOwner: Determines if user owns the session.
    ///
    func showFinishStreamViewController(withAuthorisedUserModel userModel: AuthorisedUserModel, streamInfoModel: StreamInfoModel, sessionOwner: Bool)
    
    /// Shows SessionAttachmentViewController.
    ///
    /// - parameter userModel: Model of the authorised user.
    /// - parameter attachmentModel: Course attachment model.
    ///
    func showSessionAttachmentViewController(withAuthorisedUserModel userModel: AuthorisedUserModel, attachmentModel: CourseAttachmentModel)
    
}

protocol SettingsRouterInput {
    
    /// Shows CreditsViewController.
    ///
    /// - parameter userModel: Model of the authorised user.
    ///
    func showCreditsViewController(withAuthorisedUserModel userModel: AuthorisedUserModel)
    
    /// Shows WithdrawalCardViewController.
    ///
    /// - parameter userModel: Model of the authorised user.
    /// - parameter currentBalance: Default credits amount to withdraw.
    /// - parameter delegate: Delegate. Responds to WithdrawalCardDelegate.
    ///
    func showWithdrawalCardViewController(withAuthorisedUserModel userModel: AuthorisedUserModel, currentBalance: String?, delegate: WithdrawalCardDelegate)
    
    /// Shows EditProfileViewController.
    ///
    /// - parameter userModel: Model of the authorised user.
    ///
    func showEditProfileViewController(withAuthorisedUserModel userModel: AuthorisedUserModel)
    
}
