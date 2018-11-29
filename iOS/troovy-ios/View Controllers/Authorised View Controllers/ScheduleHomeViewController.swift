//
//  ScheduleHomeViewController.swift
//  troovy-ios
//
//  Created by Daniil on 23.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class ScheduleHomeViewController: TroovyViewController, SessionCellDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var topSeparatorView: UIView?
    @IBOutlet weak var bottomSeparatorView: UIView?
    
    @IBOutlet weak var collectionView: UICollectionView?
    @IBOutlet weak var emptyView: UIView?
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView?
    
    // MARK: Public Properties
    
    private let sessionsUpdateQueue = DispatchQueue(label: "sessionsUpdateQueue")
    private let sessionsDataQueue = DispatchQueue(label: "sessionsDataQueue")
    
    /// Model of the unauthorised user.
    var authorisedUserModel: AuthorisedUserModel!
    
    // MARK: Private Properties
    
    private var verificationService: VerificationService!
    private var coursesService: CoursesService!
    
    private var dateMonthFormatter: DateFormatter!
    private var dateNumberFormatter: DateFormatter!
    private var dateTimeFormatter: DateFormatter!
    
    private var firstLaunch = true
    private var loadingWithPullToRefresh = false
    private var loadingSessions = false
    private var refreshControl: UIRefreshControl?
    
    private var sessions: [CourseSessionModel] = []
    
    private var loadSessionsMethod: String?

    // MARK: Init Methods & Superclass Overriders
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(subscribedSessionsChanged(_:)), name: Notification.Name(CreateCoursesNotificationNames.subscribedSessionsChanged), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(subscribedSessionFinished(_:)), name: Notification.Name(CreateCoursesNotificationNames.subscribedSessionFinished), object: nil)
        
        self.title = nil
        self.titleLabel?.text = ApplicationMessages.ScreenTitles.scheduleHomeScreen
        
        self.setupDateFormatters()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.firstLaunch {
            self.firstLaunch = false
            self.checkSessionsLoaded()
        } else {
            self.collectionView?.isHidden = (self.sessions.count == 0)
            self.emptyView?.isHidden = (self.sessions.count != 0 || self.loadingSessions)
        }
        
        self.configureSeparatorsStateForScroll()
        
        DispatchQueue.main.async {
            self.setupCollectionView()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.collectionView?.collectionViewLayout.invalidateLayout()
        self.configureSeparatorsStateForScroll()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func inject(propertiesWithAssembly assembly: ViewControllerAssemblyManager) {
        self.verificationService = assembly.verificationService
        self.coursesService = assembly.coursesService
    }
    
    override func configureServices() {
        self.coursesService.delegate = self
    }
    
    override func serviceMethodSucceeded(withMethod method: String, resultDictionary: [String : Any]?, resultArray: [[String : Any]]?, resultString: String?) {
        if method == self.loadSessionsMethod {
            var sessions: [CourseSessionModel] = []
            if let sessionsInfo = resultArray {
                for info in sessionsInfo {
                    let session = CourseSessionModel(withDictionary: info)
                    sessions.append(session)
                }
            }
            
            self.loadingWithPullToRefresh = false
            self.loadingSessions = false
            self.refreshControl?.setRefreshing(false)
            
            self.apply(serverSessions: sessions)
        }
    }
    
    override func serviceMethodFailed(withMethod method: String) {
        if method == self.loadSessionsMethod {
            self.loadingWithPullToRefresh = false
            self.loadingSessions = false
            self.refreshControl?.setRefreshing(false)
            self.apply(serverSessions: [])
        }
    }
    
    override func showLoadingView(withMethod method: String) {
        if method == self.loadSessionsMethod {
            if !self.loadingWithPullToRefresh {
                let isAnimating = self.activityIndicator?.isAnimating ?? false
                if !isAnimating {
                    self.activityIndicator?.startAnimating()
                }
                
                self.collectionView?.isHidden = true
                self.emptyView?.isHidden = true
            } else {
                self.hideLoadingView(withMethod: method)
            }
        }
    }
    
    override func hideLoadingView(withMethod method: String) {
        if method == self.loadSessionsMethod {
            self.collectionView?.isHidden = (self.sessions.count == 0)
            self.emptyView?.isHidden = (self.sessions.count != 0 || self.loadingSessions)
            
            let isAnimating = self.activityIndicator?.isAnimating ?? false
            if isAnimating {
                self.activityIndicator?.stopAnimating()
            }
        }
    }
    
    // MARK: Notifications & Observers
    
    @objc private func subscribedSessionsChanged(_ notification: Notification) {
        if self.firstLaunch {
            return
        }
        
        self.loadSessions()
    }
    
    @objc private func subscribedSessionFinished(_ notification: Notification) {
        if self.firstLaunch {
            return
        }
        
        if let finishedSession = notification.object as? CourseSessionModel {
            self.deleteSession(finishedSession)
        }
    }
    
    // MARK: Private Methods
    
    private func setupCollectionView() {
        if self.refreshControl != nil {
            return
        }
        
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = UIColor.tv_darkColor()
        refreshControl.addTarget(self, action: #selector(refreshControlTriggered(_:)), for: .valueChanged)
        
        self.collectionView?.insertSubview(refreshControl, at: 0)
        self.collectionView?.alwaysBounceVertical = true
        self.refreshControl = refreshControl
        
        if #available(iOS 11.0, *) {
            self.collectionView?.contentInsetAdjustmentBehavior = .never
        }
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
    
    private func configureSeparatorsStateForScroll() {
        guard let collectionView = self.collectionView else {
            return
        }
        
        self.topSeparatorView?.isHidden = !(collectionView.contentOffset.y >= 15.0)
        self.bottomSeparatorView?.isHidden = !(collectionView.contentSize.height - collectionView.contentOffset.y - collectionView.bounds.height >= 15.0)
    }
    
    private func checkSessionsLoaded() {
        self.refreshControl?.setRefreshing(self.loadingSessions)
        self.apply(serverSessions: self.sessions)
        
        if self.sessions.count > 0 {
            let isAnimating = self.activityIndicator?.isAnimating ?? false
            if isAnimating {
                self.activityIndicator?.stopAnimating()
            }
        } else {
            self.loadSessions()
        }
    }
    
    private func apply(serverSessions: [CourseSessionModel]?) {
        if let sessions = serverSessions {
            self.replaceSessions(withNew: sessions)
        }
        
        self.configureSeparatorsStateForScroll()
    }
    
    private func loadSessions() {
        if self.loadingSessions {
            self.loadingWithPullToRefresh = false
            return
        }
        
        self.loadingSessions = true
        self.loadSessionsMethod = self.coursesService.loadSessions(forUser: self.authorisedUserModel)
    }
    
    private func checkCollectionViewState() {
        self.collectionView?.isHidden = (self.sessions.count == 0)
        self.emptyView?.isHidden = (self.sessions.count != 0 || self.loadingSessions)
        
        self.configureSeparatorsStateForScroll()
    }
    
    // MARK: Change sessions
    
    private func replaceSessions(withNew sessions: [CourseSessionModel]) {
        self.sessionsUpdateQueue.async {
            self.changeSessions(byReplacingWithSessions: sessions)
        }
    }
    
    private func deleteSession(_ session: CourseSessionModel) {
        self.sessionsUpdateQueue.async {
            self.changeSessions(byDeletingSession: session)
        }
    }
    
    private func reloadSession(_ session: CourseSessionModel) {
        self.sessionsUpdateQueue.async {
            self.changeSessions(byReloadingSession: session)
        }
    }
    
    private func changeSessions(byDeletingSession session: CourseSessionModel) {
        let semaphore = DispatchSemaphore.init(value: 0)
        
        self.sessionsDataQueue.async {
            self.updateCollectionView(byReplacingWithSessions: nil, orByDeletingSession: session, orByReloadingSession: nil, completion: {
                semaphore.signal()
            })
        }
        
        semaphore.wait()
    }
    
    private func changeSessions(byReplacingWithSessions sessions: [CourseSessionModel]) {
        let semaphore = DispatchSemaphore.init(value: 0)
        
        self.sessionsDataQueue.async {
            self.updateCollectionView(byReplacingWithSessions: sessions, orByDeletingSession: nil, orByReloadingSession: nil, completion: {
                semaphore.signal()
            })
        }
        
        semaphore.wait()
    }
    
    private func changeSessions(byReloadingSession session: CourseSessionModel) {
        let semaphore = DispatchSemaphore.init(value: 0)
        
        self.sessionsDataQueue.async {
            self.updateCollectionView(byReplacingWithSessions: nil, orByDeletingSession: nil, orByReloadingSession: session, completion: {
                semaphore.signal()
            })
        }
        
        semaphore.wait()
    }
    
    private func updateCollectionView(byReplacingWithSessions replaceSessions: [CourseSessionModel]?, orByDeletingSession deleteSession: CourseSessionModel?, orByReloadingSession reloadSession: CourseSessionModel?, completion: @escaping (() -> ())) {
        if let sessions = replaceSessions {
            self.sessions = sessions
            
            DispatchQueue.main.async {
                if self.collectionView != nil {
                    self.collectionView!.reloadData()
                    self.checkCollectionViewState()
                }
                completion()
            }
        } else if let session = deleteSession, let sessionID = session.id {
            if let index = self.sessions.index(where: { $0.id == sessionID }) {
                self.sessions.remove(at: index)
                
                let indexPath = IndexPath(row: index, section: 0)
                DispatchQueue.main.async {
                    if self.collectionView != nil {
                        if self.viewAppeared && self.collectionView!.visibleCells.count > 0 {
                            self.collectionView!.deleteItems(at: [indexPath])
                            self.checkCollectionViewState()
                        } else {
                            self.collectionView!.reloadData()
                            self.checkCollectionViewState()
                        }
                    }
                    completion()
                }
            } else {
                DispatchQueue.main.async {
                    self.checkCollectionViewState()
                    completion()
                }
            }
        } else if let session = reloadSession, let sessionID = session.id {
            if let index = self.sessions.index(where: { $0.id == sessionID }) {
                let indexPath = IndexPath(row: index, section: 0)
                DispatchQueue.main.async {
                    if self.collectionView != nil {
                        if self.viewAppeared && self.collectionView!.visibleCells.count > 0 {
                            self.collectionView!.performBatchUpdates({
                                self.collectionView!.deleteItems(at: [indexPath])
                                self.collectionView!.insertItems(at: [indexPath])
                            }, completion: { (succeed) in
                                self.checkCollectionViewState()
                                completion()
                            })
                        } else {
                            self.collectionView!.reloadData()
                            self.checkCollectionViewState()
                            completion()
                        }
                    } else {
                        completion()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.checkCollectionViewState()
                    completion()
                }
            }
        } else {
            DispatchQueue.main.async {
                if self.collectionView != nil {
                    self.collectionView!.reloadData()
                    self.checkCollectionViewState()
                }
                completion()
            }
        }
    }
    
    // MARK: Controls Actions
    
    @objc private func refreshControlTriggered(_ sender: UIRefreshControl) {
        self.refreshControl?.setRefreshing(true)
        self.loadingWithPullToRefresh = true
        self.loadSessions()
    }
    
    @IBAction func reloadButtonAction(_ sender: UIButton) {
        self.loadSessions()
    }
    
    // MARK: Protocols Implementation
    
    // MARK: UIScrollViewDelegate
    
    internal func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.configureSeparatorsStateForScroll()
    }
    
    // MARK: SessionCellDelegate
    
    internal func sessionCell(cell: SessionCollectionViewCell, shouldEnterSessionWithID sessionID: String) {
        let found = self.sessions.first { (sessionModel) -> Bool in
            return (sessionModel.id != nil && sessionModel.id == sessionID)
        }
        
        if let sessionModel = found {
            let sessionOwner = sessionModel.creatorID != nil && self.authorisedUserModel.id == sessionModel.creatorID
            self.router.showVideoStreamViewController(withAuthorisedUserModel: self.authorisedUserModel, sessionModel: sessionModel, sessionOwner: sessionOwner)
        }
    }
    
    internal func sessionCell(cell: SessionCollectionViewCell, sessionEnterMinutesLeftForSessionWithID sessionID: String) -> Int {
        return self.verificationService.sessionEnterMinutesLeft()
    }
    
    internal func sessionCell(cell: SessionCollectionViewCell, sessionBecomeReadyForEnterWithID sessionID: String) {
        let found = self.sessions.first { (sessionModel) -> Bool in
            return (sessionModel.id != nil && sessionModel.id == sessionID)
        }
        
        if let sessionModel = found {
            self.reloadSession(sessionModel)
        }
    }
    
    internal func sessionCell(cell: SessionCollectionViewCell, sessionBecomeOutdatedWithID sessionID: String) {
        let found = self.sessions.first { (sessionModel) -> Bool in
            return (sessionModel.id != nil && sessionModel.id == sessionID)
        }
        
        if let sessionModel = found {
            self.deleteSession(sessionModel)
        }
    }
    
    // MARK: UICollectionViewDelegate && UICollectionViewDataSource
    
    internal func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let index = indexPath.row
        let session = self.sessions[index]
        
        let currentTimestamp = Int64(Date().timeIntervalSince1970)
        let startTimestamp = session.startTimestamp!
        let durationInSeconds = Int64(session.duration! * 60)
        let sessionEnterMinutesLeft = self.verificationService.sessionEnterMinutesLeft()
        
        if (startTimestamp - currentTimestamp) <= (sessionEnterMinutesLeft * 60) && (startTimestamp + durationInSeconds) > currentTimestamp {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SessionCollectionViewCellEnter", for: indexPath) as! SessionCollectionViewCell
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SessionCollectionViewCell", for: indexPath) as! SessionCollectionViewCell
            return cell
        }
    }
    
    internal func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let sessionCell = cell as? SessionCollectionViewCell {
            let index = indexPath.row
            let session = self.sessions[index]
            
            let currentTimestamp = Int64(Date().timeIntervalSince1970)
            let startTimestamp = session.startTimestamp!
            let durationInSeconds = Int64(session.duration! * 60)
            let sessionEnterMinutesLeft = self.verificationService.sessionEnterMinutesLeft()
            
            if (startTimestamp - currentTimestamp) <= (sessionEnterMinutesLeft * 60) && (startTimestamp + durationInSeconds) > currentTimestamp {
                sessionCell.configure(withSession: session, dateMonthFormatter: self.dateMonthFormatter, dateNumberFormatter: self.dateNumberFormatter, dateTimeFormatter: self.dateTimeFormatter, isFirstSession: false, isLastSession: false, delegate: self)
            } else {
                var previousSessionReady = false
                if ((index - 1) >= 0) {
                    let previousSession = self.sessions[(index - 1)]
                    let previousStartTimestamp = previousSession.startTimestamp!
                    let previousDurationInSeconds = Int64(previousSession.duration! * 60)
                    
                    previousSessionReady = ((previousStartTimestamp - currentTimestamp) <= (sessionEnterMinutesLeft * 60) && (previousStartTimestamp + previousDurationInSeconds) > currentTimestamp)
                }
                
                let isFirstSession = (index == 0) || previousSessionReady
                let isLastSession = ((index + 1) == self.sessions.count)
                
                sessionCell.configure(withSession: session, dateMonthFormatter: self.dateMonthFormatter, dateNumberFormatter: self.dateNumberFormatter, dateTimeFormatter: self.dateTimeFormatter, isFirstSession: isFirstSession, isLastSession: isLastSession, delegate: self)
            }
        }
    }
    
    internal func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.sessions.count
    }
    
    internal func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let index = indexPath.row
        let session = self.sessions[index]
        
        self.router.showFuturePastSessionScreen(withAuthorisedUserModel: self.authorisedUserModel, sessionModel: session, courseModel: nil)
    }
    
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.size.width
        let height: CGFloat = 92.0
        
        return CGSize(width: width, height: height)
    }
    
    internal func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) {
            cell.alpha = 0.66
            cell.contentView.alpha = 0.66
        }
    }
    
    internal func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) {
            cell.alpha = 1.0
            cell.contentView.alpha = 1.0
        }
    }

}
