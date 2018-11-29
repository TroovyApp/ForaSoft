//
//  LaunchViewController.swift
//  troovy-ios
//
//  Created by Daniil on 11.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class LaunchViewController: TroovyViewController {
    
    // MARK: Properties Overriders
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: Private Properties
    
    private var unauthorisedUserService: UnauthorisedUserService!
    private var authorisedUserService: AuthorisedUserService!
    
    // MARK: Init Methods & Superclass Overriders

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.main.async {
            self.showNextView()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func inject(propertiesWithAssembly assembly: ViewControllerAssemblyManager) {
        self.unauthorisedUserService = assembly.unauthorisedUserService
        self.authorisedUserService = assembly.authorisedUserService
    }
    
    // MARK: Private Methods
    
    private func showNextView() {
        if self.authorisedUserService.isUserAuthorised() {
            self.userAuthorised()
        } else {
            if self.unauthorisedUserService.isTutorialPassed() {
                self.userUnauthorised()
            } else {
                self.showTutorial()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.userUnauthorised()
                }
            }
        }
    }
    
    private func showTutorial() {
        self.router.showTutorialViewController()
    }
    
    private func userUnauthorised() {
        self.router.showUnauthorisedViewController()
    }
    
    private func userAuthorised() {
        let authorisedUserModel = self.authorisedUserService.currentAuthorisedUser()
        self.router.showAuthorisedViewController(withAuthorisedUserModel: authorisedUserModel)
    }

}
