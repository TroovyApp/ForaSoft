//
//  UploadAttachmentViewController.swift
//  troovy-ios
//
//  Created by Daniil on 25.09.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class UploadAttachmentViewController: TroovyViewController {
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var progressView: ProgressView!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var cancelButtonHeight: NSLayoutConstraint!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: Public Properties
    
    /// Model of the unauthorised user.
    var authorisedUserModel: AuthorisedUserModel?
    
    /// Model of the course.
    var courseModel: CourseModel!
    
    /// Model of the course attachment.
    var attachmentModel: CourseAttachmentModel!
    
    // MARK: Private Properties
    
    private var coursesService: CoursesService!
    private var createCoursesService: CreateCoursesService!
    
    private var createAttachmentMethod: String?

    // MARK: Init Methods & Superclass Overriders
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive(_:)), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(_:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        self.applyProgress(0.0)
        self.createAttachmentMethod = self.createCoursesService.uploadCourseAttachment(withModel: self.attachmentModel, user: self.authorisedUserModel)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
        
        UIApplication.shared.isIdleTimerDisabled = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func inject(propertiesWithAssembly assembly: ViewControllerAssemblyManager) {
        self.coursesService = assembly.coursesService
        self.createCoursesService = assembly.createCoursesService
    }
    
    override func configureServices() {
        self.createCoursesService.delegate = self
    }
    
    override func serviceStateChanged(withActionResult result: ServiceActionResult) {
        switch result {
        case .methodStarted(let method):
            if method == self.createAttachmentMethod {
                self.applyProgress(0.0)
            }
            break
        case .methodSucceededWithResponseDictionary(let method, let resultDictionary):
            if method == self.createAttachmentMethod {
                self.serviceMethodSucceeded(withMethod: method, resultDictionary: resultDictionary, resultArray: nil, resultString: nil)
            }
            break
        case .methodProgressedWithProgress(let method, let progress):
            if method == self.createAttachmentMethod {
                self.applyProgress(progress)
            }
            break
        case .methodFailed(let method, let error):
            if method == self.createAttachmentMethod {
                self.showDismissalAlert(withTitle: ApplicationMessages.AlertTitles.message, message: error)
            }
            break
        case .methodCancelled(_):
            break
        default:
            super.serviceStateChanged(withActionResult: result)
            break
        }
    }
    
    override func serviceMethodSucceeded(withMethod method: String, resultDictionary: [String : Any]?, resultArray: [[String : Any]]?, resultString: String?) {
        if method == self.createAttachmentMethod {
            if let attachmentDictionary = resultDictionary {
                let attachment = CourseAttachmentModel(withDictionary: attachmentDictionary)
                
                self.courseModel.update(byAppendingAttachment: attachment)
                self.coursesService.saveOwnCourseAttachment(withModel: attachmentModel, forCourse: self.courseModel)
            }
            
            self.presentingViewController?.dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: Notifications & Observers
    
    @objc private func applicationWillResignActive(_ notification: Notification) {
        self.createCoursesService.pauseUploadCourseResources()
    }
    
    @objc private func applicationDidBecomeActive(_ notification: Notification) {
        self.createCoursesService.resumeUploadCourseResources()
    }
    
    // MARK: Private Methods
    
    private func applyProgress(_ progress: Double) {
        let percents = round(progress * 100)
        
        if percents >= 90.0 {
            if self.cancelButtonHeight.constant != 0.0 {
                self.cancelButtonHeight.constant = 0.0
                
                UIView.animate(withDuration: 0.25, animations: {
                    self.view.layoutIfNeeded()
                    self.cancelButton.alpha = 0.0
                }, completion: { (success) in
                    self.cancelButton.isHidden = true
                })
            }
        }
        
        self.progressView.progress = CGFloat(progress)
        
        if percents >= 100.0 {
            self.progressLabel.text = nil
            self.activityIndicator.startAnimating()
        } else {
            self.progressLabel.text = "\(percents.tailingZeros()) %"
        }
    }
    
    private func showDismissalAlert(withTitle title: String, message: String?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: ApplicationMessages.AlertButtonsTitles.close, style: .cancel, handler: { [weak self] (action) in
            self?.presentingViewController?.dismiss(animated: true, completion: nil)
        }))
        self.present(alertController, animated: true, completion: nil)
    }
    
    // MARK: Controls Actions
    
    @IBAction override func closeButtonAction(_ sender: UIButton) {
        self.createCoursesService.cancelUploadCourseResources()
        
        super.closeButtonAction(sender)
    }
    
}
