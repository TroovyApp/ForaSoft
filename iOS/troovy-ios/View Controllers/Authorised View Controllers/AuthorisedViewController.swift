//
//  AuthorisedViewController.swift
//  troovy-ios
//
//  Created by Daniil on 11.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class AuthorisedViewController: UITabBarController {
    
    // MARK: Properties Overriders
    
    override var selectedViewController: UIViewController? {
        didSet {
            self.checkSelectedViewController()
        }
    }
    
    // MARK: Internal Properties
    
    /// Router showing this view controller.
    internal(set) var router: TroovyRouterInput!
    
    // MARK: Public Properties
    
    /// Model of the unauthorised user.
    var authorisedUserModel: AuthorisedUserModel!
    
    // MARK: Private Properties
    
    private let networkManager = NetworkManager.shared
    private let applicationService = ApplicationService()
    
    private var coursesRouter: CoursesRouter!
    private var scheduleRouter: ScheduleRouter!
    private var settingsRouter: SettingsRouter!
    
    private var configuringUser = false
    
    // MARK: Init Methods & Superclass Overriders

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupTabBarViewControllers()
        self.checkSelectedViewController()
        self.configureUser()
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(_:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Notifications & Observers
    
    @objc private func applicationDidBecomeActive(_ notification: Notification) {
        self.configureUser()
    }
    
    // MARK: Private Methods
    
    private func setupTabBarViewControllers() {
        if let tabBarViewControllers = self.viewControllers {
            for viewController in tabBarViewControllers {
                if let navigationController = viewController as? UINavigationController {
                    if let troovyViewController = navigationController.viewControllers.first as? TroovyViewController {
                        if let coursesHomeViewController = troovyViewController as? CoursesHomeViewController {
                            self.coursesRouter = CoursesRouter(parentRouter: (self.router as! TroovyRouter), navigationController: navigationController)
                            
                            coursesHomeViewController.router = self.coursesRouter
                            coursesHomeViewController.authorisedUserModel = self.authorisedUserModel
                        } else if let scheduleHomeViewController = troovyViewController as? ScheduleHomeViewController {
                            self.scheduleRouter = ScheduleRouter(parentRouter: (self.router as! TroovyRouter), navigationController: navigationController)
                            
                            scheduleHomeViewController.router = self.scheduleRouter
                            scheduleHomeViewController.authorisedUserModel = self.authorisedUserModel
                        } else if let settingsHomeViewController = troovyViewController as? SettingsHomeViewController {
                            self.settingsRouter = SettingsRouter(parentRouter: (self.router as! TroovyRouter), navigationController: navigationController)
                            
                            settingsHomeViewController.router = self.settingsRouter
                            settingsHomeViewController.authorisedUserModel = self.authorisedUserModel
                        }
                    }
                }
            }
        }
        
        self.tabBar.shadowImage = UIImage()
        self.tabBar.backgroundImage = UIImage()
        self.tabBar.backgroundColor = .white
        self.tabBar.barTintColor = .white
        
        if let items = self.tabBar.items {
            for item in items {
                item.imageInsets = UIEdgeInsetsMake(6.0, 0.0, -6.0, 0.0)
            }
        }
    }
    
    private func checkSelectedViewController() {
        if let navigationController = self.selectedViewController as? UINavigationController {
            if let troovyViewController = navigationController.viewControllers.first as? TroovyViewController {
                self.router.changeChildRouter(withNew: (troovyViewController.router as! TroovyRouter))
            }
        } else if let troovyViewController = self.selectedViewController as? TroovyViewController {
            self.router.changeChildRouter(withNew: (troovyViewController.router as! TroovyRouter))
        }
    }
    
    private func configureUser() {
        if self.configuringUser {
            return
        }
        
        self.configuringUser = true
        
        
        let timezoneOffset = NSTimeZone.system.secondsFromGMT()
        self.networkManager.configureUser(withNetworkToken: self.authorisedUserModel.networkToken, pushToken: nil, timezoneOffset: timezoneOffset) { (response, errorMessage, isCancelled) -> (Void) in
            DispatchQueue.main.async {
                if let responseDictionary = response as? [String:Any] {
                    self.userConfigured(response: responseDictionary)
                } else {
                    self.userNotConfigured()
                }
            }
        }
    }
    
    private func userConfigured(response: [String:Any]) {
        self.configuringUser = false
        
        self.applicationService.updateAndSaveApplicationModel(withDictionary: response)
    }
    
    private func userNotConfigured() {
        self.configuringUser = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            self.configureUser()
        }
    }

}
