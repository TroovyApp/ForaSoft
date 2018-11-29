//
//  SettingsRouter.swift
//  troovy-ios
//
//  Created by Daniil on 23.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class SettingsRouter: TroovyRouter {

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
    
    override func showCreditsViewController(withAuthorisedUserModel userModel: AuthorisedUserModel) {
        let viewController = self.createViewControllerAndHandleErrors(withStoryboardID: "CreditsViewController") as! CreditsViewController
        viewController.authorisedUserModel = userModel
        viewController.hidesBottomBarWhenPushed = true
        
        self.push(viewController: viewController)
    }
    
    override func showWithdrawalCardViewController(withAuthorisedUserModel userModel: AuthorisedUserModel, currentBalance: String?, delegate: WithdrawalCardDelegate) {
        let viewController = self.createViewControllerAndHandleErrors(withStoryboardID: "WithdrawalCardViewController") as! WithdrawalCardViewController
        viewController.currentBalance = currentBalance
        viewController.delegate = delegate
        viewController.modalPresentationStyle = .overCurrentContext
        viewController.modalTransitionStyle = .crossDissolve
        
        self.present(viewController: viewController)
    }
    
    override func showEditProfileViewController(withAuthorisedUserModel userModel: AuthorisedUserModel) {
        let viewController = self.createViewControllerAndHandleErrors(withStoryboardID: "EditProfileViewController") as! EditProfileViewController
        viewController.authorisedUserModel = userModel
        viewController.hidesBottomBarWhenPushed = true
        
        self.push(viewController: viewController)
    }
    
}
