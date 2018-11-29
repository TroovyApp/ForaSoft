//
//  AppDelegate.swift
//  troovy-ios
//
//  Created by Daniil on 08.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit
import Branch

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // MARK: Public Properties

    var window: UIWindow?
    
    // MARK: Private Properties
    
    private lazy var rootRouter = LaunchRouter()
    
    // MARK: Private Methods
    
    private func showLaunchViewContoller(withApplication: UIApplication) {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window!.makeKeyAndVisible()
        
        self.rootRouter.showInitialViewController(withWindow: self.window!)
    }
    
    private func openCourse(withCourseID courseID: String) {
        let authorisedUserService = AuthorisedUserService()
        let authorisedUserModel = (authorisedUserService.isUserAuthorised() ? authorisedUserService.currentAuthorisedUser() : nil)
        
        self.rootRouter.showCommonCourseScreen(withAuthorisedUserModel: authorisedUserModel, courseModel: nil, courseID: courseID)
    }
    
    private func loadInAppPurchases() {
        TroovyProducts.shared.requestProducts()
    }
    
    private func canChangeRoute() -> Bool {
        let lastChildRouter = self.rootRouter.lastChildRouter()
        var canChangeRoute = true
        if let viewController = lastChildRouter.rootNavigationController {
            var presentedViewController: UIViewController? = viewController
            while presentedViewController != nil {
                if presentedViewController is VideoStreamViewController {
                    canChangeRoute = false
                    break
                }
                
                if presentedViewController != nil && presentedViewController is UINavigationController {
                    let navigationController = presentedViewController as! UINavigationController
                    for controller in navigationController.viewControllers {
                        if controller is VideoStreamViewController {
                            canChangeRoute = false
                            break
                        }
                    }
                    
                    presentedViewController = presentedViewController?.presentedViewController
                } else {
                    presentedViewController = presentedViewController?.navigationController?.presentedViewController
                }
            }
        }
        
        return canChangeRoute
    }

    // MARK: Protocols Implementation
    
    // MARK: UIApplicationDelegate
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
//        if let playerViewController = self.rootRouter.presentedViewController() as? TroovyPlayerViewController, playerViewController.viewControllerVisible() {
//            return UIInterfaceOrientationMask.allButUpsideDown
//        } else {
//            return UIInterfaceOrientationMask.portrait
//        }
        
        return UIInterfaceOrientationMask.portrait
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        self.loadInAppPurchases()
        self.showLaunchViewContoller(withApplication: application)

        let info = InfoPlistService()
        
        let branch: Branch = Branch.getInstance(info.branchKey())
        branch.initSession(launchOptions: launchOptions, andRegisterDeepLinkHandler: {params, error in
            if error == nil {
                // params are the deep linked params associated with the link that the user clicked -> was re-directed to this app
                // params will be empty if no data found
                // ... insert custom logic here ...
                print("params: %@", params as? [String: AnyObject] ?? {})
                
                if let params = params, let courseID = params["courseId"] as? String {
                    self.openCourse(withCourseID: courseID)
                }
            }
        })
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
//    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
//        if let query = url.query, url.absoluteString.hasPrefix("troovy://opencourse") && self.canChangeRoute() {
//            let queryPairs = query.split(separator: "&")
//            for pair in queryPairs {
//                let components = pair.split(separator: "=")
//                if components.count >= 2 {
//                    let key = components[components.count - 2]
//                    if key == "id" {
//                        let value = components[components.count - 1]
//                        let courseID = String(value)
//                        self.openCourse(withCourseID: courseID)
//                        return true
//                    }
//                }
//            }
//        }
//
//        return false
//    }
//
//    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
//        if userActivity.activityType == NSUserActivityTypeBrowsingWeb && self.canChangeRoute() {
//            if let webPageURL = userActivity.webpageURL {
//                let components = webPageURL.pathComponents
//                if components.count >= 2 {
//                    let path = components[components.count - 2]
//                    if path == "courses" {
//                        let courseID = components[components.count - 1]
//                        self.openCourse(withCourseID: courseID)
//                        return true
//                    }
//                }
//
//                application.open(webPageURL, options: [:], completionHandler: nil)
//            }
//        }
//
//        return false
//    }
    
    // Respond to URI scheme links
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        // pass the url to the handle deep link call
        let branchHandled = Branch.getInstance().application(application,
                                                             open: url,
                                                             sourceApplication: sourceApplication,
                                                             annotation: annotation
        )
        if (!branchHandled) {
            // If not handled by Branch, do other deep link routing for the Facebook SDK, Pinterest SDK, etc
        }
        
        // do other deep link routing for the Facebook SDK, Pinterest SDK, etc
        return true
    }
    
    // Respond to Universal Links
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        // pass the url to the handle deep link call
        Branch.getInstance().continue(userActivity)
        
        return true
    }
    
}
