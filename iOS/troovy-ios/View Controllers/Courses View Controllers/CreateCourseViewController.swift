//
//  CreateCourseViewController.swift
//  troovy-ios
//
//  Created by Daniil on 25.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

import EMPageViewController
import IQKeyboardManager

enum CreateCourseSteps: Int {
    case title = 0
    case description
    case media
    case price
    case count
}

enum CreateCourseStepsHeight: CGFloat {
    case standart = 80.0
    case compact = 56.0
    case large = 121.0
    
    static func normalHeight(forStepType stepType: CreateCourseSteps?) -> CGFloat {
        guard let type = stepType else {
            return CreateCourseStepsHeight.standart.rawValue
        }
        
        switch type {
        case .title, .description:
            return CreateCourseStepsHeight.compact.rawValue
        case .media:
            return CreateCourseStepsHeight.compact.rawValue
        case .price:
            return CreateCourseStepsHeight.compact.rawValue
        default:
            return CreateCourseStepsHeight.standart.rawValue
        }
    }
    
    static func detailedHeight(forStepType stepType: CreateCourseSteps?) -> CGFloat {
        guard let type = stepType else {
            return CreateCourseStepsHeight.standart.rawValue
        }
        
        switch type {
        case .title, .description:
            return CreateCourseStepsHeight.standart.rawValue
        case .media:
            return CreateCourseStepsHeight.large.rawValue
        case .price:
            return CreateCourseStepsHeight.standart.rawValue
        default:
            return CreateCourseStepsHeight.standart.rawValue
        }
    }
}

class CreateCourseViewController: TroovyViewController, EMPageViewControllerDelegate, EMPageViewControllerDataSource, CreateCourseDelegate, CreateSessionDelegate, CourseDeleteIntroDelegate {
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var segmentedControl: NLSegmentControl!
    @IBOutlet weak var topSeparatorView: UIView!
    
    @IBOutlet weak var deleteContainerView: UIView!
    @IBOutlet weak var deleteView: UIView!
    @IBOutlet weak var deleteHeaderView: ShadowView!
    @IBOutlet weak var deleteGradientView: ShadowView!
    
    // MARK: Public Properties
    
    /// Model of the unauthorised user.
    var authorisedUserModel: AuthorisedUserModel!
    
    /// Model of the unfinished course. Course creation will be continued if model exists.
    var unfinishedCourseModel: UnfinishedCourseModel?
    
    // MARK: Private Properties
    
    private var verificationService: VerificationService!
    private var createCoursesService: CreateCoursesService!
    private var coursesService: CoursesService!
    private var paymentService: PaymentService!
    
    private var listAnimationPerformed = false
    private var deleteViewInDeletableZone = false
    
    private var pageViewController: EMPageViewController!
    private var createCoursePages: [UIViewController] = []
    
    private var createCourseMethod: String?
    
    // MARK: Init Methods & Superclass Overriders
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.titleLabel.text = ApplicationMessages.ScreenTitles.createCourseScreen
        
        self.deleteContainerView.alpha = 0.0
        self.deleteHeaderView.setupGradientShadow(fromColor: UIColor(white: 1.0, alpha: 1.0), toColor: UIColor(white: 1.0, alpha: 1.0))
        self.deleteGradientView.setupGradientShadow(fromColor: UIColor(white: 1.0, alpha: 1.0), toColor: UIColor(white: 1.0, alpha: 0.0))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.setupSegmentedControl()
        self.setupCreateCoursePages()
        self.turnOffKeyboardManager()
        
