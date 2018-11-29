//
//  EditCourseRouter.swift
//  troovy-ios
//
//  Created by Daniil on 22.09.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class EditCourseRouter: TroovyRouter {

    // MARK: Public Methods
    
    /// Shows initial view controller embeded in navigation controller in passed window.
    ///
    /// - parameter navigationController: Navigation controller on which router will be presented.
    /// - parameter authorisedUserModel: Model of the authorised user model.
    /// - parameter courseModel: Model of the unfinished course model. Course creation will be continued if model exists.
    ///
    func showInitialViewController(withNavigationController navigationController: UINavigationController, authorisedUserModel: AuthorisedUserModel, courseModel: CourseModel) {
        let rootNavigationController = self.setupEditCourseInitialViewControllers(withAuthorisedUserModel: authorisedUserModel, courseModel: courseModel)
        self.rootNavigationController = rootNavigationController
        
        navigationController.present(rootNavigationController, animated: true, completion: nil)
    }
    
    // MARK: Private Methods
    
    private func setupEditCourseInitialViewControllers(withAuthorisedUserModel userModel: AuthorisedUserModel, courseModel: CourseModel) -> UINavigationController {
        let viewController = self.createViewControllerAndHandleErrors(withStoryboardID: "EditCourseViewController") as! EditCourseViewController
        viewController.authorisedUserModel = userModel
        viewController.courseModel = courseModel
        
        let navigationController = TroovyNavigationController(rootViewController: viewController)
        return navigationController
    }
    
}
