//
//  UnauthorisedRouter.swift
//  troovy-ios
//
//  Created by Daniil on 18.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class UnauthorisedRouter: TroovyRouter {
    
    // MARK: Init Methods & Superclass Overriders
    
    override func optionalShowUserVerificationViewController(withUnauthorisedUserModel model: UnauthorisedUserModel) throws {
        let viewController = self.createViewControllerAndHandleErrors(withStoryboardID: "UserVerificationViewController") as! UserVerificationViewController
        viewController.unauthorisedUserModel = model
        
        self.push(viewController: viewController)
    }
    
    override func optionalShowRegistrationViewController(withUnauthorisedUserModel model: UnauthorisedUserModel) throws {
        let viewController = self.createViewControllerAndHandleErrors(withStoryboardID: "RegistrationViewController") as! RegistrationViewController
        viewController.unauthorisedUserModel = model
        
        self.push(viewController: viewController)
    }
    
    // MARK: Public Methods
    
    /// Shows initial view controller embeded in navigation controller in passed window.
    ///
    /// - parameter navigationController: Root navigation controller.
    ///
    func showInitialViewController(withRootNavigationController navigationController: UINavigationController, errorMessage: String?) {
        self.rootNavigationController = navigationController
        
        let viewController = self.setupUnauthorisedViewController(withMessage: errorMessage)
        navigationController.viewControllers = [viewController]
    }
    
    // MARK: Private Methods
    
    private func setupUnauthorisedViewController(withMessage errorMessage: String?) -> UIViewController {
        let viewController = self.createViewControllerAndHandleErrors(withStoryboardID: "UnauthorisedViewController") as! UnauthorisedViewController
        viewController.errorMessage = errorMessage
        return viewController
    }
    
}
