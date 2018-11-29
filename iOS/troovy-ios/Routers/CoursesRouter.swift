//
//  CoursesRouter.swift
//  troovy-ios
//
//  Created by Daniil on 23.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import MobileCoreServices

class CoursesRouter: TroovyRouter {
    
    // MARK: Init Methods & Superclass Overriders
    
    /// Initialises router with parent router.
    ///
    /// - parameter parentRouter: Router which is showing this router.
    /// - parameter navigationController: Root navigation controller.
    ///
    convenience init(parentRouter: TroovyRouter, navigationController: UINavigationController) {
        self.init(parentRouter: parentRouter)
        
        self.rootNavigationController = navigationController
    }
    
    override func optionalShowScheduleScreen() throws {
        
        if let topVC = self.rootNavigationController?.topViewController, let tabBarVC = topVC.tabBarController{
            tabBarVC.selectedIndex = 1
        }
        
        self.rootNavigationController?.popToRootViewController(animated: true)
        if let parentRouter = self.parentRouter {
            parentRouter.showScheduleScreen()
        }
    }
    
    override func optionalShowCreateCourseMainInfoScreen(withAuthorisedUserModel userModel: AuthorisedUserModel, courseModel: UnfinishedCourseModel?) throws {
        let createCourseRouter = CreateCourseRouter(parentRouter: self)
        self.childRouter = createCourseRouter
        
        createCourseRouter.showInitialViewController(withNavigationController: self.rootNavigationController!, authorisedUserModel: userModel, courseModel: courseModel)
    }
    
    override func optionalShowOwnCourseScreen(withAuthorisedUserModel userModel: AuthorisedUserModel, courseModel: CourseModel) throws {
        let viewController = self.createViewControllerAndHandleErrors(withStoryboardID: "OwnCourseViewController") as! OwnCourseViewController
        viewController.authorisedUserModel = userModel
        viewController.courseModel = courseModel
        viewController.courseID = courseModel.id
        viewController.hidesBottomBarWhenPushed = true
        
        self.push(viewController: viewController)
    }
    
    override func optionalShowCourseAttachmentsScreen(withAuthorisedUserModel userModel: AuthorisedUserModel?, courseModel: CourseModel) throws {
        let viewController = self.createViewControllerAndHandleErrors(withStoryboardID: "CourseAttachmentsViewController") as! CourseAttachmentsViewController
        viewController.authorisedUserModel = userModel
        viewController.courseModel = courseModel
        
        let navigationController = TroovyNavigationController(rootViewController: viewController)
        
        self.present(viewController: navigationController)
    }
    
    override func optionalShowUploadAttachmentScreen(withAuthorisedUserModel userModel: AuthorisedUserModel, courseModel: CourseModel, attachmentModel: CourseAttachmentModel) throws {
        let viewController = self.createViewControllerAndHandleErrors(withStoryboardID: "UploadAttachmentViewController") as! UploadAttachmentViewController
        viewController.authorisedUserModel = userModel
        viewController.courseModel = courseModel
        viewController.attachmentModel = attachmentModel
        viewController.modalPresentationStyle = .overCurrentContext
        viewController.modalTransitionStyle = .crossDissolve
        
        self.present(viewController: viewController)
    }
    
    override func optionalShowUploadCourseIntroScreen(withAuthorisedUserModel userModel: AuthorisedUserModel, courseModel: CourseModel, introFilePath: String, courseCreation: Bool, unfinishedCourseModel: UnfinishedCourseModel) throws {
        let viewController = self.createViewControllerAndHandleErrors(withStoryboardID: "UploadCourseIntroViewController") as! UploadCourseIntroViewController
        viewController.authorisedUserModel = userModel
        viewController.courseModel = courseModel
        viewController.introFilePath = introFilePath
        viewController.courseCreation = courseCreation
        viewController.unfinishedCourseModel = unfinishedCourseModel
        viewController.modalPresentationStyle = .overCurrentContext
        viewController.modalTransitionStyle = .crossDissolve
        
        self.present(viewController: viewController)
    }
    
