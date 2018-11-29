//
//  AuthorisedRouter.swift
//  troovy-ios
//
//  Created by Daniil on 22.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class AuthorisedRouter: TroovyRouter {
    
    // MARK: Init Methods & Superclass Overriders
    
    override func optionalChangeChildRouter(withNew childRouter: TroovyRouter) throws {
        self.childRouter = childRouter
    }
    
    override func optionalShowCourseSessionScreen(withAuthorisedUserModel userModel: AuthorisedUserModel?, sessionModel: CourseSessionModel?, courseSessionAlwaysEditable: Bool, delegate: CreateSessionDelegate?) throws {
        let viewController = self.createViewControllerAndHandleErrors(withStoryboardID: "CreateSessionModelViewController") as! CreateSessionModelViewController
        viewController.authorisedUserModel = userModel
        viewController.courseSessionModel = sessionModel
        viewController.courseSessionAlwaysEditable = courseSessionAlwaysEditable
        viewController.delegate = delegate
        viewController.setCustomModalTransition(customModalTransition: DragCustomModalTransition(), inPresentationStyle: UIModalPresentationStyle.overCurrentContext)
        
        self.present(viewController: viewController, completion: nil)
    }
    
    override func optionalShowVideoStreamViewController(withAuthorisedUserModel userModel: AuthorisedUserModel, sessionModel: CourseSessionModel, sessionOwner: Bool) throws {
        let viewController = self.createViewControllerAndHandleErrors(withStoryboardID: "VideoStreamViewController") as! VideoStreamViewController
        viewController.authorisedUserModel = userModel
        viewController.sessionModel = sessionModel
        
        let navigationController = TroovyNavigationController(rootViewController: viewController)
        self.present(viewController: navigationController)
    }
    
    override func optionalShowFinishStreamViewController(withAuthorisedUserModel userModel: AuthorisedUserModel, streamInfoModel: StreamInfoModel, sessionOwner: Bool) throws {
        let viewController = self.createViewControllerAndHandleErrors(withStoryboardID: "FinishedStreamViewController") as! FinishedStreamViewController
        viewController.authorisedUserModel = userModel
        viewController.streamInfoModel = streamInfoModel
        viewController.isSessionOwner = sessionOwner
        
        self.show(viewController: viewController)
    }
    
    override func optionalShowSessionAttachmentViewController(withAuthorisedUserModel userModel: AuthorisedUserModel, attachmentModel: CourseAttachmentModel) throws {
        let viewController = self.createViewControllerAndHandleErrors(withStoryboardID: "SessionAttachmentViewController") as! SessionAttachmentViewController
        viewController.authorisedUserModel = userModel
        viewController.attachmentModel = attachmentModel
        viewController.modalPresentationStyle = .overCurrentContext
        viewController.modalTransitionStyle = .crossDissolve
        
        self.present(viewController: viewController)
    }
    
    override func optionalShowVideo(withVideoURL videoURL: URL) throws {
        let player = AVPlayer.init(url: videoURL)
        player.automaticallyWaitsToMinimizeStalling = false
        
        let moviePlayer = TroovyPlayerViewController()
        moviePlayer.player = player
        moviePlayer.modalPresentationStyle = .fullScreen
        moviePlayer.modalTransitionStyle = .crossDissolve
        
        self.present(viewController: moviePlayer, animated: false, completion: {
            player.play()
        })
    }
    
    override func optionalShowScheduleScreen() throws {
//        if let topVC = self.rootNavigationController?.topViewController as? AuthorisedViewController{
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
//                topVC.selectedIndex = 1
//            })
//        }
    }
    
    // MARK: Public Methods
    
    /// Shows initial view controller embeded in navigation controller in passed window.
    ///
    /// - parameter navigationController: Root navigation controller.
    /// - parameter model: Model of the authorised user model.
    ///
    func showInitialViewController(withRootNavigationController navigationController: UINavigationController, authorisedUserModel model: AuthorisedUserModel) {
        self.rootNavigationController = navigationController
        
        let viewController = self.setupAuthorisedViewController(withAuthorisedUserModel: model)
        navigationController.viewControllers = [viewController]
    }
    
    // MARK: Private Methods
    
    private func setupAuthorisedViewController(withAuthorisedUserModel model: AuthorisedUserModel) -> UIViewController {
        let viewController = self.createViewControllerAndHandleErrors(withStoryboardID: "AuthorisedViewController") as! AuthorisedViewController
        viewController.router = self
        viewController.authorisedUserModel = model
        return viewController
    }
    
}