        _ = self.checkFieldsFilled()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.turnOnKeyboardManager()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let pageViewController = segue.destination as? EMPageViewController {
            self.pageViewController = pageViewController
            self.pageViewController.view.clipsToBounds = false
            self.pageViewController.scrollView.clipsToBounds = false
            self.pageViewController.delegate = self
            self.pageViewController.dataSource = self
        }
    }
    
    override func inject(propertiesWithAssembly assembly: ViewControllerAssemblyManager) {
        self.verificationService = assembly.verificationService
        self.createCoursesService = assembly.createCoursesService
        self.coursesService = assembly.coursesService
        self.paymentService = assembly.paymentService
    }
    
    override func configureServices() {
        self.createCoursesService.delegate = self
    }
    
    override func serviceMethodSucceeded(withMethod method: String, resultDictionary: [String : Any]?, resultArray: [[String:Any]]?, resultString: String?) {
        if method == self.createCourseMethod {
            var createdCourse: CourseModel?
            if let courseDictionary = resultDictionary {
                let course = CourseModel(withDictionary: courseDictionary)
                _ = self.coursesService.saveOwnCourse(course)
                
                createdCourse = course
                
                NotificationCenter.default.post(name: Notification.Name(CreateCoursesNotificationNames.subscribedSessionsChanged), object: nil)
            }
            
            if let course = createdCourse, let unfinishedCourseModel = self.unfinishedCourseModel, let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first, let mediaFilenames = self.unfinishedCourseModel?.mediaFilenames, mediaFilenames.count > 0 {
                self.router.showUploadCourseIntroScreen(withAuthorisedUserModel: self.authorisedUserModel, courseModel: course, introFilePath: documentsPath, courseCreation: true, unfinishedCourseModel: unfinishedCourseModel)
            } else {
                self.createCoursesService.deleteSavedCourseModel()
                self.router.routerShouldRelease()
                self.presentingViewController?.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    // MARK: Private Methods
    
    private func setupSegmentedControl() {
        if self.createCoursePages.count != 0 {
            return
        }
        
        self.segmentedControl.segments = ["Workshop info", "Sessions"]
        self.segmentedControl.selectionIndicatorStyle = .textWidthStripe
        self.segmentedControl.segmentWidthStyle = .fixed
        self.segmentedControl.selectionIndicatorColor = UIColor.tv_purpleColor()
        self.segmentedControl.selectionIndicatorHeight = 3.0
        self.segmentedControl.selectionIndicatorPosition = .bottom
        self.segmentedControl.selectionIndicatorEdgeInset = UIEdgeInsetsMake(0.0, -3.5, 0.0, -3.5)
        self.segmentedControl.segmentEdgeInset = UIEdgeInsetsMake(-10.0, 0.0, 0.0, 0.0)
        self.segmentedControl.selectedTitleTextAttributes = [NSAttributedStringKey.font : UIFont.systemFont(ofSize: 14.0, weight: .medium), NSAttributedStringKey.foregroundColor : UIColor.tv_purpleColor()]
        self.segmentedControl.titleTextAttributes = [NSAttributedStringKey.font : UIFont.systemFont(ofSize: 14.0, weight: .regular), NSAttributedStringKey.foregroundColor : UIColor.tv_grayTextColor()]
        self.segmentedControl.indexChangedHandler = { [weak self] (index) in
            self?.segmentedControlDidChange(index)
        }
        
        self.segmentedControl.reloadSegments()
        self.segmentedControl.layoutIfNeeded()
    }
    
    private func setupCreateCoursePages() {
        if self.createCoursePages.count != 0 {
            return
        }
        
        let createCourseMainInfoViewController = self.storyboard?.instantiateViewController(withIdentifier: "CreateCourseMainInfoViewController") as! CreateCourseMainInfoViewController
        createCourseMainInfoViewController.configure(withDelegate: self, deleteDelegate: self)
        self.createCoursePages.append(createCourseMainInfoViewController)
        
        let createCourseSessionsViewController = self.storyboard?.instantiateViewController(withIdentifier: "CreateCourseSessionsViewController") as! CreateCourseSessionsViewController
        createCourseSessionsViewController.configure(withDelegate: self)
        self.createCoursePages.append(createCourseSessionsViewController)
        
        if let firstViewController = self.createCoursePages.first {
            self.pageViewController.selectViewController(firstViewController, direction: .forward, animated: false, completion: nil)
        }
    }
    
    private func turnOnKeyboardManager() {
        IQKeyboardManager.shared().isEnabled = true
        IQKeyboardManager.shared().shouldResignOnTouchOutside = true
    }
    
    private func turnOffKeyboardManager() {
        IQKeyboardManager.shared().isEnabled = false
        IQKeyboardManager.shared().shouldResignOnTouchOutside = false
    }
    
    // MARK: Verification Methods
    
    private func checkFieldsFilled() -> Bool {
        let courseTitle = self.verificationService.check(string: self.unfinishedCourseModel!.title)
        let courseDescription = self.verificationService.check(string: self.unfinishedCourseModel!.description)
        let courseSessionsCount = self.unfinishedCourseModel!.sessions.count
        let sessionsIsValid = self.checkSessionsTiming()
        
        if courseTitle != nil && courseDescription != nil && courseSessionsCount >= self.verificationService.minimumCountOfSessions() && sessionsIsValid {
            return true
        } else {
            return false
        }
    }
    
    private func checkFieldsInfo(courseWillBePublished willBePublished: Bool) {
        let courseTitle = self.verificationService.check(string: self.unfinishedCourseModel!.title)
        let courseDescription = self.verificationService.check(string: self.unfinishedCourseModel!.description)
        let courseSessionsCount = self.unfinishedCourseModel!.sessions.count
        let coursePriceTierString = self.verificationService.check(string: self.unfinishedCourseModel!.priceTier)
        let courseSessionsIsValid = self.checkSessionsTiming()
        
        if courseTitle != nil && courseDescription != nil && courseSessionsIsValid && (coursePriceTierString != nil || !willBePublished) && (courseSessionsCount >= self.verificationService.minimumCountOfSessions() || !willBePublished) {
            self.createCourseMethod = self.createCoursesService.createCourse(withUnfinishedCourse: self.unfinishedCourseModel!, user: self.authorisedUserModel, andPublish: willBePublished)
        } else {
            self.showError(withCourseTitle: courseTitle, courseDescription: courseDescription, courseSessionsCount: courseSessionsCount, coursePrice: coursePriceTierString, sessionsIsValid: courseSessionsIsValid, willBePublished: willBePublished)
        }
    }
    
    private func showError(withCourseTitle courseTitle: String?, courseDescription: String?, courseSessionsCount: Int, coursePrice: String?, sessionsIsValid: Bool, willBePublished: Bool) {
        var messages: [String] = []
        
        if courseTitle == nil || courseTitle?.count == 0 {
            messages.append(ApplicationMessages.ErrorMessages.wrongCourseTitle)
        }
        
        if courseDescription == nil || courseDescription?.count == 0 {
            messages.append(ApplicationMessages.ErrorMessages.wrongCourseDescription)
        }
        
        if courseSessionsCount == 0 {
            messages.append(ApplicationMessages.ErrorMessages.wrongCourseSessionsCount(withMinCount: self.verificationService.minimumCountOfSessions()))
        }
        
        if coursePrice == nil && willBePublished {
            messages.append(ApplicationMessages.ErrorMessages.wrongCoursePrice(withMinCount: self.verificationService.courseMinimumPrice()))
        }
        
        if !sessionsIsValid {
            messages.append(ApplicationMessages.ErrorMessages.wrongCourseSessionsTiming)
        }
        
        if messages.count > 0 {
            self.showAlert(withErrorsMessages: messages)
        }
    }
    
    private func checkSessionsTiming() -> Bool {
        if let sessions = self.unfinishedCourseModel?.sessions {
            for session in sessions {
                let currentTimeInterval = Int64(Date().timeIntervalSince1970)
                let sessionTimeInterval = session.startTimestamp!
                
                if currentTimeInterval >= sessionTimeInterval {
                    return false
                }
            }
        }
        
        return true
    }
    
    private func showPermissionAlert(withMicrophonePermission microphone: Bool, camera: Bool, photos: Bool) {
        let title = (!photos ? ApplicationMessages.AlertTitles.photosPermissionDenied : (((!microphone && !camera) ? ApplicationMessages.AlertTitles.cameraAndMicrophonePermissionDenied : (!microphone ? ApplicationMessages.AlertTitles.microphonePermissionDenied  : ApplicationMessages.AlertTitles.cameraPermissionDenied))))
        let message = ApplicationMessages.ErrorMessages.mediaPermissions
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: ApplicationMessages.AlertButtonsTitles.close, style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: ApplicationMessages.AlertButtonsTitles.settings, style: .default, handler: { [weak self] (action) in
            self?.openSettings()
        }))
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func checkRectInDeletableZone(_ rect: CGRect) -> Bool {
        return self.deleteView.frame.contains(rect)
    }
    
    // MARK: Controls Actions
    
    override func closeButtonAction(_ sender: UIButton) {
        self.router.routerShouldRelease()
        
        super.closeButtonAction(sender)
    }
    
    private func segmentedControlDidChange(_ index: Int) {
        self.view.endEditing(true)
        
        guard let selectedViewController = self.pageViewController.selectedViewController, let viewControllerIndex = self.createCoursePages.index(of: selectedViewController) else {
            return
        }
        
        if index >= 0 && index < self.createCoursePages.count {
            if self.listAnimationPerformed {
                return
            }
            
            self.listAnimationPerformed = true
            
            let newViewController = self.createCoursePages[index]
            let direction = (viewControllerIndex <= index ? EMPageViewControllerNavigationDirection.forward : EMPageViewControllerNavigationDirection.reverse)
            
            self.pageViewController.selectViewController(newViewController, direction: direction, animated: true, completion: nil)
        }
    }
    
    // MARK: Protocols Implementation
    
    // MARK: CourseDeleteIntroDelegate
    
    internal func coursePage(_ page: UIViewController, didBeginMoveDeletableView view: UIView, atPoint: CGPoint) {
        let convertedPoint = page.view.convert(atPoint, to: self.view)
        view.center = convertedPoint
        self.view.addSubview(view)
        
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .beginFromCurrentState, animations: {
            self.deleteContainerView.alpha = 1.0
        }, completion: nil)
    }
    
    internal func coursePage(_ page: UIViewController, didMoveDeletableViewToFrame frame: CGRect) {
        let rectInDeletableZone = self.checkRectInDeletableZone(frame)
        
        if rectInDeletableZone != self.deleteViewInDeletableZone {
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .beginFromCurrentState, animations: {
                if rectInDeletableZone {
                    self.deleteHeaderView.animateGradientShadow(fromColor: UIColor.tv_redColor(), toColor: UIColor.tv_redColor())
                    self.deleteGradientView.animateGradientShadow(fromColor: UIColor.tv_redColor(), toColor: UIColor.tv_redColor().withAlphaComponent(0.0))
                } else {
                    self.deleteHeaderView.animateGradientShadow(fromColor: UIColor(white: 1.0, alpha: 1.0), toColor: UIColor(white: 1.0, alpha: 1.0))
                    self.deleteGradientView.animateGradientShadow(fromColor: UIColor(white: 1.0, alpha: 1.0), toColor: UIColor(white: 1.0, alpha: 0.0))
                }
            }, completion: nil)
        }
        
        self.deleteViewInDeletableZone = rectInDeletableZone
    }
    
    internal func coursePage(_ page: UIViewController, shouldDeleteViewWithFrame frame: CGRect) -> Bool {
        self.deleteViewInDeletableZone = false
        
        return self.checkRectInDeletableZone(frame)
    }
    
    internal func coursePage(_ page: UIViewController, didEndMoveDeletableViewAnimated animated: Bool) {
        self.deleteViewInDeletableZone = false
        
        if animated {
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .beginFromCurrentState, animations: {
                self.deleteContainerView.alpha = 0.0
                self.deleteHeaderView.animateGradientShadow(fromColor: UIColor(white: 1.0, alpha: 1.0), toColor: UIColor(white: 1.0, alpha: 1.0))
                self.deleteGradientView.animateGradientShadow(fromColor: UIColor(white: 1.0, alpha: 1.0), toColor: UIColor(white: 1.0, alpha: 0.0))
            }, completion: nil)
        } else {
            self.deleteContainerView.alpha = 0.0
            self.deleteHeaderView.animateGradientShadow(fromColor: UIColor(white: 1.0, alpha: 1.0), toColor: UIColor(white: 1.0, alpha: 1.0))
            self.deleteGradientView.animateGradientShadow(fromColor: UIColor(white: 1.0, alpha: 1.0), toColor: UIColor(white: 1.0, alpha: 0.0))
        }
    }
    
    // MARK: EMPageViewControllerDelegate & EMPageViewControllerDataSource
    
    internal func em_pageViewController(_ pageViewController: EMPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        if let viewControllerIndex = self.createCoursePages.index(of: viewController) {
            let newIndex = viewControllerIndex - 1
            if newIndex >= 0 && newIndex < self.createCoursePages.count {
                let newViewController = self.createCoursePages[newIndex]
                return newViewController
            }
        }
        
        return nil
    }
    
    internal func em_pageViewController(_ pageViewController: EMPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        if let viewControllerIndex = self.createCoursePages.index(of: viewController) {
            let newIndex = viewControllerIndex + 1
            if newIndex >= 0 && newIndex < self.createCoursePages.count {
                let newViewController = self.createCoursePages[newIndex]
                return newViewController
            }
        }
        
        return nil
    }
    
    internal func em_pageViewController(_ pageViewController: EMPageViewController, didFinishScrollingFrom startingViewController: UIViewController?, destinationViewController:UIViewController, transitionSuccessful: Bool) {
        if !transitionSuccessful {
            return
        }
        
        if let viewControllerIndex = self.createCoursePages.index(of: destinationViewController) {
            self.listAnimationPerformed = false
            
            self.segmentedControl.setSelectedSegmentIndex(viewControllerIndex, animated: true)
        }
    }
    
    // MARK: CreateCourseDelegate
    
    internal func currentCourseModel() -> UnfinishedCourseModel {
        if self.unfinishedCourseModel == nil {
            if let savedCourseModel = self.createCoursesService.savedCourseModel() {
                self.unfinishedCourseModel = savedCourseModel
            } else {
                self.unfinishedCourseModel = UnfinishedCourseModel()
            }
        }
        
        return self.unfinishedCourseModel!
    }
    
    internal func coursePage(page: UIViewController, didChangeCourseModel model: UnfinishedCourseModel) {
        self.unfinishedCourseModel = model
        
        _ = self.checkFieldsFilled()
        self.createCoursesService.saveCourseModel(withCourseModel: self.unfinishedCourseModel!)
    }
    
    internal func coursePage(page: UIViewController, didChangeCourseWithContent content: [Any], forCourseModel model: UnfinishedCourseModel, mediaIndex: Int) {
        self.showLoadingView()
        
        DispatchQueue.main.async {
            var mediaFilenames: [String] = self.unfinishedCourseModel!.mediaFilenames ?? []
            
            if content.count > 0 {
                var index = mediaIndex
                for object in content {
                    self.createCoursesService.deleteCourseMedia(withCourseModel: self.unfinishedCourseModel!, atIndex: index)
                    
                    let image = object as? UIImage
                    let videoURL = object as? URL
                    if let filename = self.createCoursesService.saveCoursePreview(withImage: image, videoURL: videoURL) {
                        if mediaFilenames.count > index {
                            mediaFilenames[index] = filename
                        } else {
                            mediaFilenames.insert(filename, at: index)
                        }
                    } else {
                        if mediaFilenames.count > index {
                            mediaFilenames.remove(at: index)
                        }
                    }
                    
                    index += 1
                }
            } else {
                self.createCoursesService.deleteCourseMedia(withCourseModel: self.unfinishedCourseModel!, atIndex: mediaIndex)
                if mediaFilenames.count > mediaIndex {
                    mediaFilenames.remove(at: mediaIndex)
                }
            }
            
            self.unfinishedCourseModel!.update(withMediaFilenames: mediaFilenames)
            self.createCoursesService.saveCourseModel(withCourseModel: self.unfinishedCourseModel!)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.hideLoadingView(withMethod: "didChangeCourseMedia")
            }
        }
    }
    
    internal func coursePageWantsNextPage(page: UIViewController) {
        guard let selectedViewController = self.pageViewController.selectedViewController, let viewControllerIndex = self.createCoursePages.index(of: selectedViewController) else {
            return
        }
        
        let nextViewControllerIndex = viewControllerIndex + 1
        
        if nextViewControllerIndex >= 0 && nextViewControllerIndex < self.createCoursePages.count {
            let newViewController = self.createCoursePages[nextViewControllerIndex]
            
            self.pageViewController.selectViewController(newViewController, direction: .forward, animated: true, completion: nil)
            self.segmentedControl.setSelectedSegmentIndex(nextViewControllerIndex, animated: true)
        }
    }
    
    internal func coursePageShouldTakeCoursePreviewFromCamera(page: UIViewController) {
        self.checkCameraPermission { [unowned self] (granted) in
            if granted {
                self.showLoadingView(withMethod: "coursePageShouldTakeCoursePreviewFromCamera")
                self.router.takeCoursePreviewFromCamera(withDelegate: page as! (UIImagePickerControllerDelegate & UINavigationControllerDelegate)) {
                    self.hideLoadingView(withMethod: "coursePageShouldTakeCoursePreviewFromCamera")
                }
            } else {
                self.showPermissionAlert(withMicrophonePermission: true, camera: false, photos: true)
            }
        }
    }
    
    internal func coursePageShouldTakeCoursePreviewFromCameraRoll(page: UIViewController, replacingExistOne: Bool, didSelect: ((_ assets: [DKAsset]) -> Void)?) {
        self.checkPhotosPermission { [unowned self] (granted) in
            if granted {
                var maxSelectableCount = (replacingExistOne ? 1: (3 - (self.unfinishedCourseModel?.mediaFilenames?.count ?? 0)))
                if maxSelectableCount <= 0 {
                    maxSelectableCount = 1
                }
                
                self.router.takeCoursePreviewFromCameraRoll(withDidSelect: didSelect, maxSelectableCount: maxSelectableCount, completion: nil)
            } else {
                self.showPermissionAlert(withMicrophonePermission: true, camera: true, photos: false)
            }
        }
    }
    
    internal func coursePageShouldShowLoadingView() {
        self.showLoadingView(withMethod: "coursePageShouldShowLoadingView")
    }
    
    internal func coursePageShouldHideLoadingView() {
        self.hideLoadingView(withMethod: "coursePageShouldHideLoadingView")
    }
    
    internal func coursePage(page: UIViewController, shouldOpenSessionModel model: CourseSessionModel?) {
        self.router.showCourseSessionScreen(withAuthorisedUserModel: self.authorisedUserModel, sessionModel: model, courseSessionAlwaysEditable: true, delegate: self)
    }
    
    internal func coursePageShouldCreateCourse(page: UIViewController) {
        self.checkFieldsInfo(courseWillBePublished: false)
    }
    
    internal func coursePageShouldPublishCourse(page: UIViewController) {
        self.checkFieldsInfo(courseWillBePublished: false)
    }
    
    internal func coursePageReadyForPublish(page: UIViewController) -> Bool {
        return self.checkFieldsFilled()
    }
    
    internal func coursePage(page: UIViewController, checkVideoWithPickerInfo info: [String : Any]) -> String? {
        var errorMessage: String?
        var libraryVideo = false
        if (info[UIImagePickerControllerReferenceURL] as? URL) != nil {
            libraryVideo = true
        }
        
        if let mediaURL = info[UIImagePickerControllerMediaURL] as? URL {
            if libraryVideo {
                if self.verificationService.check(libraryCourseVideoURL: mediaURL) == nil {
                    errorMessage = ApplicationMessages.ErrorMessages.wrongCourseVideoSize(withMaxSize: self.verificationService.maximumLibraryCourseVideoSize())
                }
            } else {
                if self.verificationService.check(cameraCourseVideoURL: mediaURL) == nil {
                    errorMessage = ApplicationMessages.ErrorMessages.wrongCourseVideoDuration(withMinDuration: self.verificationService.minimumCameraCourseVideoDuration())
                }
            }
        }
        
        return errorMessage
    }
    
    internal func coursePage(page: UIViewController, shouldShowAlertWithMessages messages: [String]) {
        self.showAlert(withErrorsMessages: messages)
    }
    
    internal func coursePage(page: UIViewController, shouldShowAlertWithMessage message: String) {
        self.showAlert(withTitle: ApplicationMessages.AlertTitles.message, message: message)
    }
    
    internal func coursePageRequestСommissionPercentage(page: UIViewController) -> Double {
        return self.paymentService.courseCommisionPercentage()
    }
    
    // MARK: CreateSessionDelegate
    
    internal func sessionView(view: UIViewController, didChangeCourseSessionModel model: CourseSessionModel) {
        self.unfinishedCourseModel!.update(byReplacingSession: model)
        self.createCoursesService.saveCourseModel(withCourseModel: self.unfinishedCourseModel!)
        
        if let selectedViewController = self.pageViewController.selectedViewController as? CreateCourseSessionsViewController {
            selectedViewController.configure(withDelegate: self)
        }
        
        _ = self.checkFieldsFilled()
    }
    
    internal func sessionView(view: UIViewController, didCreateCourseSessionModel model: CourseSessionModel) {
        self.unfinishedCourseModel!.update(byAppendingSession: model)
        self.createCoursesService.saveCourseModel(withCourseModel: self.unfinishedCourseModel!)
        
        if let selectedViewController = self.pageViewController.selectedViewController as? CreateCourseSessionsViewController {
            selectedViewController.configure(withDelegate: self)
        }
        
        _ = self.checkFieldsFilled()
    }
    
    internal func sessionView(view: UIViewController, checkNewSessionModelDoesNotConflictWithOthers model: CourseSessionModel) -> Bool {
        guard let sessions = self.unfinishedCourseModel?.sessions else {
            return true
        }
        
        for session in sessions {
            if (model.id != nil && session.id != nil && model.id == session.id) || (model.identifier == session.identifier) {
                continue
            }
            
            let newSessionStartInterval = model.startTimestamp!
            let newSessionEndInterval = model.startTimestamp! + Int64((model.duration! * 60))
            
            let sessionStartInterval = session.startTimestamp!
            let sessionEndInterval = session.startTimestamp! + Int64((session.duration! * 60))
            
            if (newSessionStartInterval >= sessionStartInterval && newSessionStartInterval < sessionEndInterval) || (newSessionEndInterval > sessionStartInterval && newSessionEndInterval <= sessionEndInterval) {
                return false
            }
        }
        
        return true
    }
    
    internal func sessionViewSelectedCourseID(view: UIViewController) -> String? {
        return nil
    }

}
