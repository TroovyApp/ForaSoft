//
//  CourseInfoViewController.swift
//  troovy-ios
//
//  Created by Vladimir on 14/09/2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit
import QuartzCore

import Kingfisher

class CourseInfoViewController: TroovyViewController, CourseModelDelegate, CreateSessionDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {
    
    internal enum CourseCellType: Int {
        case title = 0
        case subtitle
        case schedule
        case subscribe
        case description
        case attachments
        case createSession
        case sessions
        case earnings
    }
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var navigationControls: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var courseBackgroundView: CourseBackgroundView!
    @IBOutlet weak var navigationControlsEffectView: UIVisualEffectView!
    @IBOutlet weak var shadowView: ShadowView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var showCourseButton: UIButton!
    @IBOutlet weak var exitButton: UIButton!
    @IBOutlet weak var introPageControl: UIPageControl!
    @IBOutlet weak var showCourseButtonToBottom: NSLayoutConstraint!
    @IBOutlet weak var introPageControlToBottom: NSLayoutConstraint!
    
    // MARK: Public Properties
    
    /// Model of the unauthorised user.
    var authorisedUserModel: AuthorisedUserModel?
    
    /// Course server ID.
    var courseID: String!
    
    /// Model of the course.
    var courseModel: CourseModel? {
        willSet {
            self.courseModel?.removeDelegate(self)
        }
        didSet {
            self.courseModel?.delegate = self
        }
    }
    
    // MARK: Internal Properties
    
    /// Plist service.
    internal let infoPlistService = InfoPlistService()
    
    /// Verification service.
    internal var verificationService: VerificationService!
    
    /// Application service.
    internal var applicationService: ApplicationService!
    
    /// Cells types to be displayed.
    internal var cellsTypes: [CourseCellType] = []
    
    /// Sorted upcoming sessions.
    internal var upcomingSessions: [CourseSessionModel] = []
    
    /// Start index of sessions in cell types array.
    internal var sessionStartIndex: Int = 0
    
    /// Cells cached heights.
    internal var cellsHeights: [CourseCellType:CGFloat] = [:]
    
    /// Price number formatter.
    internal var numberFormatter: NumberFormatter!
    
    /// Date formatters.
    internal var dateMonthFormatter: DateFormatter!
    internal var dateNumberFormatter: DateFormatter!
    internal var dateTimeFormatter: DateFormatter!
    
    // MARK: Properties Overriders
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    // MARK: Private Properties
    
    private var firstLaunch = true
    private var modelChanged = false
    private var loadingCourse = false
    private var collectionViewLayouted = false
    private var courseSuccesfullyRequested = false
    private var scrollingToTop = false
    
    private var courseScrollProgress: CGFloat = 0.0
    
    private var visualEffectView: UIVisualEffectView?
    private var coursesService: CoursesService!
    private var createCoursesService: CreateCoursesService!
    
    private var deleteCourseMethod: String?
    private var loadCourseMethod: String?
    private var refreshControl: UIRefreshControl!
    
    // MARK: Init Methods & Superclass Overriders
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupNumberFormatter()
        self.setupDateFormatters()
        self.setupExitButton()
        self.setupCollectionView()
        
        refreshControl = UIRefreshControl()
        refreshControl.tintColor = .white
        refreshControl.addTarget(self, action: #selector(refreshInfo(sender:)),
                                 for: .valueChanged)

        self.collectionView.refreshControl = refreshControl
        self.collectionView.alwaysBounceVertical = true

