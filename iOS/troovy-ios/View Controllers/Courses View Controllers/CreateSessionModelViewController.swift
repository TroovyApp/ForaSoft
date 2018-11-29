//
//  CreateSessionModelViewController.swift
//  troovy-ios
//
//  Created by Daniil on 19.12.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit
import IQKeyboardManager

enum CreateSessionSteps: Int {
    case title = 0
    case description
    case date
    case duration
    case count
}

enum CreateSessionStepsHeight: CGFloat {
    case large = 80.0
    case standart = 84.0
    case compact = 56.0
    case small = 38.0
    
    static func normalHeight(forStepType stepType: CreateSessionSteps?) -> CGFloat {
        guard let type = stepType else {
            return CreateCourseStepsHeight.standart.rawValue
        }
        
        switch type {
        case .title, .description:
            return CreateSessionStepsHeight.compact.rawValue
        case .date, .duration:
            return CreateSessionStepsHeight.small.rawValue
        default:
            return CreateSessionStepsHeight.standart.rawValue
        }
    }
    
    static func detailedHeight(forStepType stepType: CreateSessionSteps?) -> CGFloat {
        guard let type = stepType else {
            return CreateCourseStepsHeight.standart.rawValue
        }
        
        switch type {
        case .title, .description:
            return CreateSessionStepsHeight.large.rawValue
        case .date:
            return CreateSessionStepsHeight.compact.rawValue
        case .duration:
            return CreateSessionStepsHeight.standart.rawValue
        default:
            return CreateSessionStepsHeight.standart.rawValue
        }
    }
}

class CreateSessionModelViewController: TroovyViewController {
    
    // MARK: Properties Overriders
    
    override var prefersStatusBarHidden: Bool {
        if let parent = self.parent {
            return parent.prefersStatusBarHidden
        } else if let presentingViewController = self.presentingViewController {
            if let router = self.router as? TroovyRouter, let navigationController = router.rootNavigationController, let lastViewController = navigationController.viewControllers.last {
                return lastViewController.prefersStatusBarHidden
            } else if let navigationController = presentingViewController as? UINavigationController, let lastViewController = navigationController.viewControllers.last {
                return lastViewController.prefersStatusBarHidden
            }
            return presentingViewController.prefersStatusBarHidden
        }
        return false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if let parent = self.parent {
            return parent.preferredStatusBarStyle
        } else if let presentingViewController = self.presentingViewController {
            if let router = self.router as? TroovyRouter, let navigationController = router.rootNavigationController, let lastViewController = navigationController.viewControllers.last {
                return lastViewController.preferredStatusBarStyle
            } else if let navigationController = presentingViewController as? UINavigationController, let lastViewController = navigationController.viewControllers.last {
                return lastViewController.preferredStatusBarStyle
            }
            return presentingViewController.preferredStatusBarStyle
        }
        return .lightContent
    }

    // MARK: Interface Builder Properties
    
    @IBOutlet weak var containerView: UIView!
    
    // MARK: Public Properties
    
    /// Delegate. Responds to CreateSessionDelegate.
    weak var delegate: CreateSessionDelegate?
    
    /// Model of the unauthorised user.
    var authorisedUserModel: AuthorisedUserModel?
    
    /// Model of the course session. Course session will be edited if model exists or created otherwise.
    var courseSessionModel: CourseSessionModel?
    
    /// True if session should be editable without restrictions.
    var courseSessionAlwaysEditable: Bool = false
    
    // MARK: Private Properties
    
    private var onSelection: ((_ assets: [DKAsset]) -> Void)?
    private var maxSelectableCount: Int = 0
    
    private var sessionsViewController: UIViewController?
    
    // MARK: Init Methods & Superclass Overriders
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.createSessionViewController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.turnOffKeyboardManager()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.turnOnKeyboardManager()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.sessionsViewController?.view.frame = self.containerView.bounds
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: Private Properties
    
    private func turnOnKeyboardManager() {
        IQKeyboardManager.shared().isEnabled = true
        IQKeyboardManager.shared().shouldResignOnTouchOutside = true
    }
    
    private func turnOffKeyboardManager() {
        IQKeyboardManager.shared().isEnabled = false
        IQKeyboardManager.shared().shouldResignOnTouchOutside = false
    }
    
    private func createSessionViewController() {
        self.sessionsViewController = self.sessionsController()
        
        if let sessionsViewController = self.sessionsViewController {
            self.addChildViewController(sessionsViewController)
            sessionsViewController.beginAppearanceTransition(true, animated: true)
            sessionsViewController.view.frame = self.containerView.bounds
            self.containerView.addSubview(sessionsViewController.view)
            sessionsViewController.endAppearanceTransition()
            sessionsViewController.didMove(toParentViewController: self)
        }
    }
    
    private func sessionsController() -> UIViewController {
        if self.courseSessionModel != nil {
            let viewController = self.storyboard?.instantiateViewController(withIdentifier: "EditSessionViewController") as! CreateSessionViewController
            viewController.router = self.router
            viewController.authorisedUserModel = self.authorisedUserModel
            viewController.courseSessionModel = self.courseSessionModel
            viewController.courseSessionAlwaysEditable = self.courseSessionAlwaysEditable
            viewController.delegate = self.delegate
            return viewController
        } else {
            let viewController = self.storyboard?.instantiateViewController(withIdentifier: "CreateSessionViewController") as! CreateSessionViewController
            viewController.router = self.router
            viewController.authorisedUserModel = self.authorisedUserModel
            viewController.courseSessionModel = self.courseSessionModel
            viewController.courseSessionAlwaysEditable = self.courseSessionAlwaysEditable
            viewController.delegate = self.delegate
            return viewController
        }
    }
    
    // MARK: Controls Actions
    
    @IBAction func panGestureAction(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: self.view)
        let verticalMovement = translation.y / self.view.bounds.height
        let downwardMovement = fmaxf(Float(verticalMovement), 0.0)
        let downwardMovementPercent = fminf(downwardMovement, 1.0)
        let progress = CGFloat(downwardMovementPercent)
        
        switch sender.state {
        case .began:
            let velocity = sender.velocity(in: self.containerView)
            if velocity.x > self.containerView.frame.height / 3.0 {
                self.dismiss(animated: true, completion: nil)
                sender.isEnabled = false
            } else {
                self.customModalTransition?.beginInteractiveDismissalTransition(completion: nil)
            }
            break
        case .changed:
            self.customModalTransition?.updateInteractiveTransitionToProgress(progress: progress)
            break
        case .ended:
            if progress >= 0.3 {
                self.customModalTransition?.finishInteractiveTransition()
            } else {
                self.customModalTransition?.cancelInteractiveTransition()
            }
            break
        default:
            self.customModalTransition?.cancelInteractiveTransition()
            break
        }
    }

}