    override func optionalShowReportCourseScreen(withAuthorisedUserModel userModel: AuthorisedUserModel, courseID: String) throws {
        let viewController = self.createViewControllerAndHandleErrors(withStoryboardID: "ReportCourseViewController") as! ReportCourseViewController
        viewController.authorisedUserModel = userModel
        viewController.courseID = courseID
        viewController.modalPresentationStyle = .overCurrentContext
        viewController.modalTransitionStyle = .crossDissolve
        
        self.present(viewController: viewController)
    }
    
    override func optionalShowBuyCourseScreen(withAuthorisedUserModel userModel: AuthorisedUserModel, course: CourseModel) throws {
        let viewController = self.createViewControllerAndHandleErrors(withStoryboardID: "CoursePaymentViewController") as! CoursePaymentViewController
        viewController.authorisedUserModel = userModel
        viewController.courseModel = course
        
        let navigationController = TroovyNavigationController(rootViewController: viewController)
        
        self.present(viewController: navigationController)
    }
    
    override func optionalShowCourseNotEnoughMoneyViewController(withAuthorisedUserModel userModel: AuthorisedUserModel, notEnoughAmount: Double, cardParameters: [String:Any], delegate: CourseNotEnoughMoneyDelegate) throws {
        let viewController = self.createViewControllerAndHandleErrors(withStoryboardID: "CourseNotEnoughMoneyViewController") as! CourseNotEnoughMoneyViewController
        viewController.notEnoughAmount = notEnoughAmount
        viewController.cardParameters = cardParameters
        viewController.delegate = delegate
        viewController.modalPresentationStyle = .overCurrentContext
        viewController.modalTransitionStyle = .crossDissolve
        
        self.present(viewController: viewController)
    }
    
    override func optionalShowEditCourseScreen(withAuthorisedUserModel userModel: AuthorisedUserModel, courseModel: CourseModel) throws {
        let editCourseRouter = EditCourseRouter(parentRouter: self)
        self.childRouter = editCourseRouter
        
        editCourseRouter.showInitialViewController(withNavigationController: self.rootNavigationController!, authorisedUserModel: userModel, courseModel: courseModel)
    }
    
    override func optionalShowCourseImage(withImage image: UIImage) throws {
        let moviePlayer = TroovyPlayerViewController()
        moviePlayer.image = image
        moviePlayer.modalPresentationStyle = .fullScreen
        moviePlayer.modalTransitionStyle = .crossDissolve
        
        self.present(viewController: moviePlayer, animated: false, completion: nil)
    }
    
    override func optionalTakeCoursePreviewFromCamera(withDelegate delegate: (UIImagePickerControllerDelegate & UINavigationControllerDelegate), completion: (() -> ())?) throws {
        let imagePicker = PortraitImagePickerController()
        imagePicker.videoQuality = .typeHigh
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .camera
        imagePicker.videoMaximumDuration = 120
        imagePicker.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
        imagePicker.delegate = delegate
        
        self.present(viewController: imagePicker, completion: completion)
    }
    
    override func optionalTakeCoursePreviewFromCameraRoll(withDidSelect didSelect: ((_ assets: [DKAsset]) -> Void)?, maxSelectableCount: Int, completion: (() -> ())?) throws {
        let imagePicker = self.createViewControllerAndHandleErrors(withStoryboardID: "CourseImagePickerViewController") as! CourseImagePickerViewController
        imagePicker.configure(withSelectBlock: didSelect, maxSelectableCount: maxSelectableCount)
        imagePicker.setCustomModalTransition(customModalTransition: DragCustomModalTransition(), inPresentationStyle: UIModalPresentationStyle.overCurrentContext)
        
        self.present(viewController: imagePicker, completion: completion)
    }
    
    override func optionalTakeCourseAttachmentFromCameraRoll(withDelegate delegate: (UIImagePickerControllerDelegate & UINavigationControllerDelegate), completion: (() -> ())?) throws {
        let imagePicker = PortraitImagePickerController()
        imagePicker.videoQuality = .typeHigh
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = [kUTTypeMovie as String]
        imagePicker.delegate = delegate
        
        self.present(viewController: imagePicker, completion: completion)
    }
    
}