        if #available(iOS 11.0, *) {
            self.collectionView?.contentInsetAdjustmentBehavior = .never
        }
    }
    
    @objc private func refreshInfo(sender: UIRefreshControl) {
        self.loadCourseInfo()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if self.firstLaunch || self.modelChanged  {
            self.firstLaunch = false
            self.modelChanged = false
            
            self.checkCourseLoaded()
        }
        
        self.courseBackgroundView.setIntrosPaused(false)
        self.setCourseScrollProgress(scrollProgress: self.courseScrollProgress)
        
        DispatchQueue.main.async {
            self.setupBlurEffect()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(_:)), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.collectionViewLayouted = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.collectionViewLayouted = false
        
        DispatchQueue.main.async {
            self.courseBackgroundView.setIntrosPaused(true)
        }
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        if #available(iOS 11.0, *) {
            let bottomEdgeInsets = self.view.safeAreaInsets.bottom
            if bottomEdgeInsets > 0 {
                self.showCourseButtonToBottom.constant = -6.0
                self.introPageControlToBottom.constant = -12.0
            } else {
                self.showCourseButtonToBottom.constant = 6.0
                self.introPageControlToBottom.constant = 0.0
            }
        } else {
            self.showCourseButtonToBottom.constant = 6.0
            self.introPageControlToBottom.constant = 0.0
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.visualEffectView?.frame = self.courseBackgroundView.bounds
        
        if !self.collectionViewLayouted {
            self.changeCollectionInsets()
            self.layoutCourseElements()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    deinit {
        self.coursesService.cancelCourseLoading()
    }
    
    override func inject(propertiesWithAssembly assembly: ViewControllerAssemblyManager) {
        self.verificationService = assembly.verificationService
        self.applicationService = assembly.applicationService
        self.coursesService = assembly.coursesService
        self.createCoursesService = assembly.createCoursesService
    }
    
    override func configureServices() {
        self.coursesService.delegate = self
        self.createCoursesService.delegate = self
    }
    
    override func serviceMethodSucceeded(withMethod method: String, resultDictionary: [String : Any]?, resultArray: [[String : Any]]?, resultString: String?) {
        if method == self.loadCourseMethod {
            if let info = resultDictionary {
                let course = CourseModel(withDictionary: info)
                if self.courseID == course.id {
                    if self.courseModel != nil {
                        self.courseModel!.update(withModel: course)
                    } else {
                        self.courseModel = course
                    }
                }
            }
            
            self.courseSuccesfullyRequested = true
            self.loadingCourse = false
            self.structCourseInfo()
            self.stopRefreshing()
        } else if method == self.deleteCourseMethod {
            let deletionResult = CourseDeletionResultModel(withDictionary: resultDictionary)
            if deletionResult.requireUserAction {
                self.showDeleteConfirmation(withMessage: deletionResult.message, ignoreSubscribers: true)
            } else {
                if let course = self.courseModel {
                    NotificationCenter.default.post(name: Notification.Name(CreateCoursesNotificationNames.subscribedSessionsChanged), object: nil)
                    
                    self.coursesService.deleteOwnCourse(course)
                    self.exit()
                }
            }
        }
    }
    
    override func serviceMethodFailed(withMethod method: String) {
        if method == self.loadCourseMethod {
            self.courseSuccesfullyRequested = false
            self.loadingCourse = false
            self.structCourseInfo()
            self.stopRefreshing()
        }
    }
    
    private func stopRefreshing() {
        DispatchQueue.main.async { [weak self] in
            self?.refreshControl.setRefreshing(false)
        }
    }
    
    private func startRefreshing() {
        DispatchQueue.main.async { [weak self] in
            self?.refreshControl.setRefreshing(true)
        }
    }
    
    override func showLoadingView(withMethod method: String) {
        if method == self.loadCourseMethod {
            if self.cellsTypes.count == 0 {
                if !self.activityIndicator.isAnimating {
                    self.activityIndicator.startAnimating()
                }
                
                self.collectionView.isHidden = true
                self.showCourseButton.isHidden = true
            } else {
                self.hideLoadingView(withMethod: method)
            }
        } else if method == self.deleteCourseMethod {
            super.showLoadingView(withMethod: method)
        }
    }
    
    override func hideLoadingView(withMethod method: String) {
        if method == self.loadCourseMethod {
            self.collectionView.isHidden = false
            self.showCourseButton.isHidden = !self.isMediaExists()
            
            if self.activityIndicator.isAnimating {
                self.activityIndicator.stopAnimating()
            }
        } else if method == self.deleteCourseMethod {
            super.hideLoadingView(withMethod: method)
        }
    }
    
    // MARK: Notifications & Observers
    
    @objc private func applicationWillEnterForeground(_ notification: Notification) {
        self.setupBlurEffect()
    }
    
    // MARK: Internal Methods
    
    /// Deletes course with confirmation.
    internal func deleteCourse(ignoreSubscribers: Bool) {
        self.showDeleteConfirmation(withMessage: nil, ignoreSubscribers: ignoreSubscribers)
    }
    
    /// Fills cellsTypes with cell types to be displayed.
    internal func structCourseInfo() {
        var upcomingSessions: [CourseSessionModel] = []
        if let sessions = self.courseModel?.sessions {
            let currentTimestamp = Int64(Date().timeIntervalSince1970)
            let sortedSessions = sessions.sorted { (firstSession, secondSession) -> Bool in
                return firstSession.startTimestamp < secondSession.startTimestamp
            }
            
            for session in sortedSessions {
                if session.startTimestamp > currentTimestamp {
                    upcomingSessions.append(session)
                }
            }
        }
        
        self.upcomingSessions = upcomingSessions
        self.courseBackgroundView.setup(withIntros: self.courseModel?.intros, pageControl: self.introPageControl)
        self.visualEffectView?.isHidden = !self.isMediaExists()
        self.shadowView.isHidden = !self.isMediaExists()
        self.showCourseButton.isHidden = !self.isMediaExists()
        
        self.changeCollectionInsets()
        self.layoutCourseElements()
    }
    
    /// Applies cell height.
    internal func apply(cellHeight height: CGFloat, forCellType type: CourseCellType) {
        self.cellsHeights[type] = height
        
        self.collectionView.collectionViewLayout.invalidateLayout()
        
        if self.scrollingToTop {
            self.scrollCourseToTop()
        }
    }
    
    /// Allows to edit and create sessions if true. Should be overridden
    ///
    /// - returns: True or false.
    ///
    internal func thisCourseIsMine() -> Bool {
        return false
    }
    
    // MARK: Private Methods
    
    private func deleteCourseConfirmed(withIgnoreSubscribers ignoreSubscribers: Bool) {
        guard let course = self.courseModel, let userModel = self.authorisedUserModel else {
            return
        }
        
        self.deleteCourseMethod = self.createCoursesService.deleteCourse(withCourseID: course.id, ignoreSubscribers: ignoreSubscribers, user: userModel)
    }
    
    private func setupNumberFormatter() {
        self.numberFormatter = NumberFormatter()
        self.numberFormatter.numberStyle = .currency
        if let currency = TroovyProducts.shared.getCurrentCurrency(), let locale = TroovyProducts.shared.getCurrentCurrencyLocale() {
            self.numberFormatter.currencyCode = currency
            self.numberFormatter.locale = locale
        }
        self.numberFormatter.minimumFractionDigits = 2
    }
    
    private func setupDateFormatters() {
        self.dateMonthFormatter = DateFormatter()
        self.dateMonthFormatter.locale = Locale(identifier: "en_US")
        self.dateMonthFormatter.dateFormat = "MMM"
        
        self.dateNumberFormatter = DateFormatter()
        self.dateNumberFormatter.locale = Locale(identifier: "en_US")
        self.dateNumberFormatter.dateFormat = "d"
        
        self.dateTimeFormatter = DateFormatter()
        self.dateTimeFormatter.locale = Locale(identifier: "en_US_POSIX")
        self.dateTimeFormatter.dateFormat = "h:mm a"
    }
    
    private func setupExitButton() {
        let viewControllersCount = self.navigationController?.viewControllers.count ?? 0
        if self.presentingViewController != nil && (self.navigationController == nil || self.navigationController?.viewControllers.last != self || viewControllersCount <= 1) {
            self.exitButton.setImage(UIImage.tv_navbarCloseSmall(), for: .normal)
        } else {
            self.exitButton.setImage(UIImage.tv_navbarBack(), for: .normal)
        }
    }
    
    private func setupBlurEffect() {
        self.visualEffectView?.layer.speed = 1.0
        self.visualEffectView?.removeFromSuperview()
        self.visualEffectView = nil
        
        self.visualEffectView = UIVisualEffectView()
        self.visualEffectView?.frame = self.courseBackgroundView.bounds
        self.visualEffectView?.isHidden = !self.isMediaExists()
        self.courseBackgroundView.addSubview(self.visualEffectView!)
        
        self.visualEffectView?.layer.speed = 0.0
        
        let effect = UIBlurEffect(style: .dark)
        UIView.animate(withDuration: 1.0, animations: {
            self.visualEffectView?.effect = effect
        })
        
        DispatchQueue.main.async {
            self.visualEffectView?.layer.timeOffset = Double(self.courseScrollProgress)
        }
    }
    
    private func setupCollectionView() {
        self.collectionView.alwaysBounceVertical = true
        
        if #available(iOS 11.0, *) {
            self.collectionView.contentInsetAdjustmentBehavior = .never
        }
    }
    
    private func setCourseScrollProgress(scrollProgress: CGFloat) {
        self.courseScrollProgress = scrollProgress
        
        self.visualEffectView?.layer.timeOffset = Double(scrollProgress)
        
        //self.navigationControlsEffectView.isHidden = (self.collectionView.contentOffset.y <= (0.0 - self.navigationControls.frame.maxY))
        
        let shadowPosition = Double(0.6177 * (1.0 - scrollProgress))
        self.shadowView.setupBlackGradientShadow(withStartPosition: shadowPosition)
        
        var buttonAlpha = (1.0 - scrollProgress * 30)
        if buttonAlpha < 0.0 {
            buttonAlpha = 0.0
        } else if buttonAlpha > 1.0 {
            buttonAlpha = 1.0
        }
        let cellAlpha = (1.0 - buttonAlpha)
        self.showCourseButton.alpha = buttonAlpha
        
        self.changeDescriptionCellAlpha(cellAlpha)
    }
    
    private func changeDescriptionCellAlpha(_ alpha: CGFloat) {
        let visibleCells = self.collectionView.visibleCells
        for cell in visibleCells {
            if let descriptionCell = cell as? CourseDescriptionCollectionViewCell {
                descriptionCell.setDescriptionAlpha(self.isMediaExists() ? alpha : 1.0)
                break
            }
        }
    }
    
    private func changeCollectionInsets() {
        var topInset: CGFloat = self.navigationControls.frame.maxY
        if self.isMediaExists() {
            topInset = ceil(self.collectionView.bounds.height * 0.8576)
        }
        
        if self.collectionView.contentInset.top != topInset {
            self.collectionView.contentInset = UIEdgeInsetsMake(topInset, 0.0, 0.0, 0.0)
            self.collectionView.collectionViewLayout.invalidateLayout()
        }
    }
    
    private func checkCourseLoaded() {
        if let course = self.courseModel {
            var checkPassed = false
//            if self.thisCourseIsMine() {
//                checkPassed = (self.verificationService.check(string: course.title) != nil && self.verificationService.check(string: course.price?.stringValue) != nil && self.verificationService.check(string: course.earnings?.stringValue) != nil && self.verificationService.check(string: course.specification) != nil)
//            } else {
//                checkPassed = (self.verificationService.check(string: course.title) != nil && self.verificationService.check(string: course.price?.stringValue) != nil && self.verificationService.check(string: course.specification) != nil && self.verificationService.check(string: course.creatorName) != nil && self.verificationService.check(string: course.creatorID) != nil)
//            }
//            
//            if checkPassed {
//                self.structCourseInfo()
//                if self.activityIndicator.isAnimating {
//                    self.activityIndicator.stopAnimating()
//                }
//                
//                if course.sessions.count > 0 {
//                    return
//                }
//            }
        }
        
        if !self.courseSuccesfullyRequested {
            self.loadCourseInfo()
        }
    }
    
    private func loadCourseInfo() {
        if self.loadingCourse {
            return
        }
        self.startRefreshing()
        self.loadingCourse = true
        self.loadCourseMethod = self.coursesService.loadCourseInfo(withCourseID: self.courseID, user: self.authorisedUserModel)
    }
    
    private func layoutCourseElements() {
        let collectionViewOffset = self.collectionView.contentOffset.y + self.collectionView.contentInset.top
        
        var courseScrollProgress = (collectionViewOffset / self.collectionView.contentInset.top)
        if courseScrollProgress < 0.0 {
            courseScrollProgress = 0.0
        } else if courseScrollProgress > 1.0 {
            courseScrollProgress = 1.0
        }
        self.setCourseScrollProgress(scrollProgress: courseScrollProgress)
    }
    
    private func showDeleteConfirmation(withMessage message: String?, ignoreSubscribers: Bool) {
        let title = message ?? ApplicationMessages.AlertTitles.deleteCourse
        let message = ApplicationMessages.Instructions.undone
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: ApplicationMessages.AlertButtonsTitles.no, style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: ApplicationMessages.AlertButtonsTitles.yes, style: .default, handler: { [weak self] (action) in
            self?.deleteCourseConfirmed(withIgnoreSubscribers: ignoreSubscribers)
        }))
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func scrollCourseToTop() {
        var contentHeight: CGFloat = 0.0
        for cellType in self.cellsTypes {
            if let cellHeight = self.cellsHeights[cellType] {
                contentHeight += cellHeight
            } else {
                contentHeight += 102.0
            }
        }
        
        var maxOffset = contentHeight - self.collectionView.contentInset.top - self.navigationControls.frame.maxY
        if let flowLayout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            maxOffset += (flowLayout.sectionInset.top + flowLayout.sectionInset.bottom)
        }
        var topOffset = 0.0 - self.navigationControls.frame.maxY
        if maxOffset < topOffset {
            topOffset = maxOffset
        }
        
        self.scrollingToTop = true
        UIView.animate(withDuration: 0.25, animations: {
            self.collectionView.contentOffset = CGPoint(x: 0.0, y: topOffset)
        }) { (success) in
            self.scrollingToTop = false
        }
    }
    
    private func isMediaExists() -> Bool {
        let mediaExists = (self.courseModel?.previewImageURL != nil)
        return mediaExists
    }
    
    private func exit() {
        let viewControllersCount = self.navigationController?.viewControllers.count ?? 0
        if self.presentingViewController != nil && (self.navigationController == nil || self.navigationController?.viewControllers.last != self || viewControllersCount <= 1) {
            self.presentingViewController?.dismiss(animated: true, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    // MARK: Controls Actions
    
    @IBAction func exitButtonAction(_ sender: UIButton) {
        self.exit()
    }
    
    @IBAction func courseBackgroundTapped(_ sender: UITapGestureRecognizer) {
        let tapPoint = sender.location(in: self.view)
        if self.courseBackgroundView.frame.contains(tapPoint) && self.courseScrollProgress <= 0.5 {
            let tapAreaWidth = self.courseBackgroundView.frame.width * 0.3
            if tapPoint.x < tapAreaWidth {
                self.courseBackgroundView.showPreviousIntro()
            } else if tapPoint.x > self.courseBackgroundView.frame.width - tapAreaWidth {
                self.courseBackgroundView.showNextIntro()
            } else {
                self.courseBackgroundView.changeIntroMuted()
            }
        }
    }
    
    @IBAction func showCourseButtonAction(_ sender: UIButton) {
        self.scrollCourseToTop()
    }
    
    // MARK: Protocols Implementation
    
    // MARK: CourseModelDelegate
    
    internal func courseChagned(course: CourseModel) {
        if self.courseModel?.id == course.id {
            if self.viewAppeared {
                self.checkCourseLoaded()
            } else {
                self.modelChanged = true
            }
        }
    }
    
    // MARK: UICollectionViewDelegate && UICollectionViewDataSource
    
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        guard let lastCellType = self.cellsTypes.last else {
            return UIEdgeInsets.zero
        }
        
        if lastCellType == .createSession || lastCellType == .title || lastCellType == .subtitle || lastCellType == .description || lastCellType == .sessions {
            return UIEdgeInsetsMake(0.0, 0.0, 30.0, 0.0)
        } else {
            return UIEdgeInsetsMake(0.0, 0.0, 2.0, 0.0)
        }
    }
    
    internal func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        fatalError()
    }
    
    internal func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.cellsTypes.count
    }
    
    internal func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cellType = self.cellsTypes[indexPath.row]
        if cellType == .createSession {
            self.router.showCourseSessionScreen(withAuthorisedUserModel: self.authorisedUserModel, sessionModel: nil, courseSessionAlwaysEditable: false, delegate: self)
        } else if cellType == .sessions {
            let index = indexPath.row - self.sessionStartIndex
            let session = self.upcomingSessions[index]
            
            if self.thisCourseIsMine() && self.authorisedUserModel != nil {
                self.router.showCourseSessionScreen(withAuthorisedUserModel: self.authorisedUserModel, sessionModel: session, courseSessionAlwaysEditable: false, delegate: self)
            } else {
                self.router.showFuturePastSessionScreen(withAuthorisedUserModel: self.authorisedUserModel, sessionModel: session, courseModel: self.courseModel)
            }
        } else if cellType == .subtitle {
            guard let userID = self.courseModel?.creatorID, let userModel = self.authorisedUserModel else {
                return
            }
            
            if let otherProfileViewController = self.navigationController?.viewControllers.first as? OtherProfileViewController, otherProfileViewController.userID == userID {
                self.navigationController?.popViewController(animated: true)
            } else {
                self.router.showOtherProfileViewController(withAuthorisedUserModel: userModel, userID: userID)
            }
        }
    }
    
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.size.width
        let height: CGFloat = 102.0
        
        let cellType = self.cellsTypes[indexPath.row]
        if let cellHeight = self.cellsHeights[cellType] {
            return CGSize(width: width, height: cellHeight)
        }
        
        return CGSize(width: width, height: height)
    }
    
    internal func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let cellType = self.cellsTypes[indexPath.row]
        if cellType == .createSession || cellType == .sessions || (cellType == .subtitle && self.authorisedUserModel != nil) {
            if let cell = collectionView.cellForItem(at: indexPath) {
                cell.alpha = 0.66
                cell.contentView.alpha = 0.66
            }
        }
    }
    
    internal func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) {
            cell.alpha = 1.0
            cell.contentView.alpha = 1.0
        }
    }
    
    // MARK: UIScrollViewDelegate
    
    internal func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.layoutCourseElements()
    }
    
    // MARK: CreateSessionDelegate
    
    internal func sessionView(view: UIViewController, didChangeCourseSessionModel model: CourseSessionModel) {
        guard let course = self.courseModel else {
            return
        }
        
        course.update(byChangingSession: model)
        self.coursesService.updateCourseSession(withModel: model)
    }
    
    internal func sessionView(view: UIViewController, didCreateCourseSessionModel model: CourseSessionModel) {
        guard let course = self.courseModel else {
            return
        }
        
        course.update(byAppendingSession: model)
        self.coursesService.saveOwnCourseSession(withModel: model, forCourse: course)
    }
    
    internal func sessionView(view: UIViewController, checkNewSessionModelDoesNotConflictWithOthers model: CourseSessionModel) -> Bool {
        return true
    }
    
    internal func sessionViewSelectedCourseID(view: UIViewController) -> String? {
        return self.courseModel?.id
    }
    
}
