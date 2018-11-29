//
//  TroovyRouter.swift
//  troovy-ios
//
//  Created by Daniil on 11.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class TroovyRouter: NSObject, TroovyRouterInput, TroovyRouterOptionalInput {
    
    private enum RouterShowViewControllerType {
        case push
        case present
        case child
    }
    
    private enum RouterError: Error {
        case showFailed(sourceViewController: UIViewController?, targetViewController: UINavigationController?)
        case methodFailed(router: TroovyRouter, methodName: String)
    }
    
    // MARK: Internal Properties
    
    /// Router showed by this router will be his child router.
    internal var childRouter: TroovyRouter?
    
    /// Router showing by this router will be his parent router.
    internal private(set) weak var parentRouter: TroovyRouter?
    
    /// Each router must have a root navigation controller. All view controllers will be pushed and presented using it.
    internal var rootNavigationController: UINavigationController?
    
    // MARK: Init Methods & Superclass Overriders
    
    override init() {
        super.init()
    }
    
    /// Initialises router with parent router.
    ///
    /// - parameter parentRouter: Router which is showing this router.
    ///
    convenience init(parentRouter: TroovyRouter) {
        self.init()
        
        self.parentRouter = parentRouter
    }
    
    // MARK: Public Methods
    
    func presentedViewController() -> UIViewController? {
        return self.lastChildRouter().rootNavigationController?.presentedViewController
    }
    
    func topPresentedViewContoller(forController targetController: UIViewController?) -> UIViewController? {
        guard let controller = targetController else {
            return nil
        }
        
        if let presentedViewController = controller.presentedViewController {
            return self.topPresentedViewContoller(forController: presentedViewController)
        }
        
        if let navigationController = controller as? UINavigationController {
            return navigationController
        }
        
        if let navigationController = controller.navigationController {
            return navigationController
        }
        
        return controller
    }
    
    // MARK: Internal Methods
    
    /// Pushes view controller to router's root navigation controller.
    /// Calls methods in the main thread if needed. Print error if occurs.
    ///
    /// - parameter viewController: View controller to be pushed.
    ///
    internal func push(viewController: UIViewController?) {
        if Thread.isMainThread {
            self.showAndHandleErrors(viewController: viewController, showingType: .push, animated: true, completion: nil)
        } else {
            DispatchQueue.main.async {
                self.showAndHandleErrors(viewController: viewController, showingType: .push, animated: true, completion: nil)
            }
        }
    }
    
    /// Presents view controller on router's root navigation controller.
    /// Calls methods in the main thread if needed. Print error if occurs.
    ///
    /// - parameter viewController: View controller to be presented.
    ///
    internal func present(viewController: UIViewController?) {
        if Thread.isMainThread {
            self.showAndHandleErrors(viewController: viewController, showingType: .present, animated: true, completion: nil)
        } else {
            DispatchQueue.main.async {
                self.showAndHandleErrors(viewController: viewController, showingType: .present, animated: true, completion: nil)
            }
        }
    }
    
    internal func show(viewController: UIViewController?) {
        if Thread.isMainThread {
            self.showAndHandleErrors(viewController: viewController, showingType: .child, animated: true, completion: nil)
        } else {
            DispatchQueue.main.async {
                self.showAndHandleErrors(viewController: viewController, showingType: .child, animated: true, completion: nil)
            }
        }
    }
    
    /// Presents view controller on router's root navigation controller.
    /// Calls methods in the main thread if needed. Print error if occurs.
    ///
    /// - parameter viewController: View controller to be presented.
    /// - parameter completion: Presentation completion block.
    ///
    internal func present(viewController: UIViewController?, completion: (() -> ())?) {
        if Thread.isMainThread {
            self.showAndHandleErrors(viewController: viewController, showingType: .present, animated: true, completion: completion)
        } else {
            DispatchQueue.main.async {
                self.showAndHandleErrors(viewController: viewController, showingType: .present, animated: true, completion: completion)
            }
        }
    }
    
    /// Presents view controller on router's root navigation controller.
    /// Calls methods in the main thread if needed. Print error if occurs.
    ///
    /// - parameter viewController: View controller to be presented.
    /// - parameter aniamted: Determines if animation is acceptable.
    /// - parameter completion: Presentation completion block.
    ///
    internal func present(viewController: UIViewController?, animated: Bool, completion: (() -> ())?) {
        if Thread.isMainThread {
            self.showAndHandleErrors(viewController: viewController, showingType: .present, animated: animated, completion: completion)
        } else {
            DispatchQueue.main.async {
                self.showAndHandleErrors(viewController: viewController, showingType: .present, animated: animated, completion: completion)
            }
        }
    }
    
    /// Initializes view controller from the storyboard. Print error if occurs.
    ///
    /// - parameter storyboardID: Storyboard ID of the view controller.
    ///
    internal func createViewControllerAndHandleErrors(withStoryboardID storyboardID: String) -> UIViewController? {
        do {
            let viewController = try TroovyViewController.create(fromStoryboardWithStoryboardID: storyboardID, router: self.lastChildRouter())
            return viewController
        } catch  {
            fatalError("Error creating view controller: \(error)")
        }
        
        return nil
    }
    
    /// Goes through the child routers chain and gets last one.
    ///
    /// - returns: Gets last child router.
    ///
    internal func lastChildRouter() -> TroovyRouter {
        var selectedRouter = self
        while selectedRouter.childRouter != nil {
            selectedRouter = selectedRouter.childRouter!
        }
        return selectedRouter
    }
    
    // MARK: Private Methods
    
    // MARK: Show View Controllers
    
    private func showAndHandleErrors(viewController: UIViewController?, showingType: RouterShowViewControllerType, animated: Bool, completion: (() -> ())?) {
        do {
            try self.show(viewController: viewController, showingType: showingType, animated: animated, completion: completion)
        } catch  {
            fatalError("Error showing view controller: \(error)")
        }
    }
    
    private func show(viewController: UIViewController?, showingType: RouterShowViewControllerType, animated: Bool, completion: (() -> ())?) throws {
        guard let targetViewController = self.lastChildRouter().rootNavigationController, let sourceViewController = viewController else {
            throw(RouterError.showFailed(sourceViewController: viewController, targetViewController: self.rootNavigationController))
        }
        
        switch showingType {
        case .push:
            if let presentedNavigationController = self.topPresentedViewContoller(forController: targetViewController) as? UINavigationController {
                presentedNavigationController.pushViewController(sourceViewController, animated: animated)
            } else {
                targetViewController.pushViewController(sourceViewController, animated: animated)
            }
            break
            
        case .present:
            if let presentedViewController = self.topPresentedViewContoller(forController: targetViewController) {
                if let presentedNavigationController = presentedViewController.navigationController {
                    presentedNavigationController.present(sourceViewController, animated: animated, completion: completion)
                } else {
                    presentedViewController.present(sourceViewController, animated: animated, completion: completion)
                }
            } else {
                targetViewController.present(sourceViewController, animated: animated, completion: completion)
            }
            break
            
        case .child:
            var parentViewController: UIViewController?
            if let presentedViewController = self.topPresentedViewContoller(forController: targetViewController) {
                if let lastViewController = presentedViewController.navigationController?.viewControllers.last {
                    parentViewController = lastViewController
                } else {
                    parentViewController = presentedViewController
                }
            } else {
                parentViewController = targetViewController
            }
            
            if let controller = parentViewController {
                controller.addChildViewController(sourceViewController)
                sourceViewController.beginAppearanceTransition(true, animated: animated)
                sourceViewController.view.translatesAutoresizingMaskIntoConstraints = false
                controller.view.addSubview(sourceViewController.view)
                sourceViewController.endAppearanceTransition()
                sourceViewController.didMove(toParentViewController: controller)
                
                let left = sourceViewController.view.leftAnchor.constraint(equalTo: controller.view.leftAnchor)
                let right = sourceViewController.view.rightAnchor.constraint(equalTo: controller.view.rightAnchor)
                let top = sourceViewController.view.topAnchor.constraint(equalTo: controller.view.topAnchor)
                let bottom = sourceViewController.view.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor)
                
                let constraints = [left, right, top, bottom]
                NSLayoutConstraint.activate(constraints)
            }
            break
        }
    }
    
    // MARK: Protocols Implementation
    
    // MARK: TroovyRouterOptionalInput
    
    internal func optionalViewControllerInited(viewController: UIViewController) throws {
        throw(RouterError.methodFailed(router: self, methodName: "optionalViewControllerInited"))
    }
    
    internal func optionalShowTutorialViewController() throws {
        throw(RouterError.methodFailed(router: self, methodName: "optionalShowTutorialViewController"))
    }

    internal func optionalShowUnauthorisedViewController() throws {
        throw(RouterError.methodFailed(router: self, methodName: "optionalShowUnauthorisedViewController"))
    }
    
    internal func optionalShowAuthorisedViewController(withAuthorisedUserModel model: AuthorisedUserModel) throws {
        throw(RouterError.methodFailed(router: self, methodName: "optionalShowAuthorisedViewController(withAuthorisedUserModel:)"))
    }
    
    internal func optionalShowUserVerificationViewController(withUnauthorisedUserModel model: UnauthorisedUserModel) throws {
        throw(RouterError.methodFailed(router: self, methodName: "optionalShowUserVerificationViewController(withUnauthorisedUserModel:)"))
    }
    
    internal func optionalShowRegistrationViewController(withUnauthorisedUserModel model: UnauthorisedUserModel) throws {
        throw(RouterError.methodFailed(router: self, methodName: "optionalShowRegistrationViewController(withUnauthorisedUserModel:)"))
    }
    
    internal func optionalTakeProfilePictureFromCamera(withDelegate delegate: (UIImagePickerControllerDelegate & UINavigationControllerDelegate), completion: (() -> ())?) throws {
        throw(RouterError.methodFailed(router: self, methodName: "optionalTakeProfilePictureFromCamera(withDelegate:completion:)"))
    }
    
    internal func optionalTakeProfilePictureFromCameraRoll(withDelegate delegate: (UIImagePickerControllerDelegate & UINavigationControllerDelegate), completion: (() -> ())?) throws {
        throw(RouterError.methodFailed(router: self, methodName: "optionalTakeProfilePictureFromCameraRoll(withDelegate:completion:)"))
    }
    
    internal func optionalChangeChildRouter(withNew childRouter: TroovyRouter) throws {
        throw(RouterError.methodFailed(router: self, methodName: "optionalChangeChildRouter(withNew:)"))
    }
    
    internal func optionalShowCreateCourseMainInfoScreen(withAuthorisedUserModel userModel: AuthorisedUserModel, courseModel: UnfinishedCourseModel?) throws {
        throw(RouterError.methodFailed(router: self, methodName: "optionalShowCreateCourseMainInfoScreen(withAuthorisedUserModel:courseModel:)"))
    }
    
    internal func optionalShowCourseSessionScreen(withAuthorisedUserModel userModel: AuthorisedUserModel?, sessionModel: CourseSessionModel?, courseSessionAlwaysEditable: Bool, delegate: CreateSessionDelegate?) throws {
        throw(RouterError.methodFailed(router: self, methodName: "optionalShowCourseSessionScreen(withAuthorisedUserModel:sessionModel:courseSessionAlwaysEditable:delegate:)"))
    }
    
    internal func optionalShowOwnCourseScreen(withAuthorisedUserModel userModel: AuthorisedUserModel, courseModel: CourseModel) throws {
        throw(RouterError.methodFailed(router: self, methodName: "optionalShowOwnCourseScreen(withAuthorisedUserModel:courseModel:)"))
    }
    
    internal func optionalShowCommonCourseScreen(withAuthorisedUserModel userModel: AuthorisedUserModel?, courseModel: CourseModel?, courseID: String) throws {
        throw(RouterError.methodFailed(router: self, methodName: "optionalShowCommonCourseScreen(withAuthorisedUserModel:courseModel:courseID:)"))
    }
    
    internal func optionalShowVideo(withVideoURL videoURL: URL) throws {
        throw(RouterError.methodFailed(router: self, methodName: "optionalShowVideo(withVideoURL:)"))
    }
    
    internal func optionalShowCourseImage(withImage image: UIImage) throws {
        throw(RouterError.methodFailed(router: self, methodName: "optionalShowCourseImage(withImage:)"))
    }
    
    internal func optionalShowCourseSessionsScreen(withAuthorisedUserModel userModel: AuthorisedUserModel?, courseModel: CourseModel, changePossible: Bool) throws {
        throw(RouterError.methodFailed(router: self, methodName: "optionalShowCourseSessionsScreen(withAuthorisedUserModel:courseModel:changePossible:)"))
    }
    
    internal func optionalShowCourseAttachmentsScreen(withAuthorisedUserModel userModel: AuthorisedUserModel?, courseModel: CourseModel) throws {
        throw(RouterError.methodFailed(router: self, methodName: "optionalShowCourseAttachmentsScreen(withAuthorisedUserModel:courseModel:)"))
    }
    
    internal func optionalShowEditCourseScreen(withAuthorisedUserModel userModel: AuthorisedUserModel, courseModel: CourseModel) throws {
        throw(RouterError.methodFailed(router: self, methodName: "optionalShowEditCourseScreen(withAuthorisedUserModel:courseModel:)"))
    }
    
    internal func optionalShowUploadAttachmentScreen(withAuthorisedUserModel userModel: AuthorisedUserModel, courseModel: CourseModel, attachmentModel: CourseAttachmentModel) throws {
        throw(RouterError.methodFailed(router: self, methodName: "optionalShowUploadAttachmentScreen(withAuthorisedUserModel:courseModel:attachmentModel:)"))
    }
    
    internal func optionalShowUploadCourseIntroScreen(withAuthorisedUserModel userModel: AuthorisedUserModel, courseModel: CourseModel, introFilePath: String, courseCreation: Bool, unfinishedCourseModel: UnfinishedCourseModel) throws {
        throw(RouterError.methodFailed(router: self, methodName: "optionalShowUploadCourseIntroScreen(withAuthorisedUserModel:courseModel:introFilePath:courseCreation:unfinishedCourseModel:)"))
    }
    
    internal func optionalTakeCoursePreviewFromCamera(withDelegate delegate: (UIImagePickerControllerDelegate & UINavigationControllerDelegate), completion: (() -> ())?) throws {
        throw(RouterError.methodFailed(router: self, methodName: "optionalTakeCoursePreviewFromCamera(delegate:completion:)"))
    }
    
    internal func optionalTakeCoursePreviewFromCameraRoll(withDidSelect didSelect: ((_ assets: [DKAsset]) -> Void)?, maxSelectableCount: Int, completion: (() -> ())?) throws {
        throw(RouterError.methodFailed(router: self, methodName: "optionalTakeCoursePreviewFromCameraRoll(withDidSelect:maxSelectableCount:completion:)"))
    }
    
    internal func optionalTakeCourseAttachmentFromCameraRoll(withDelegate delegate: (UIImagePickerControllerDelegate & UINavigationControllerDelegate), completion: (() -> ())?) throws {
        throw(RouterError.methodFailed(router: self, methodName: "optionalTakeCourseAttachmentFromCameraRoll(withDelegate:completion:)"))
    }
    
    internal func optionalShowReportCourseScreen(withAuthorisedUserModel userModel: AuthorisedUserModel, courseID: String) throws {
        throw(RouterError.methodFailed(router: self, methodName: "optionalShowReportCourseScreen(withAuthorisedUserModel:courseID:)"))
    }
    
    internal func optionalShowBuyCourseScreen(withAuthorisedUserModel userModel: AuthorisedUserModel, course: CourseModel) throws {
        throw(RouterError.methodFailed(router: self, methodName: "optionalShowBuyCourseScreen(withAuthorisedUserModel:course:)"))
    }
    
    internal func optionalShowCourseNotEnoughMoneyViewController(withAuthorisedUserModel userModel: AuthorisedUserModel, notEnoughAmount: Double, cardParameters: [String:Any], delegate: CourseNotEnoughMoneyDelegate) throws {
        throw(RouterError.methodFailed(router: self, methodName: "optionalShowCourseNotEnoughMoneyViewController(withAuthorisedUserModel:notEnoughAmount:cardParameters:delegate:)"))
    }
    
    internal func optionalShowOtherProfileViewController(withAuthorisedUserModel userModel: AuthorisedUserModel, userID: String) throws {
        throw(RouterError.methodFailed(router: self, methodName: "optionalShowOtherProfileViewController(withAuthorisedUserModel:userID:)"))
    }
    
    internal func optionalShowFuturePastSessionScreen(withAuthorisedUserModel userModel: AuthorisedUserModel?, sessionModel: CourseSessionModel, courseModel: CourseModel?) throws {
        throw(RouterError.methodFailed(router: self, methodName: "optionalShowFuturePastSessionScreen(withAuthorisedUserModel:sessionModel:courseModel:)"))
    }
    
    internal func optionalShowVideoStreamViewController(withAuthorisedUserModel userModel: AuthorisedUserModel, sessionModel: CourseSessionModel, sessionOwner: Bool) throws {
        throw(RouterError.methodFailed(router: self, methodName: "optionalShowVideoStreamViewController(withAuthorisedUserModel:sessionModel:sessionOwner:)"))
    }
    
    internal func optionalShowFinishStreamViewController(withAuthorisedUserModel userModel: AuthorisedUserModel, streamInfoModel: StreamInfoModel, sessionOwner: Bool) throws {
        throw(RouterError.methodFailed(router: self, methodName: "optionalShowFinishStreamViewController(withAuthorisedUserModel:streamInfoModel:sessionOwner:)"))
    }
    
    internal func optionalShowSessionAttachmentViewController(withAuthorisedUserModel userModel: AuthorisedUserModel, attachmentModel: CourseAttachmentModel) throws {
        throw(RouterError.methodFailed(router: self, methodName: "optionalShowSessionAttachmentViewController(withAuthorisedUserModel:attachmentModel:)"))
    }
    
    internal func optionalShowCreditsViewController(withAuthorisedUserModel userModel: AuthorisedUserModel) throws {
        throw(RouterError.methodFailed(router: self, methodName: "optionalShowCreditsViewController(withAuthorisedUserModel:)"))
    }
    
    internal func optionalShowWithdrawalCardViewController(withAuthorisedUserModel userModel: AuthorisedUserModel, currentBalance: String?, delegate: WithdrawalCardDelegate) throws {
        throw(RouterError.methodFailed(router: self, methodName: "optionalShowWithdrawalCardViewController(withAuthorisedUserModel:currentBalance:delegate:)"))
    }
    
    internal func optionalShowEditProfileViewController(withAuthorisedUserModel userModel: AuthorisedUserModel) throws {
        throw(RouterError.methodFailed(router: self, methodName: "optionalShowEditProfileViewController(withAuthorisedUserModel:)"))
    }
    
    internal func optionalShowScheduleScreen() throws {
        throw(RouterError.methodFailed(router: self, methodName: "optionalShowScheduleScreen()"))
    }
    
    // MARK: TroovyRouterInput
    
    internal func viewControllerInited(viewController: UIViewController) {
        do {
            try self.optionalViewControllerInited(viewController: viewController)
        } catch {
            if let parentRouter = self.parentRouter {
                parentRouter.viewControllerInited(viewController: viewController)
            } else {
                fatalError("Error performing protocol method: \(error)")
            }
        }
    }
    
    internal func routerShouldRelease() {
        self.parentRouter?.childRouter = nil
        self.parentRouter = nil
    }
    
    // MARK: LaunchRouterInput
    
    internal func showTutorialViewController() {
        do {
            try self.optionalShowTutorialViewController()
        } catch {
            if let parentRouter = self.parentRouter {
                parentRouter.showTutorialViewController()
            } else {
                fatalError("Error performing protocol method: \(error)")
            }
        }
    }
    
    internal func showUnauthorisedViewController() {
        do {
            try self.optionalShowUnauthorisedViewController()
        } catch {
            if let parentRouter = self.parentRouter {
                parentRouter.showUnauthorisedViewController()
            } else {
                fatalError("Error performing protocol method: \(error)")
            }
        }
    }
    
    internal func showAuthorisedViewController(withAuthorisedUserModel model: AuthorisedUserModel) {
        do {
            try self.optionalShowAuthorisedViewController(withAuthorisedUserModel: model)
        } catch {
            if let parentRouter = self.parentRouter {
                parentRouter.showAuthorisedViewController(withAuthorisedUserModel: model)
            } else {
                fatalError("Error performing protocol method: \(error)")
            }
        }
    }
    
    // MARK: UnauthorisedRouterInput
    
    internal func showUserVerificationViewController(withUnauthorisedUserModel model: UnauthorisedUserModel) {
        do {
            try self.optionalShowUserVerificationViewController(withUnauthorisedUserModel: model)
        } catch {
            if let parentRouter = self.parentRouter {
                parentRouter.showUserVerificationViewController(withUnauthorisedUserModel: model)
            } else {
                fatalError("Error performing protocol method: \(error)")
            }
        }
    }
    
    internal func showRegistrationViewController(withUnauthorisedUserModel model: UnauthorisedUserModel) {
        do {
            try self.optionalShowRegistrationViewController(withUnauthorisedUserModel: model)
        } catch {
            if let parentRouter = self.parentRouter {
                parentRouter.showRegistrationViewController(withUnauthorisedUserModel: model)
            } else {
                fatalError("Error performing protocol method: \(error)")
            }
        }
    }
    
    internal func takeProfilePictureFromCamera(withDelegate delegate: (UIImagePickerControllerDelegate & UINavigationControllerDelegate), completion: (() -> ())?) {
        do {
            try self.optionalTakeProfilePictureFromCamera(withDelegate: delegate, completion: completion)
        } catch {
            if let parentRouter = self.parentRouter {
                parentRouter.takeProfilePictureFromCamera(withDelegate: delegate, completion: completion)
            } else {
                fatalError("Error performing protocol method: \(error)")
            }
        }
    }
    
    internal func takeProfilePictureFromCameraRoll(withDelegate delegate: (UIImagePickerControllerDelegate & UINavigationControllerDelegate), completion: (() -> ())?) {
        do {
            try self.optionalTakeProfilePictureFromCameraRoll(withDelegate: delegate, completion: completion)
        } catch {
            if let parentRouter = self.parentRouter {
                parentRouter.takeProfilePictureFromCameraRoll(withDelegate: delegate, completion: completion)
            } else {
                fatalError("Error performing protocol method: \(error)")
            }
        }
    }
    
    // MARK: AuthorisedRouterInput
    
    internal func changeChildRouter(withNew childRouter: TroovyRouter) {
        do {
            try self.optionalChangeChildRouter(withNew: childRouter)
        } catch {
            if let parentRouter = self.parentRouter {
                parentRouter.changeChildRouter(withNew: childRouter)
            } else {
                fatalError("Error performing protocol method: \(error)")
            }
        }
    }
    
    internal func showScheduleScreen() {
        do {
            try self.optionalShowScheduleScreen()
        } catch {
            if let parentRouter = self.parentRouter {
                parentRouter.showScheduleScreen()
            } else {
                fatalError("Error performing protocol method: \(error)")
            }
        }
    }
    
    // MARK: CoursesRouterInput
    
    internal func showCreateCourseMainInfoScreen(withAuthorisedUserModel userModel: AuthorisedUserModel, courseModel: UnfinishedCourseModel?) {
        do {
            try self.optionalShowCreateCourseMainInfoScreen(withAuthorisedUserModel: userModel, courseModel: courseModel)
        } catch {
            if let parentRouter = self.parentRouter {
                parentRouter.showCreateCourseMainInfoScreen(withAuthorisedUserModel: userModel, courseModel: courseModel)
            } else {
                fatalError("Error performing protocol method: \(error)")
            }
        }
    }
    
    internal func showCourseSessionScreen(withAuthorisedUserModel userModel: AuthorisedUserModel?, sessionModel: CourseSessionModel?, courseSessionAlwaysEditable: Bool, delegate: CreateSessionDelegate?) {
        do {
            try self.optionalShowCourseSessionScreen(withAuthorisedUserModel: userModel, sessionModel: sessionModel, courseSessionAlwaysEditable: courseSessionAlwaysEditable, delegate: delegate)
        } catch {
            if let parentRouter = self.parentRouter {
                parentRouter.showCourseSessionScreen(withAuthorisedUserModel: userModel, sessionModel: sessionModel, courseSessionAlwaysEditable: courseSessionAlwaysEditable, delegate: delegate)
            } else {
                fatalError("Error performing protocol method: \(error)")
            }
        }
    }
    
    internal func showOwnCourseScreen(withAuthorisedUserModel userModel: AuthorisedUserModel, courseModel: CourseModel) {
        do {
            try self.optionalShowOwnCourseScreen(withAuthorisedUserModel: userModel, courseModel: courseModel)
        } catch {
            if let parentRouter = self.parentRouter {
                parentRouter.showOwnCourseScreen(withAuthorisedUserModel: userModel, courseModel: courseModel)
            } else {
                fatalError("Error performing protocol method: \(error)")
            }
        }
    }
    
    internal func showCommonCourseScreen(withAuthorisedUserModel userModel: AuthorisedUserModel?, courseModel: CourseModel?, courseID: String) {
        do {
            try self.optionalShowCommonCourseScreen(withAuthorisedUserModel: userModel, courseModel: courseModel, courseID: courseID)
        } catch {
            if let parentRouter = self.parentRouter {
                parentRouter.showCommonCourseScreen(withAuthorisedUserModel: userModel, courseModel: courseModel, courseID: courseID)
            } else {
                fatalError("Error performing protocol method: \(error)")
            }
        }
    }
    
    internal func showVideo(withVideoURL videoURL: URL) {
        do {
            try self.optionalShowVideo(withVideoURL: videoURL)
        } catch {
            if let parentRouter = self.parentRouter {
                parentRouter.showVideo(withVideoURL: videoURL)
            } else {
                fatalError("Error performing protocol method: \(error)")
            }
        }
    }
    
    internal func showCourseImage(withImage image: UIImage) {
        do {
            try self.optionalShowCourseImage(withImage: image)
        } catch {
            if let parentRouter = self.parentRouter {
                parentRouter.showCourseImage(withImage: image)
            } else {
                fatalError("Error performing protocol method: \(error)")
            }
        }
    }
    
    internal func showCourseSessionsScreen(withAuthorisedUserModel userModel: AuthorisedUserModel?, courseModel: CourseModel, changePossible: Bool) {
        do {
            try self.optionalShowCourseSessionsScreen(withAuthorisedUserModel: userModel, courseModel: courseModel, changePossible: changePossible)
        } catch {
            if let parentRouter = self.parentRouter {
                parentRouter.showCourseSessionsScreen(withAuthorisedUserModel: userModel, courseModel: courseModel, changePossible: changePossible)
            } else {
                fatalError("Error performing protocol method: \(error)")
            }
        }
    }
    
    internal func showCourseAttachmentsScreen(withAuthorisedUserModel userModel: AuthorisedUserModel?, courseModel: CourseModel) {
        do {
            try self.optionalShowCourseAttachmentsScreen(withAuthorisedUserModel: userModel, courseModel: courseModel)
        } catch {
            if let parentRouter = self.parentRouter {
                parentRouter.showCourseAttachmentsScreen(withAuthorisedUserModel: userModel, courseModel: courseModel)
            } else {
                fatalError("Error performing protocol method: \(error)")
            }
        }
    }
    
    internal func showEditCourseScreen(withAuthorisedUserModel userModel: AuthorisedUserModel, courseModel: CourseModel) {
        do {
            try self.optionalShowEditCourseScreen(withAuthorisedUserModel: userModel, courseModel: courseModel)
        } catch {
            if let parentRouter = self.parentRouter {
                parentRouter.showEditCourseScreen(withAuthorisedUserModel: userModel, courseModel: courseModel)
            } else {
                fatalError("Error performing protocol method: \(error)")
            }
        }
    }
    
    internal func showUploadAttachmentScreen(withAuthorisedUserModel userModel: AuthorisedUserModel, courseModel: CourseModel, attachmentModel: CourseAttachmentModel) {
        do {
            try self.optionalShowUploadAttachmentScreen(withAuthorisedUserModel: userModel, courseModel: courseModel, attachmentModel: attachmentModel)
        } catch {
            if let parentRouter = self.parentRouter {
                parentRouter.showUploadAttachmentScreen(withAuthorisedUserModel: userModel, courseModel: courseModel, attachmentModel: attachmentModel)
            } else {
                fatalError("Error performing protocol method: \(error)")
            }
        }
    }
    
    internal func showUploadCourseIntroScreen(withAuthorisedUserModel userModel: AuthorisedUserModel, courseModel: CourseModel, introFilePath: String, courseCreation: Bool, unfinishedCourseModel: UnfinishedCourseModel) {
        do {
            try self.optionalShowUploadCourseIntroScreen(withAuthorisedUserModel: userModel, courseModel: courseModel, introFilePath: introFilePath, courseCreation: courseCreation, unfinishedCourseModel: unfinishedCourseModel)
        } catch {
            if let parentRouter = self.parentRouter {
                parentRouter.showUploadCourseIntroScreen(withAuthorisedUserModel: userModel, courseModel: courseModel, introFilePath: introFilePath, courseCreation: courseCreation, unfinishedCourseModel: unfinishedCourseModel)
            } else {
                fatalError("Error performing protocol method: \(error)")
            }
        }
    }
    
    internal func takeCoursePreviewFromCamera(withDelegate delegate: (UIImagePickerControllerDelegate & UINavigationControllerDelegate), completion: (() -> ())?) {
        do {
            try self.optionalTakeCoursePreviewFromCamera(withDelegate: delegate, completion: completion)
        } catch {
            if let parentRouter = self.parentRouter {
                parentRouter.takeCoursePreviewFromCamera(withDelegate: delegate, completion: completion)
            } else {
                fatalError("Error performing protocol method: \(error)")
            }
        }
    }
    
    internal func takeCoursePreviewFromCameraRoll(withDidSelect didSelect: ((_ assets: [DKAsset]) -> Void)?, maxSelectableCount: Int, completion: (() -> ())?) {
        do {
            try self.optionalTakeCoursePreviewFromCameraRoll(withDidSelect: didSelect, maxSelectableCount: maxSelectableCount, completion: completion)
        } catch {
            if let parentRouter = self.parentRouter {
                parentRouter.takeCoursePreviewFromCameraRoll(withDidSelect: didSelect, maxSelectableCount: maxSelectableCount, completion: completion)
            } else {
                fatalError("Error performing protocol method: \(error)")
            }
        }
    }
    
    internal func takeCourseAttachmentFromCameraRoll(withDelegate delegate: (UIImagePickerControllerDelegate & UINavigationControllerDelegate), completion: (() -> ())?) {
        do {
            try self.optionalTakeCourseAttachmentFromCameraRoll(withDelegate: delegate, completion: completion)
        } catch {
            if let parentRouter = self.parentRouter {
                parentRouter.takeCourseAttachmentFromCameraRoll(withDelegate: delegate, completion: completion)
            } else {
                fatalError("Error performing protocol method: \(error)")
            }
        }
    }
    
    internal func showReportCourseScreen(withAuthorisedUserModel userModel: AuthorisedUserModel, courseID: String) {
        do {
            try self.optionalShowReportCourseScreen(withAuthorisedUserModel: userModel, courseID: courseID)
        } catch {
            if let parentRouter = self.parentRouter {
                parentRouter.showReportCourseScreen(withAuthorisedUserModel: userModel, courseID: courseID)
            } else {
                fatalError("Error performing protocol method: \(error)")
            }
        }
    }
    
    internal func showBuyCourseScreen(withAuthorisedUserModel userModel: AuthorisedUserModel, course: CourseModel) {
        do {
            try self.optionalShowBuyCourseScreen(withAuthorisedUserModel: userModel, course: course)
        } catch {
            if let parentRouter = self.parentRouter {
                parentRouter.showBuyCourseScreen(withAuthorisedUserModel: userModel, course: course)
            } else {
                fatalError("Error performing protocol method: \(error)")
            }
        }
    }
    
    internal func showCourseNotEnoughMoneyViewController(withAuthorisedUserModel userModel: AuthorisedUserModel, notEnoughAmount: Double, cardParameters: [String:Any], delegate: CourseNotEnoughMoneyDelegate) {
        do {
            try self.optionalShowCourseNotEnoughMoneyViewController(withAuthorisedUserModel: userModel, notEnoughAmount: notEnoughAmount, cardParameters: cardParameters, delegate: delegate)
        } catch {
            if let parentRouter = self.parentRouter {
                parentRouter.showCourseNotEnoughMoneyViewController(withAuthorisedUserModel: userModel, notEnoughAmount: notEnoughAmount, cardParameters: cardParameters, delegate: delegate)
            } else {
                fatalError("Error performing protocol method: \(error)")
            }
        }
    }
    
    internal func showOtherProfileViewController(withAuthorisedUserModel userModel: AuthorisedUserModel, userID: String) {
        do {
            try self.optionalShowOtherProfileViewController(withAuthorisedUserModel: userModel, userID: userID)
        } catch {
            if let parentRouter = self.parentRouter {
                parentRouter.showOtherProfileViewController(withAuthorisedUserModel: userModel, userID: userID)
            } else {
                fatalError("Error performing protocol method: \(error)")
            }
        }
    }
    
    // MARK: ScheduleRouterInput
    
    internal func showFuturePastSessionScreen(withAuthorisedUserModel userModel: AuthorisedUserModel?, sessionModel: CourseSessionModel, courseModel: CourseModel?) {
        do {
            try self.optionalShowFuturePastSessionScreen(withAuthorisedUserModel: userModel, sessionModel: sessionModel, courseModel: courseModel)
        } catch {
            if let parentRouter = self.parentRouter {
                parentRouter.showFuturePastSessionScreen(withAuthorisedUserModel: userModel, sessionModel: sessionModel, courseModel: courseModel)
            } else {
                fatalError("Error performing protocol method: \(error)")
            }
        }
    }
    
    internal func showVideoStreamViewController(withAuthorisedUserModel userModel: AuthorisedUserModel, sessionModel: CourseSessionModel, sessionOwner: Bool) {
        do {
            try self.optionalShowVideoStreamViewController(withAuthorisedUserModel: userModel, sessionModel: sessionModel, sessionOwner: sessionOwner)
        } catch {
            if let parentRouter = self.parentRouter {
                parentRouter.showVideoStreamViewController(withAuthorisedUserModel: userModel, sessionModel: sessionModel, sessionOwner: sessionOwner)
            } else {
                fatalError("Error performing protocol method: \(error)")
            }
        }
    }
    
    internal func showFinishStreamViewController(withAuthorisedUserModel userModel: AuthorisedUserModel, streamInfoModel: StreamInfoModel, sessionOwner: Bool) {
        do {
            try self.optionalShowFinishStreamViewController(withAuthorisedUserModel: userModel, streamInfoModel: streamInfoModel, sessionOwner: sessionOwner)
        } catch {
            if let parentRouter = self.parentRouter {
                parentRouter.showFinishStreamViewController(withAuthorisedUserModel: userModel, streamInfoModel: streamInfoModel, sessionOwner: sessionOwner)
            } else {
                fatalError("Error performing protocol method: \(error)")
            }
        }
    }
    
    internal func showSessionAttachmentViewController(withAuthorisedUserModel userModel: AuthorisedUserModel, attachmentModel: CourseAttachmentModel) {
        do {
            try self.optionalShowSessionAttachmentViewController(withAuthorisedUserModel: userModel, attachmentModel: attachmentModel)
        } catch {
            if let parentRouter = self.parentRouter {
                parentRouter.showSessionAttachmentViewController(withAuthorisedUserModel: userModel, attachmentModel: attachmentModel)
            } else {
                fatalError("Error performing protocol method: \(error)")
            }
        }
    }
    
    // MARK: SettingsRouterInput
    
    internal func showCreditsViewController(withAuthorisedUserModel userModel: AuthorisedUserModel) {
        do {
            try self.optionalShowCreditsViewController(withAuthorisedUserModel: userModel)
        } catch {
            if let parentRouter = self.parentRouter {
                parentRouter.showCreditsViewController(withAuthorisedUserModel: userModel)
            } else {
                fatalError("Error performing protocol method: \(error)")
            }
        }
    }
    
    internal func showWithdrawalCardViewController(withAuthorisedUserModel userModel: AuthorisedUserModel, currentBalance: String?, delegate: WithdrawalCardDelegate) {
        do {
            try self.optionalShowWithdrawalCardViewController(withAuthorisedUserModel: userModel, currentBalance: currentBalance, delegate: delegate)
        } catch {
            if let parentRouter = self.parentRouter {
                parentRouter.showWithdrawalCardViewController(withAuthorisedUserModel: userModel, currentBalance: currentBalance, delegate: delegate)
            } else {
                fatalError("Error performing protocol method: \(error)")
            }
        }
    }
    
    internal func showEditProfileViewController(withAuthorisedUserModel userModel: AuthorisedUserModel) {
        do {
            try self.optionalShowEditProfileViewController(withAuthorisedUserModel: userModel)
        } catch {
            if let parentRouter = self.parentRouter {
                parentRouter.showEditProfileViewController(withAuthorisedUserModel: userModel)
            } else {
                fatalError("Error performing protocol method: \(error)")
            }
        }
    }
    
}
