//
//  TroovyViewController.swift
//  troovy-ios
//
//  Created by Daniil on 11.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit
import NVActivityIndicatorView

class TroovyViewController: GAITrackedViewController, TroovyServiceDelegate, NVActivityIndicatorViewable {
    
    private enum ViewControllerError: Error {
        case createFailed(storyboard: UIStoryboard?, storyboardID: String, viewController: UIViewController?)
    }
    
    // MARK: Properties Overriders
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.default
    }
    
    // MARK: Internal Properties
    
    // Shows if view visible.
    internal var viewAppeared = false
    
    /// Router showing this view controller.
    internal(set) weak var router: TroovyRouterInput! {
        didSet {
            self.router?.viewControllerInited(viewController: self)
        }
    }
    
    // MARK: Private Properties
    
    private let loadingView = LoadingView(frame: CGRect(x: 0.0, y: 0.0, width: 320.0, height: 480.0))

    // MARK: Init Methods & Superclass Overriders
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.screenName = String(describing: type(of: self))
        self.automaticallyAdjustsScrollViewInsets = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.configureServices()
        self.viewAppeared = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let navigationController = self.navigationController {
            self.loadingView.frame = navigationController.view.bounds
        } else {
            self.loadingView.frame = self.view.bounds
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.view.endEditing(true)
        self.viewAppeared = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: Class Methods
    
    /// Initializes view controller from the storyboard. Throws error if occurs.
    ///
    /// - parameter storyboardID: Storyboard ID of the view controller.
    /// - parameter router: Router showing view controller.
    ///
    /// - returns: View controller with passed storyboard ID.
    ///
    class func create(fromStoryboardWithStoryboardID storyboardID: String?, router: TroovyRouter) throws -> UIViewController {
        let viewControllerStoryboardID = storyboardID ?? String(describing: type(of: self))
        
        do {
            let storyboard = try TroovyStoryboard.storyboard(forStoryboardID: viewControllerStoryboardID)
            let viewController = storyboard.instantiateViewController(withIdentifier: viewControllerStoryboardID)
            
            if let troovyViewController = viewController as? TroovyViewController {
                troovyViewController.router = router
                return troovyViewController
            } else {
                return viewController
            }
        } catch  {
            fatalError("Error creating storyboard: \(error)")
        }
        
        throw(ViewControllerError.createFailed(storyboard: nil, storyboardID: viewControllerStoryboardID, viewController: nil))
    }
    
    // MARK: Public Methods
    
    /// Lets view controller to get services. Should be overridden.
    ///
    /// - parameter assembly: Assembly which contains all services.
    ///
    func inject(propertiesWithAssembly assembly: ViewControllerAssemblyManager) {
        // Should be overridden
    }
    
    // MARK: Internal Methods
    
    /// The view controller configure services for own usage. Should be overridden.
    internal func configureServices() {
        // Should be overridden
    }
    
    /// Gets called when service receive method succeeded. Should be overridden.
    ///
    /// - parameter method: Name of the method which succeeded.
    /// - parameter resultDictionary: Request result as dictionary.
    /// - parameter resultArray: Request result as array of dictionaries.
    /// - parameter resultString: Request result as string.
    ///
    internal func serviceMethodSucceeded(withMethod method: String, resultDictionary: [String:Any]?, resultArray: [[String:Any]]?, resultString: String?) {
        // Should be overridden
    }
    
    /// Gets called when service receive method failed. Should be overridden.
    ///
    /// - parameter method: Name of the method which succeeded.
    ///
    internal func serviceMethodFailed(withMethod method: String) {
        // Should be overridden
    }
    
    /// Shows loading view above the screen if possible.
    internal func showLoadingView(withMethod method: String) {
        if !self.viewAppeared || self.presentedViewController != nil {
            return
        }
        
        self.showLoadingView()
    }
    
    /// Shows loading view above the screen.
//    internal func showLoadingView() {
//        if self.navigationController != nil {
//            self.loadingView.frame = self.navigationController!.view.bounds
//            self.navigationController!.view.addSubview(self.loadingView)
//        } else if self.tabBarController != nil {
//            self.loadingView.frame = self.tabBarController!.view.bounds
//            self.tabBarController!.view.addSubview(self.loadingView)
//        } else {
//            self.loadingView.frame = self.view.bounds
//            self.view.addSubview(self.loadingView)
//        }
//    }
    
    internal func showLoadingView() {
        startAnimating()
    }
    
    internal func showLoadingView(withMessage message: String) {
        startAnimating(message: message)
    }
    
    /// Hides loading view.
//    internal func hideLoadingView(withMethod method: String) {
//        self.loadingView.removeFromSuperview()
//    }
    internal func hideLoadingView(withMethod method: String) {
        stopAnimating()
    }
    
    internal func hideLoadingView() {
        stopAnimating()
    }
    
    /// Determines if alert should be shown.
    ///
    /// - returns: True if alert should be shown. False otherwise.
    ///
    internal func shouldShowAlert(forMethod method: String) -> Bool {
        return true
    }
    
    internal func alertTitle(forMethod method: String) -> String {
        return ApplicationMessages.AlertTitles.message
    }
    
    // MARK: Protocols Implementation
    
    // MARK: TroovyServiceDelegate
    
    /// Implements default behaviour for TroovyServiceDelegate. In most cases it will be enough.
    internal func serviceStateChanged(withActionResult result: ServiceActionResult) {
        switch result {
        case .methodStarted(let method):
            DispatchQueue.main.async {
                self.showLoadingView(withMethod: method)
            }
            break
        case .methodSucceeded(let method):
            DispatchQueue.main.async {
                self.hideLoadingView(withMethod: method)
            }
            
            self.serviceMethodSucceeded(withMethod: method, resultDictionary: nil, resultArray: nil, resultString: nil)
            break
        case .methodSucceededWithMessage(let method, let resultString):
            DispatchQueue.main.async {
                self.hideLoadingView(withMethod: method)
            }
            
            self.serviceMethodSucceeded(withMethod: method, resultDictionary: nil, resultArray: nil, resultString: resultString)
            break
        case .methodSucceededWithResponseDictionary(let method, let resultDictionary):
            DispatchQueue.main.async {
                self.hideLoadingView(withMethod: method)
            }
            
            self.serviceMethodSucceeded(withMethod: method, resultDictionary: resultDictionary, resultArray: nil, resultString: nil)
            break
        case .methodSucceededWithResponseArray(let method, let resultArray):
            DispatchQueue.main.async {
                self.hideLoadingView(withMethod: method)
            }
            
            self.serviceMethodSucceeded(withMethod: method, resultDictionary: nil, resultArray: resultArray, resultString: nil)
            break
        case .methodFailed(let method, let error):
            DispatchQueue.main.async {
                self.hideLoadingView(withMethod: method)
                
                if self.viewAppeared && self.presentedViewController == nil && self.shouldShowAlert(forMethod: method) {
                    let title = self.alertTitle(forMethod: method)
                    self.showAlert(withTitle: title, message: error)
                }
            }
            
            self.serviceMethodFailed(withMethod: method)
            break
        case .methodCancelled(let method):
            DispatchQueue.main.async {
                self.hideLoadingView(withMethod: method)
            }
            break
        default:
            if self.viewAppeared && self.presentedViewController == nil {
                fatalError("Other cases should be overrided where it needed")
            }
            break
        }
    }

}
