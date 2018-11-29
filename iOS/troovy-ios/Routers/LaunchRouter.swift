//
//  LaunchRouter.swift
//  troovy-ios
//
//  Created by Daniil on 11.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit
import MobileCoreServices

import Stripe
import HockeySDK_Source
import IQKeyboardManager

class LaunchRouter: TroovyRouter {
    
    // MARK: Private Properties
    
    private let infoPlistService = InfoPlistService()
    
    private let viewControllerAssemblyManager = ViewControllerAssemblyManager()
    
    // MARK: Init Methods & Superclass Overriders
    
    override init() {
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive(_:)), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        
        NetworkManager.shared.userBannedAction = { [weak self] (message) in
            DispatchQueue.main.async {
                self?.userBanned(withMessage: message)
            }
        }
        
        self.setupFrameworks()
    }
    
    override func optionalViewControllerInited(viewController: UIViewController) throws {
        self.viewControllerAssemblyManager.configure(viewController: viewController)
    }
    
    override func optionalShowTutorialViewController() throws {
        let viewController = self.createViewControllerAndHandleErrors(withStoryboardID: "TutorialViewController") as! TutorialViewController
        viewController.modalPresentationStyle = .overFullScreen
        viewController.modalTransitionStyle = .crossDissolve
        
        self.present(viewController: viewController)
    }
    
    override func optionalShowUnauthorisedViewController() throws {
        let unauthorisedRouter = UnauthorisedRouter(parentRouter: self)
        self.childRouter = unauthorisedRouter
        
        unauthorisedRouter.showInitialViewController(withRootNavigationController: self.rootNavigationController!, errorMessage: nil)
    }
    
    override func optionalShowAuthorisedViewController(withAuthorisedUserModel model: AuthorisedUserModel) throws {
        let authorisedRouter = AuthorisedRouter(parentRouter: self)
        self.childRouter = authorisedRouter
        
        authorisedRouter.showInitialViewController(withRootNavigationController: self.rootNavigationController!, authorisedUserModel: model)
    }
    
    override func optionalShowOtherProfileViewController(withAuthorisedUserModel userModel: AuthorisedUserModel, userID: String) throws {
        let viewController = self.createViewControllerAndHandleErrors(withStoryboardID: "OtherProfileViewController") as! OtherProfileViewController
        viewController.authorisedUserModel = userModel
        viewController.userID = userID
        
        let navigationController = TroovyNavigationController(rootViewController: viewController)
        self.present(viewController: navigationController)
    }
    
    override func optionalShowCommonCourseScreen(withAuthorisedUserModel userModel: AuthorisedUserModel?, courseModel: CourseModel?, courseID: String) throws {
        let viewController = self.createViewControllerAndHandleErrors(withStoryboardID: "CommonCourseViewController") as! CommonCourseViewController
        viewController.authorisedUserModel = userModel
        viewController.courseModel = courseModel
        viewController.courseID = courseID
        viewController.hidesBottomBarWhenPushed = true
        
        let lastChildRouter = self.lastChildRouter()
        let lastViewController = lastChildRouter.topPresentedViewContoller(forController: lastChildRouter.rootNavigationController)
        
        let pushPossible = (lastViewController != nil && lastViewController?.presentedViewController == nil && lastViewController is UINavigationController)
        let coursesHomeViewController = (lastViewController as? UINavigationController)?.viewControllers.last as? CoursesHomeViewController
        let otherProfileViewController = (lastViewController as? UINavigationController)?.viewControllers.last as? OtherProfileViewController
        let courseInfoViewController = (lastViewController as? UINavigationController)?.viewControllers.last as? CourseInfoViewController
        
        if courseInfoViewController != nil && pushPossible && courseInfoViewController?.courseID == courseID {
            return
        } else if coursesHomeViewController != nil && pushPossible {
            self.push(viewController: viewController)
        } else if otherProfileViewController != nil && pushPossible && courseModel != nil && courseModel?.creatorID == otherProfileViewController?.userID {
            self.push(viewController: viewController)
        } else {
            let navigationController = TroovyNavigationController(rootViewController: viewController)
            self.present(viewController: navigationController)
        }
    }
    
    override func optionalShowFuturePastSessionScreen(withAuthorisedUserModel userModel: AuthorisedUserModel?, sessionModel: CourseSessionModel, courseModel: CourseModel?) throws {
        let viewController = self.createViewControllerAndHandleErrors(withStoryboardID: "SessionPageViewController") as! SessionPageViewController
        viewController.authorisedUserModel = userModel
        viewController.sessionModel = sessionModel
        viewController.hidesBottomBarWhenPushed = true
        
        if courseModel != nil {
            let navigationController = TroovyNavigationController(rootViewController: viewController)
            self.present(viewController: navigationController)
        } else {
            self.push(viewController: viewController)
        }
    }
    
    override func optionalTakeProfilePictureFromCamera(withDelegate delegate: (UIImagePickerControllerDelegate & UINavigationControllerDelegate), completion: (() -> ())?) throws {
        let imagePicker = PortraitImagePickerController()
        imagePicker.videoQuality = .typeHigh
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .camera
        imagePicker.mediaTypes = [kUTTypeImage as String]
        imagePicker.delegate = delegate
        
        self.present(viewController: imagePicker, completion: completion)
    }
    
    override func optionalTakeProfilePictureFromCameraRoll(withDelegate delegate: (UIImagePickerControllerDelegate & UINavigationControllerDelegate), completion: (() -> ())?) throws {
        let imagePicker = PortraitImagePickerController()
        imagePicker.videoQuality = .typeHigh
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = [kUTTypeImage as String]
        imagePicker.delegate = delegate
        
        self.present(viewController: imagePicker, completion: completion)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Notifications & Observers
    
    @objc private func applicationWillResignActive(_ notification: Notification) {
        GAI.sharedInstance().dispatch()
    }
    
    // MARK: Public Methods
    
    /// Shows initial view controller embeded in navigation controller in passed window.
    ///
    /// - parameter window: Window to show launch screen.
    ///
    func showInitialViewController(withWindow window: UIWindow) {
        let navigationController = self.setupLaunchNavigationController()
        window.rootViewController = navigationController
        
        self.rootNavigationController = navigationController
    }
    
    // MARK: Private Methods
    
    private func setupLaunchNavigationController() -> UINavigationController {
        let viewController = self.createViewControllerAndHandleErrors(withStoryboardID: "LaunchViewController")
        let navigationController = TroovyNavigationController(rootViewController: viewController!)
        
        return navigationController
    }
    
    private func setupFrameworks() {
        let hockeyAppApplicationIdentifier = self.infoPlistService.hockeyAppApplicationIdentifier()
        if hockeyAppApplicationIdentifier.count > 0 {
            BITHockeyManager.shared().configure(withIdentifier: self.infoPlistService.hockeyAppApplicationIdentifier())
            BITHockeyManager.shared().start()
        }
        
        IQKeyboardManager.shared().isEnabled = true
        IQKeyboardManager.shared().isEnableAutoToolbar = false
        IQKeyboardManager.shared().shouldResignOnTouchOutside = true
        
        STPPaymentConfiguration.shared().publishableKey = self.infoPlistService.stripeApiKey()
        STPPaymentConfiguration.shared().appleMerchantIdentifier = self.infoPlistService.appleMerchantIdentifier()
        
        if let googleConfigurationFilePath = Bundle.main.path(forResource: self.infoPlistService.googleAnalyticsFilename(), ofType: "plist"), let configurationFileAsDictionary = NSDictionary.init(contentsOfFile: googleConfigurationFilePath), let trackID = configurationFileAsDictionary["TRACKING_ID"] as? String {
            GGLContext.sharedInstance().configureWithError(nil)
            
            let tracker = GAI.sharedInstance().tracker(withTrackingId: trackID)

            GAI.sharedInstance().trackUncaughtExceptions = true
            GAI.sharedInstance().logger.logLevel = .error
            GAI.sharedInstance().dispatchInterval = 120.0
            GAI.sharedInstance().defaultTracker = tracker
        }
    }
    
    private func userBanned(withMessage message: String?) {
        self.viewControllerAssemblyManager.authorisedUserService.deauthoriseUser()
        self.viewControllerAssemblyManager.createCoursesService.cancelUploadCourseResources()
        self.viewControllerAssemblyManager.createCoursesService.deleteSavedCourseModel()
        self.viewControllerAssemblyManager.coursesService.cancelAllCoursesLoading()
        self.viewControllerAssemblyManager.coursesService.removeCoursesAndIdentifiers()
        self.viewControllerAssemblyManager.videoStreamService.exitSession()
        
        if !(self.childRouter is UnauthorisedRouter) {
            let unauthorisedRouter = UnauthorisedRouter(parentRouter: self)
            self.childRouter = unauthorisedRouter
            
            guard let rootNavigationController = self.rootNavigationController else {
                return
            }
            
            if rootNavigationController.presentedViewController != nil {
                rootNavigationController.dismiss(animated: false, completion: {
                    unauthorisedRouter.showInitialViewController(withRootNavigationController: rootNavigationController, errorMessage: message)
                })
            } else {
                unauthorisedRouter.showInitialViewController(withRootNavigationController: rootNavigationController, errorMessage: message)
            }
        } else {
            if let lastViewController = self.childRouter?.rootNavigationController?.viewControllers.last as? TroovyViewController, let errorMessage = message {
                lastViewController.showAlert(withTitle: ApplicationMessages.AlertTitles.message, message: errorMessage)
            }
        }
    }
    
}
