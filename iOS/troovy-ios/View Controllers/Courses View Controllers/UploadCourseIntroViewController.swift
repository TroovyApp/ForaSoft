//
//  UploadCourseIntroViewController.swift
//  troovy-ios
//
//  Created by Daniil on 04.10.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class UploadCourseIntroViewController: TroovyViewController {

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
    
    /// Intro folder path.
    var introFilePath: String!
    
    /// Determines if a course is being created
    var courseCreation: Bool = false
    
    /// New model of the course.
    var unfinishedCourseModel: UnfinishedCourseModel!
    
    // MARK: Private Properties
    
    private var coursesService: CoursesService!
    private var createCoursesService: CreateCoursesService!
    
    private var courseIntroIndex: Int = 0
    private var uploadIntroOrder: Int = 0
    private var uploadIntrosCount: Int = 0
    private var uploadedIntros: [CourseIntroModel] = []
    
    private var createCourseIntroMethod: String?
    private var uploadCourseIntroMethod: String?
    private var publishCourseMethod: String?
    private var deleteCourseMethod: String?
    
    // MARK: Init Methods & Superclass Overriders
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let mediaFilenames = self.unfinishedCourseModel.mediaFilenames {
            var uploadedIntrosCount = 0
            for intro in self.courseModel.intros {
                for filename in mediaFilenames {
                    if intro.id == filename {
                        uploadedIntrosCount += 1
                        break
                    }
                }
            }
            
            self.uploadIntrosCount = mediaFilenames.count - uploadedIntrosCount
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive(_:)), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(_:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        self.applyProgress(0.0)
        self.createIntro(withIndex: self.courseIntroIndex)
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
            if method == self.uploadCourseIntroMethod {
                let uploadsCount = Double(self.uploadIntrosCount)
                let newProgress = (1.0 / uploadsCount) * Double(self.uploadIntroOrder)
                self.applyProgress(newProgress)
            }
            break
        case .methodSucceededWithResponseDictionary(let method, let resultDictionary):
            if method == self.uploadCourseIntroMethod || method == self.createCourseIntroMethod || method == self.publishCourseMethod || method == self.deleteCourseMethod {
                self.serviceMethodSucceeded(withMethod: method, resultDictionary: resultDictionary, resultArray: nil, resultString: nil)
            }
            break
        case .methodProgressedWithProgress(let method, let progress):
            if method == self.uploadCourseIntroMethod {
                let uploadsCount = Double(self.uploadIntrosCount)
                let newProgress = ((1.0 / uploadsCount) * Double(self.uploadIntroOrder)) + ((1.0 / uploadsCount) * progress)
                self.applyProgress(newProgress)
            }
            break
        case .methodFailed(let method, let error):
            if method == self.uploadCourseIntroMethod || method == self.createCourseIntroMethod {
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
        if method == self.createCourseIntroMethod {
            if let introDictionary = resultDictionary {
                let intro = CourseIntroModel(withDictionary: introDictionary)
                self.uploadIntro(withIndex: self.courseIntroIndex, intro: intro)
            } else {
                self.showDismissalAlert(withTitle: ApplicationMessages.AlertTitles.message, message: ApplicationMessages.ErrorMessages.serverError)
            }
        } else if method == self.uploadCourseIntroMethod {
            if let introDictionary = resultDictionary {
                let intro = CourseIntroModel(withDictionary: introDictionary)

                self.uploadedIntros.append(intro)
                self.courseIntroIndex += 1
                self.uploadIntroOrder += 1
                self.createIntro(withIndex: self.courseIntroIndex)
            } else {
                self.showDismissalAlert(withTitle: ApplicationMessages.AlertTitles.message, message: ApplicationMessages.ErrorMessages.serverError)
            }
        } else if method == self.publishCourseMethod {
            if let courseDictionary = resultDictionary {
                let course = CourseModel(withDictionary: courseDictionary)
                
                self.courseModel.update(withModel: course)
                self.coursesService.updateCourse(withModel: course)
                
                self.router.routerShouldRelease()
                self.dismissWithParent()
            }
        } else if method == self.deleteCourseMethod {
            self.presentingViewController?.dismiss(animated: true, completion: nil)
        }
    }
    
    override func serviceMethodFailed(withMethod method: String) {
        if method == self.publishCourseMethod {
            self.showAlert(withTitle: ApplicationMessages.AlertTitles.error, message: ApplicationMessages.ErrorMessages.unableCourseCreate)
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
    
    private func createIntro(withIndex index: Int) {
        if let mediaFilenames = self.unfinishedCourseModel.mediaFilenames, mediaFilenames.count > index {
            for intro in self.courseModel.intros {
                if intro.id == mediaFilenames[index] {
                    self.courseIntroIndex += 1
                    self.createIntro(withIndex: self.courseIntroIndex)
                    return
                }
            }
            
            let filename = mediaFilenames[index]
            let filePath = self.introFilePath + "/" + filename
            let fileURL = URL(fileURLWithPath: filePath)
            let fileExtension = "." + fileURL.pathExtension.lowercased()
            
            if fileExtension == ".png" || fileExtension == ".jpeg" {
                self.createCourseIntroMethod = self.createCoursesService.createCourseImageIntro(orCourseID: self.courseModel.id, introOrder: (index + 1), user: self.authorisedUserModel)
            } else {
                self.createCourseIntroMethod = self.createCoursesService.createCourseVideoIntro(orCourseID: self.courseModel.id, introOrder: (index + 1), user: self.authorisedUserModel)
            }
        } else {
            self.uploadFinished()
        }
    }
    
    private func uploadIntro(withIndex index: Int, intro: CourseIntroModel) {
        if let mediaFilenames = self.unfinishedCourseModel.mediaFilenames, mediaFilenames.count > index {
            let filename = mediaFilenames[index]
            let filePath = self.introFilePath + "/" + filename
            
            self.uploadCourseIntroMethod = self.createCoursesService.uploadCourseIntro(withFilePath: filePath, introID: intro.id, introType: intro.type.rawValue, user: self.authorisedUserModel)
        } else {
            self.uploadFinished()
        }
    }
    
    private func uploadFinished() {
        if let mediaFilenames = self.unfinishedCourseModel.mediaFilenames, mediaFilenames.count > 0, self.courseModel.intros.count > 0 {
            for index in 0..<mediaFilenames.count {
                for introIndex in 0..<self.courseModel.intros.count {
                    let intro = self.courseModel.intros[introIndex]
                    if intro.id == mediaFilenames[index] {
                        if self.uploadedIntros.count > index {
                            self.uploadedIntros.insert(intro, at: index)
                        } else {
                            self.uploadedIntros.append(intro)
                        }
                        break
                    }
                }
            }
        }
        
        self.courseModel.update(withIntros: self.uploadedIntros)
        self.coursesService.updateCourseIntros(withModels: self.uploadedIntros, forCourseID: self.courseModel.id)
        self.publishCourseMethod = self.createCoursesService.publishCourse(withCourseModel: self.courseModel, user: self.authorisedUserModel)
    }
    
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
            self?.uploadFinished()
        }))
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func dismissWithParent() {
        if self.courseCreation {
            self.createCoursesService.deleteSavedCourseModel()
        }
        
        self.createCoursesService.deleteCourseMedia(withCourseModel: self.unfinishedCourseModel!)
        
        if let parentPresentingViewController = self.presentingViewController?.presentingViewController {
            self.presentingViewController?.dismiss(animated: true, completion: {
                parentPresentingViewController.dismiss(animated: true, completion: nil)
            })
        } else {
            self.presentingViewController?.dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: Controls Actions
    
    @IBAction override func closeButtonAction(_ sender: UIButton) {
        self.createCoursesService.cancelUploadCourseResources()
        self.deleteCourseMethod = self.createCoursesService.deleteCourse(withCourseID: courseModel.id, ignoreSubscribers: true, user: authorisedUserModel)
//        self.router.routerShouldRelease()
//        self.dismissWithParent()
    }

}
