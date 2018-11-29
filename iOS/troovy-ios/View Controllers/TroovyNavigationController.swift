//
//  TroovyNavigationController.swift
//  troovy-ios
//
//  Created by Daniil on 11.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class TroovyNavigationController: UINavigationController, UIGestureRecognizerDelegate {
    
    // MARK: Properties Overriders
    
    override var prefersStatusBarHidden: Bool {
        return self.childViewControllers.last?.prefersStatusBarHidden ?? false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.childViewControllers.last?.preferredStatusBarStyle ?? .lightContent
    }
    
    override var shouldAutorotate: Bool {
        return self.controllerShouldAutorotate
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return self.controllerSupportedInterfaceOrientations
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return self.controllerPreferredInterfaceOrientationForPresentation
    }
    
    // MARK: Private Properties
    
    private var controllerShouldAutorotate = true
    private var controllerSupportedInterfaceOrientations = UIInterfaceOrientationMask.portrait
    private var controllerPreferredInterfaceOrientationForPresentation = UIInterfaceOrientation.portrait
    
    // MARK: Init Methods & Superclass Overriders
    
    override init(rootViewController: UIViewController) {
        super.init(navigationBarClass: TroovyNavigationBar.self, toolbarClass: nil)
        self.viewControllers = [rootViewController]
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    convenience init(rootViewController: UIViewController, shouldAutorotate: Bool, supportedInterfaceOrientations: UIInterfaceOrientationMask, preferredInterfaceOrientationForPresentation: UIInterfaceOrientation) {
        self.init(rootViewController: rootViewController)
        
        self.controllerShouldAutorotate = shouldAutorotate
        self.controllerSupportedInterfaceOrientations = supportedInterfaceOrientations
        self.controllerPreferredInterfaceOrientationForPresentation = preferredInterfaceOrientationForPresentation
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setNavigationBarHidden(true, animated: false)
        self.automaticallyAdjustsScrollViewInsets = false
        
        self.view.backgroundColor = UIColor.tv_backgroundViewColor()
        self.interactivePopGestureRecognizer?.delegate = self
        self.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    // MARK: Protocols Implementation
    
    // MARK: UIGestureRecognizerDelegate
    
    internal func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if let interactivePopGestureRecognizer = self.interactivePopGestureRecognizer {
            if interactivePopGestureRecognizer == gestureRecognizer {
                return (self.viewControllers.count > 1)
            }
        }
        
        return true
    }

}
