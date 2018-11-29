//
//  VideoStreamViewController.swift
//  troovy-ios
//
//  Created by Daniil on 11.10.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit
import AVFoundation
import Kingfisher
import MetalKit

class VideoStreamViewController: TroovyViewController, VideoStreamServiceDelegate, StreamChatServiceDelegate, RTCEAGLVideoViewDelegate {
    
    private enum BottomControlsState: Int {
        case none = 0
        case attachments
        case chat
        case info
    }
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var exitButtonWidth: NSLayoutConstraint!
    @IBOutlet weak var viewsContainerViewToBottom: NSLayoutConstraint!
    @IBOutlet weak var bottomButtonsContainerViewToBottom: NSLayoutConstraint!
    
    @IBOutlet weak var viewsContainerView: UIView!
    @IBOutlet weak var chatContainerView: UIView!
    @IBOutlet weak var infoContainerView: UIView!
    @IBOutlet weak var attachmentsContainerView: UIView!
    
    @IBOutlet weak var connectionStatusView: UIView!
    @IBOutlet weak var connectionStatusLabel: UILabel!
    @IBOutlet weak var videoContainerView: UIView!
    @IBOutlet weak var bottomButtonsContainerView: UIView!

    @IBOutlet weak var exitButton: UIButton!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var finishButton: UIButton!
    @IBOutlet weak var microphoneButton: UIButton!
    @IBOutlet weak var switchButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var attachmentsButton: UIButton!
    @IBOutlet weak var chatButton: UIButton!
    
    @IBOutlet weak var streamerViewContainer: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var profileImageView: UIImageView!
    
    // MARK: Public Properties
    
    /// Model of the unauthorised user.
    var authorisedUserModel: AuthorisedUserModel!
    
    /// Course session model.
    var sessionModel: CourseSessionModel!
    
    // MARK: Properties Overriders
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: Private Properties
    
    private var streamChatViewController: StreamChatViewController!
    
    private let infoPlistService = InfoPlistService()
    private var authorisedUserService: AuthorisedUserService!
    private var videoStreamService: VideoStreamService!
    
    private var streamInfoModel: StreamInfoModel?
    
    private var serverTimestamp: Int64 = 0
    private var timeUpdateTime: Timer?
    
    private var streamConnected = false
    private var sessionConnecting = false
    private var sessionConnected = false {
        didSet {
            self.changeChatReadyForSending()
        }
    }
    private var sessionStarted = false
    private var sessionFinished = false
    
    private var videoEnabled = true
    private var microphoneEnabled = true
    
    private var finishSessionMethod: String?
    private var startSessionMethod: String?
    private var loadUsersMethod: String?
    
    private var bottomControlsState: BottomControlsState = .none
    
    private var streamingView: UIView? {
        willSet {
            self.hideVideoView()
        }
        didSet {
            self.showVideoView()
        }
    }
    
    private var cameraView: UIView? {
        willSet {
            self.hideVideoView()
        }
        didSet {
            self.showVideoView()
        }
    }
    
    private var videoViewConstraints: [NSLayoutConstraint] = []
    
    // MARK: Init Methods & Superclass Overriders

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.startTimeUpdateTimer()
        self.getStreamerInfo()
        self.updateBottomControlsConstraints(animated: false)
        self.updateTopControlsConstraints(animated: false)
        
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(_:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive(_:)), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        
        self.configureButtonsAndLabels()
        
        self.checkMediaPermissions {
            self.applySessionConnected(self.sessionConnected)
            self.applySessionStartedState(sessionStarted: self.sessionStarted)
            
            if self.isSessionOwner() {
                self.videoStreamService.startCamera()
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.updateBottomControlsConstraints(animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let streamChatViewController = segue.destination as? StreamChatViewController, let sessionID = self.sessionModel.id, let creatorID = self.sessionModel.creatorID {
            streamChatViewController.router = self.router
            streamChatViewController.authorisedUserModel = self.authorisedUserModel
            streamChatViewController.sessionID = sessionID
            streamChatViewController.streamerID = creatorID
            streamChatViewController.readyForSending = self.sessionConnected
            
            self.streamChatViewController = streamChatViewController
        } else if let streamSessionInfoViewController = segue.destination as? StreamSessionInfoViewController {
            streamSessionInfoViewController.router = self.router
            streamSessionInfoViewController.sessionModel = self.sessionModel
        } else if let sessionAttachmentsViewController = segue.destination as? SessionAttachmentsViewController {
            sessionAttachmentsViewController.router = self.router
            sessionAttachmentsViewController.sessionModel = self.sessionModel
            sessionAttachmentsViewController.authorisedUserModel = self.authorisedUserModel
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        
        self.stopTimeUpdateTimer()
        
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    override func inject(propertiesWithAssembly assembly: ViewControllerAssemblyManager) {
        self.authorisedUserService = assembly.authorisedUserService
        self.videoStreamService = assembly.videoStreamService
    }
    
    override func configureServices() {
        self.authorisedUserService.delegate = self
        self.videoStreamService.delegate = self
        self.videoStreamService.streamReceiver = self
        self.videoStreamService.chatReceiver = self
    }
    
    override func serviceMethodSucceeded(withMethod method: String, resultDictionary: [String : Any]?, resultArray: [[String : Any]]?, resultString: String?) {
        if method == self.finishSessionMethod {
            self.finishSessionWithFinishedView()
        } else if method == self.startSessionMethod {
            self.applySessionStartedState(sessionStarted: true)
            self.videoStreamService.startStreaming(withServers: self.streamInfoModel?.iceServers)
        } else if method == self.loadUsersMethod {
            if let usersDictionaries = resultArray {
                for dictionary in usersDictionaries {
                    let user = UserModel(withDictionary: dictionary)
                    self.applyStreamerInfo(user)
                    break
                }
            }
        }
    }
    
    override func serviceMethodFailed(withMethod method: String) {
        if method == self.startSessionMethod {
            self.applySessionStartedState(sessionStarted: false)
        } else if method == self.loadUsersMethod {
            self.getStreamerInfo()
        }
    }
    
    override func showLoadingView(withMethod method: String) {
        if method == self.startSessionMethod {
            self.showLoadingView()
        } else if method == self.finishSessionMethod {
            self.showLoadingView()
        } else if method == self.loadUsersMethod {
            return
        }
    }
    
    override func shouldShowAlert(forMethod method: String) -> Bool {
        if method == self.startSessionMethod || method == self.finishSessionMethod {
            return true
        }
        
        return false
    }
    
    override func alertTitle(forMethod method: String) -> String {
        if method == self.startSessionMethod {
            return ApplicationMessages.AlertTitles.sessionItNotStarted
        } else {
            return ApplicationMessages.AlertTitles.message
        }
    }
    
    // MARK: Notifications & Observers
    
    @objc private func applicationWillResignActive(_ notification: Notification) {
        if self.isSessionOwner() {
            self.videoStreamService.setCameraEnabled(enabled: false)
            self.videoStreamService.setMicrophoneEnabled(enabled: false)
        }
    }
    
    @objc private func applicationDidBecomeActive(_ notification: Notification) {
        self.configureButtonsAndLabels()
        
        if self.isSessionOwner() {
            self.videoStreamService.setCameraEnabled(enabled: self.videoEnabled)
            self.videoStreamService.setMicrophoneEnabled(enabled: self.microphoneEnabled)
        } else {
            self.videoStreamService.continueWatching(withServers: self.streamInfoModel?.iceServers)
        }
    }
    
    // MARK: Private Methods
    
    private func getStreamerInfo() {
        self.streamerViewContainer.isHidden = self.isSessionOwner()

        if !self.isSessionOwner() {
            guard let streamerID = self.sessionModel.creatorID else {
                return
            }
            
            self.setActivityIndicator(animating: true)
            self.loadUsersMethod = self.authorisedUserService.loadUsers(withUsersIdentifiers: [streamerID], user: self.authorisedUserModel)
        }
    }
    
    private func applyStreamerInfo(_ streamer: UserModel) {
        let serverAddress = self.infoPlistService.serverURL()
        if let profilePictureURL = streamer.profilePictureURL, let imageURL = URL.address(byAppendingServerAddress: serverAddress, toContentPath: profilePictureURL) {
            let resourse = ImageResource(downloadURL: imageURL)
            self.profileImageView?.kf.setImage(with: resourse, placeholder: nil, options: nil, progressBlock: nil, completionHandler: { [weak self] (loadedImage, error, cacheType, url) in
                if loadedImage != nil {
                    DispatchQueue.main.async {
                        self?.setActivityIndicator(animating: false)
                    }
                }
            })
        } else {
            self.setActivityIndicator(animating: false)
            self.profileImageView?.kf.cancelDownloadTask()
            self.profileImageView?.image = UIImage.tv_profilePlaceholder()
        }
    }
    
    private func configureButtonsAndLabels() {
        if self.isSessionOwner() {
            self.finishButton.isHidden = !(self.sessionStarted && !self.sessionFinished)
            self.startButton.isHidden = !(!self.sessionStarted && !self.sessionFinished && self.sessionConnected)
            self.exitButton.isHidden = !(!self.sessionStarted && !self.sessionFinished)
            
            self.cameraButton.isHidden = (self.cameraView == nil || !self.sessionStarted || !self.sessionConnected)
            self.microphoneButton.isHidden = (self.cameraView == nil || !self.sessionStarted || !self.sessionConnected)
            self.switchButton.isHidden = (self.cameraView == nil || !self.sessionStarted || !self.sessionConnected)
            self.infoButton.isHidden = false
            self.attachmentsButton.isHidden = true
        } else {
            self.finishButton.isHidden = true
            self.startButton.isHidden = true
            self.exitButton.isHidden = false
            
            self.cameraButton.isHidden = true
            self.microphoneButton.isHidden = true
            self.switchButton.isHidden = true
            self.infoButton.isHidden = false
            self.attachmentsButton.isHidden = (!self.sessionStarted || self.sessionFinished || !self.sessionConnected || !self.streamConnected)
        }
        
        self.checkSessionDates()
        self.configureConnectionStatusView()
        self.updateTopControlsConstraints(animated: true)
    }
    
    private func applySessionConnected(_ connected: Bool) {
        self.sessionConnected = connected
        
        if connected == false {
            if let _ = self.streamingView {
                self.streamingView = nil
            }
            
            self.applySessionStartedState(sessionStarted: false)
            self.enterSession()
        }
        
        self.configureButtonsAndLabels()
    }
    
    private func applySessionStartedState(sessionStarted: Bool) {
        self.sessionStarted = sessionStarted
        
        self.configureButtonsAndLabels()
    }
    
    // MARK: Timer Methods
    
    private func startTimeUpdateTimer() {
        if self.timeUpdateTime != nil {
            return
        }
        
        self.timeUpdateTime = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] (timer) in
            DispatchQueue.main.async {
                self?.serverTimestamp += 1
                self?.checkSessionDates()
            }
        })
    }
    
    private func stopTimeUpdateTimer() {
        self.timeUpdateTime?.invalidate()
        self.timeUpdateTime = nil
    }
    
    private func updateBottomControlsConstraints(animated: Bool) {
        var shouldUpdateConstraints = false
        
        var safeAreaBottomInsets: CGFloat = 0.0
        if #available(iOS 11.0, *) {
            safeAreaBottomInsets = self.view.safeAreaInsets.bottom
        }
        
        switch self.bottomControlsState {
        case .none:
            if self.viewsContainerViewToBottom.constant != (0.0 - self.viewsContainerView.bounds.height - safeAreaBottomInsets) || self.bottomButtonsContainerViewToBottom.constant != 26.0 {
                shouldUpdateConstraints = true
                self.viewsContainerViewToBottom.constant = (0.0 - self.viewsContainerView.bounds.height - safeAreaBottomInsets)
                self.bottomButtonsContainerViewToBottom.constant = 26.0
            }
            break
        case .attachments:
            self.attachmentsContainerView.isHidden = false
            self.chatContainerView.isHidden = true
            self.infoContainerView.isHidden = true
            if self.viewsContainerViewToBottom.constant != 0.0 || self.bottomButtonsContainerViewToBottom.constant != (0.0 - self.bottomButtonsContainerView.bounds.height - safeAreaBottomInsets) {
                shouldUpdateConstraints = true
                self.viewsContainerViewToBottom.constant = 0.0
                self.bottomButtonsContainerViewToBottom.constant = (0.0 - self.bottomButtonsContainerView.bounds.height - safeAreaBottomInsets)
            }
            break
        case .chat:
            self.attachmentsContainerView.isHidden = true
            self.chatContainerView.isHidden = false
            self.infoContainerView.isHidden = true
            if self.viewsContainerViewToBottom.constant != 0.0 || self.bottomButtonsContainerViewToBottom.constant != (0.0 - self.bottomButtonsContainerView.bounds.height - safeAreaBottomInsets) {
                shouldUpdateConstraints = true
                self.viewsContainerViewToBottom.constant = 0.0
                self.bottomButtonsContainerViewToBottom.constant = (0.0 - self.bottomButtonsContainerView.bounds.height - safeAreaBottomInsets)
            }
            break
        case .info:
            self.attachmentsContainerView.isHidden = true
            self.chatContainerView.isHidden = true
            self.infoContainerView.isHidden = false
            if self.viewsContainerViewToBottom.constant != 0.0 || self.bottomButtonsContainerViewToBottom.constant != (0.0 - self.bottomButtonsContainerView.bounds.height - safeAreaBottomInsets) {
                shouldUpdateConstraints = true
                self.viewsContainerViewToBottom.constant = 0.0
                self.bottomButtonsContainerViewToBottom.constant = (0.0 - self.bottomButtonsContainerView.bounds.height - safeAreaBottomInsets)
            }
            break
        }
        
        if shouldUpdateConstraints {
            if animated {
                UIView.animate(withDuration: 0.25, animations: {
                    self.view.layoutIfNeeded()
                })
            } else {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    private func updateTopControlsConstraints(animated: Bool) {
        var shouldUpdateConstraints = false
        if self.exitButton.isHidden {
            if self.exitButtonWidth.constant != 8.0 {
                shouldUpdateConstraints = true
                self.exitButtonWidth.constant = 8.0
            }
        } else {
            if self.exitButtonWidth.constant != 44.0 {
                shouldUpdateConstraints = true
                self.exitButtonWidth.constant = 44.0
            }
        }
        
        if shouldUpdateConstraints {
            if animated {
                UIView.animate(withDuration: 0.25, animations: {
                    self.view.layoutIfNeeded()
                })
            } else {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    private func checkSessionDates() {
        let currentTimestamp = self.serverTimestamp
        let sessionStartTimestamp = self.sessionModel.startTimestamp ?? 0
        let sessionEndTimestamp = self.sessionModel.startTimestamp + Int64(self.sessionModel.duration * 60)
        
        if !self.sessionStarted && self.sessionConnected {
            let timeLeftSeconds = Double(sessionStartTimestamp - currentTimestamp)
            if timeLeftSeconds > 0 {
                let minutes = Int(timeLeftSeconds / 60)
                let seconds = Int(timeLeftSeconds) - (minutes * 60)
                let timeLeft = String(format: "%02d:%02d", arguments: [minutes, seconds])
                self.connectionStatusLabel.text = timeLeft
            } else {
                if self.isSessionOwner() {
                    self.connectionStatusLabel.text = ApplicationMessages.ButtonsTitles.ready
                } else {
                    self.connectionStatusLabel.text = ApplicationMessages.ButtonsTitles.wait
                }
            }
        } else {
            if self.sessionConnected {
                self.connectionStatusLabel.text = ApplicationMessages.ButtonsTitles.live
            } else {
                self.connectionStatusLabel.text = ApplicationMessages.ButtonsTitles.wait
            }
        }
        
        if self.sessionStarted && self.sessionConnected {
            if currentTimestamp >= sessionEndTimestamp {
                self.stopTimeUpdateTimer()
                
                if self.isSessionOwner() {
                    self.finishSession()
                } else {
                    self.finishSessionWithFinishedView()
                }
            }
        }
    }
    
    // MARK: Session Methods
    
    private func enterSession() {
        guard let sessionID = self.sessionModel.id, let sessionCreatorID = self.sessionModel.creatorID else {
            return
        }
        
        if !self.sessionConnecting {
            self.sessionConnecting = true
            self.videoStreamService.enterSession(withID: sessionID, sessionCreatorID: sessionCreatorID, user: self.authorisedUserModel)
        }
    }
    
    private func exitSession() {
        self.showLoadingView()
        
        self.presentingViewController?.dismiss(animated: true, completion: { [weak self]() in
            self?.videoStreamService.exitSession()
            self?.hideLoadingView()
        })
    }
    
    private func finishSession() {
        guard let sessionID = self.sessionModel.id else {
            return
        }
        
        self.finishSessionMethod = self.videoStreamService.finishSession(withID: sessionID, user: self.authorisedUserModel)
    }
    
    private func startSession() {
        guard let sessionID = self.sessionModel.id else {
            return
        }
        
        self.startSessionMethod = self.videoStreamService.startSession(withID: sessionID, user: self.authorisedUserModel)
    }
    
    private func showVideoView() {
        if self.isSessionOwner() {
            self.microphoneButton?.isHidden = (self.cameraView == nil || !self.sessionStarted || !self.sessionConnected)
            self.cameraButton?.isHidden = (self.cameraView == nil || !self.sessionStarted || !self.sessionConnected)
            self.switchButton?.isHidden = (self.cameraView == nil || !self.sessionStarted || !self.sessionConnected)
        }
        
        if let streamingView = self.streamingView as? RTCEAGLVideoView {
            streamingView.delegate = self
            self.videoContainerView.addSubview(streamingView)
        } else if let streamingView = self.streamingView {
            print("USING METAL")
            self.videoContainerView.addSubview(streamingView)
        } else if let cameraView = self.cameraView {
            self.videoContainerView.addSubview(cameraView)
        }
    }
    
    private func hideVideoView() {
        NSLayoutConstraint.deactivate(self.videoViewConstraints)
        
        if let streamingView = self.streamingView {
            //EAGLContext.setCurrent(nil)
            
            if let streamingView = self.streamingView as? RTCEAGLVideoView {
                streamingView.delegate = nil
            }
            streamingView.removeFromSuperview()
        } else if let cameraView = self.cameraView {
            cameraView.removeFromSuperview()
        }
        
        self.configureVideoViewConstraints(withSize: self.videoContainerView.bounds.size)
    }
    
    // MARK: Permissions
    
    private func checkMediaPermissions(_ completion: @escaping (() -> ())) {
        if self.isSessionOwner() {
            self.checkMicrophonePermission({ [weak self] (granted) in
                if granted {
                    self?.checkCameraPermission({ [weak self] (granted) in
                        if granted {
                            completion()
                        } else {
                            self?.showPermissionAlert(withMicrophonePermission: true, camera: false)
                        }
                    })
                } else {
                    let recordPermission = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
                    let cameraGranted = (recordPermission == AVAuthorizationStatus.authorized)
                    self?.showPermissionAlert(withMicrophonePermission: false, camera: cameraGranted)
                }
            })
        } else {
            completion()
        }
    }
    
    private func showPermissionAlert(withMicrophonePermission microphone: Bool, camera: Bool) {
        let title = ((!microphone && !camera) ? ApplicationMessages.AlertTitles.cameraAndMicrophonePermissionDenied : (!microphone ? ApplicationMessages.AlertTitles.microphonePermissionDenied  : ApplicationMessages.AlertTitles.cameraPermissionDenied))
        let message = ApplicationMessages.ErrorMessages.streamPermissions
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: ApplicationMessages.AlertButtonsTitles.close, style: .cancel, handler: { [weak self] (action) in
            self?.exitSession()
        }))
        alertController.addAction(UIAlertAction(title: ApplicationMessages.AlertButtonsTitles.settings, style: .default, handler: { [weak self] (action) in
            self?.openSettings()
            self?.exitSession()
        }))
        self.present(alertController, animated: true, completion: nil)
    }
    
    // MARK: Support Methods
    
    private func changeChatReadyForSending() {
        guard let readyForSending = self.streamChatViewController?.readyForSending else {
            return
        }
        
        if readyForSending != self.sessionConnected {
            self.streamChatViewController?.readyForSending = self.sessionConnected
        }
    }
    
    private func configureConnectionStatusView() {
        if self.sessionFinished {
            self.connectionStatusView?.isHidden = true
        } else {
            self.connectionStatusView?.isHidden = false
            
            if self.sessionStarted && self.streamConnected {
                self.connectionStatusView?.backgroundColor = UIColor.tv_redColor()
                self.connectionStatusLabel?.textColor = UIColor.white
            } else {
                self.connectionStatusView?.backgroundColor = UIColor.tv_darkColor()
                self.connectionStatusLabel?.textColor = UIColor.tv_grayTextColor()
            }
        }
    }
    
    private func showFinishConfirmation() {
        let title = ApplicationMessages.AlertTitles.finishSession
        let message = ApplicationMessages.Instructions.undone
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: ApplicationMessages.AlertButtonsTitles.no, style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: ApplicationMessages.AlertButtonsTitles.yes, style: .default, handler: { [weak self] (action) in
            self?.finishSession()
        }))
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func isSessionOwner() -> Bool {
        let sessionOwner = (self.sessionModel.creatorID != nil && self.sessionModel.creatorID == self.authorisedUserModel.id)
        return sessionOwner
    }
    
    private func showDismissalAlert(withTitle title: String, message: String?, retry: Bool) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: ApplicationMessages.AlertButtonsTitles.close, style: .cancel, handler: { [weak self] (action) in
            self?.exitSession()
        }))
        if retry {
            alertController.addAction(UIAlertAction(title: ApplicationMessages.AlertButtonsTitles.retry, style: .default, handler: { [weak self] (action) in
                self?.enterSession()
            }))
        }
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func showFinishedView() {
        self.view.endEditing(true)
        
        if let streamInfo = self.streamInfoModel {
            if let presentedViewController = self.presentedViewController {
                if let overlayPresentedViewController = presentedViewController.presentedViewController {
                    overlayPresentedViewController.dismiss(animated: false, completion: {
                        presentedViewController.dismiss(animated: false, completion: {
                            self.router.showFinishStreamViewController(withAuthorisedUserModel: self.authorisedUserModel, streamInfoModel: streamInfo, sessionOwner: self.isSessionOwner())
                        })
                    })
                } else {
                    presentedViewController.dismiss(animated: false, completion: {
                        self.router.showFinishStreamViewController(withAuthorisedUserModel: self.authorisedUserModel, streamInfoModel: streamInfo, sessionOwner: self.isSessionOwner())
                    })
                }
            } else {
                self.router.showFinishStreamViewController(withAuthorisedUserModel: self.authorisedUserModel, streamInfoModel: streamInfo, sessionOwner: self.isSessionOwner())
            }
        }
    }
    
    private func finishSessionWithFinishedView() {
        if self.sessionFinished {
            return
        }
        
        self.sessionFinished = true
        
        self.videoStreamService.exitSession()
        self.sessionConnecting = false
        self.sessionConnected = false
        
        self.configureButtonsAndLabels()
        
        NotificationCenter.default.post(name: Notification.Name(CreateCoursesNotificationNames.subscribedSessionFinished), object: self.sessionModel)
        
        self.showFinishedView()
    }
    
    private func configureVideoViewConstraints(withSize size: CGSize) {
        if self.videoViewConstraints.count > 0 {
            NSLayoutConstraint.deactivate(self.videoViewConstraints)
        }
        
        self.videoViewConstraints = []
        
        if let streamingView = self.streamingView, let _ = self.streamingView?.superview  {
            var availableSize = self.videoContainerView.bounds.size
            if availableSize.width / availableSize.height < size.width / size.height {
                availableSize.width = availableSize.height * size.width / size.height
            }
            
            self.videoViewConstraints.append(NSLayoutConstraint(item: streamingView, attribute: .centerX, relatedBy: .equal, toItem: self.videoContainerView, attribute: .centerX, multiplier: 1.0, constant: 0.0))
            self.videoViewConstraints.append(NSLayoutConstraint(item: streamingView, attribute: .centerY, relatedBy: .equal, toItem: self.videoContainerView, attribute: .centerY, multiplier: 1.0, constant: 0.0))
            self.videoViewConstraints.append(NSLayoutConstraint(item: streamingView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: availableSize.width))
            self.videoViewConstraints.append(NSLayoutConstraint(item: streamingView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: availableSize.height))
            NSLayoutConstraint.activate(self.videoViewConstraints)
        } else if let cameraView = self.cameraView, let _ = self.cameraView?.superview {
            let availableSize = self.videoContainerView.bounds.size
            self.videoViewConstraints.append(NSLayoutConstraint(item: cameraView, attribute: .centerX, relatedBy: .equal, toItem: self.videoContainerView, attribute: .centerX, multiplier: 1.0, constant: 0.0))
            self.videoViewConstraints.append(NSLayoutConstraint(item: cameraView, attribute: .centerY, relatedBy: .equal, toItem: self.videoContainerView, attribute: .centerY, multiplier: 1.0, constant: 0.0))
            self.videoViewConstraints.append(NSLayoutConstraint(item: cameraView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: availableSize.width))
            self.videoViewConstraints.append(NSLayoutConstraint(item: cameraView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: availableSize.height))
            NSLayoutConstraint.activate(self.videoViewConstraints)
        }
        
        self.videoContainerView.updateConstraints()
        self.videoContainerView.layoutIfNeeded()
    }
    
    private func setActivityIndicator(animating: Bool) {
        let isAnimating = self.activityIndicator?.isAnimating ?? false
        if animating {
            if !isAnimating {
                self.activityIndicator?.startAnimating()
            }
        } else {
            if isAnimating {
                self.activityIndicator?.stopAnimating()
            }
        }
    }
    
    private func animateChatButton() {
        chatButton.playBounceAnimation()
    }
    
    // MARK: Controls Actions
    
    @IBAction func hideBottomControlsButtonAction(_ sender: UIButton) {
        self.view.endEditing(true)
        
        self.bottomControlsState = .none
        self.updateBottomControlsConstraints(animated: true)
    }
    
    @IBAction func chatButtonAction(_ sender: UIButton) {
        self.bottomControlsState = .chat
        self.updateBottomControlsConstraints(animated: true)
        chatButton.stopBounceAnimation()
    }
    
    @IBAction func attachmentsButtonAction(_ sender: UIButton) {
        self.bottomControlsState = .attachments
        self.updateBottomControlsConstraints(animated: true)
    }
    
    @IBAction func infoButtonAction(_ sender: UIButton) {
        self.bottomControlsState = .info
        self.updateBottomControlsConstraints(animated: true)
    }
    
    @IBAction func exitButtonAction(_ sender: UIButton) {
        self.view.endEditing(true)
        
        self.exitSession()
    }
    
    @IBAction func startButtonAction(_ sender: UIButton) {
        self.view.endEditing(true)
        
        self.startSession()
    }
    
    @IBAction func finishButtonAction(_ sender: UIButton) {
        self.view.endEditing(true)
        
        self.showFinishConfirmation()
    }
    
    @IBAction func microphoneButtonAction(_ sender: UIButton) {
        let microphoneEnabled = !self.microphoneEnabled
        sender.alpha = (microphoneEnabled ? 1.0 : 0.33)
        
        self.microphoneEnabled = microphoneEnabled
        self.videoStreamService.setMicrophoneEnabled(enabled: microphoneEnabled)
    }
    
    @IBAction func cameraButtonAction(_ sender: UIButton) {
        let videoEnabled = !self.videoEnabled
        sender.alpha = (videoEnabled ? 1.0 : 0.33)
        
        self.videoEnabled = videoEnabled
        self.videoStreamService.setCameraEnabled(enabled: videoEnabled)
    }
    
    @IBAction func switchButtonAction(_ sender: UIButton) {
        self.videoStreamService.toggleCamera()
    }
    
    // MARK: Protocols Implementation
    
    // MARK: RTCEAGLVideoViewDelegate
    
    internal func videoView(_ videoView: RTCVideoRenderer, didChangeVideoSize size: CGSize) {
        guard let _ = self.streamingView else {
            return
        }
        
        #if DEBUG
            print("RTCEAGLVideoView did change video size to \(size) ", videoView)
        #endif
        
        self.configureVideoViewConstraints(withSize: size)
    }
    
    // MARK: VideoStreamServiceDelegate
    
    internal func streamReceiverHandle(taskResult result: VideoStreamServiceTaskResult) {
        switch result {
        case .serviceDidEnterSession(let serverTime, let session, let stream, let errorMessage, let sessionStarted, let sessionFinished):
            if serverTime != nil && session != nil && stream != nil && errorMessage == nil {
                self.serverTimestamp = serverTime!
                self.sessionModel.update(withDictionary: session!)
                self.streamInfoModel = StreamInfoModel(withDictionary: stream!)
            }
            
            self.applySessionStartedState(sessionStarted: sessionStarted)
            
            if sessionFinished {
                self.finishSessionWithFinishedView()
            } else if sessionStarted {
                if !self.isSessionOwner() {
                    self.videoStreamService.startWatching(withServers: self.streamInfoModel?.iceServers)
                } else {
                    self.videoStreamService.startStreaming(withServers: self.streamInfoModel?.iceServers)
                }
            }
            
            if serverTime != nil && session != nil && stream != nil && errorMessage == nil {
                self.sessionConnecting = false
                self.applySessionConnected(true)
            } else {
                self.videoStreamService.exitSession()
                self.sessionConnecting = false
                self.sessionConnected = false
                
                NotificationCenter.default.post(name: Notification.Name(CreateCoursesNotificationNames.subscribedSessionFinished), object: self.sessionModel)
                
                self.showDismissalAlert(withTitle: ApplicationMessages.AlertTitles.message, message: errorMessage, retry: true)
            }
            break
        case .serviceWaitingForSession():
            self.hideLoadingView()
            self.applySessionConnected(false)
            break
        case .serviceLogoutedFromSession(let error):
            self.hideLoadingView()
            self.videoStreamService.exitSession()
            self.sessionConnecting = false
            self.sessionConnected = false
            
            let message = error ?? ApplicationMessages.ErrorMessages.forceLogout
            self.showDismissalAlert(withTitle: ApplicationMessages.AlertTitles.sessionStopped, message: message, retry: false)
            break
        case .serviceShouldShowStreamingView(let streamingView):
            self.streamingView = streamingView
            if !self.isSessionOwner() {
                self.streamingView?.isHidden = !self.videoEnabled || !self.streamConnected
            }
            break
        case .serviceShouldHideStreamingView:
            self.streamingView = nil
            break
        case .serviceShouldShowCameraView(let cameraView):
            self.cameraView = cameraView
            break
        case .serviceFinishedSession(let session, let stream):
            if session != nil {
                self.sessionModel.update(withDictionary: session!)
            }
            
            if stream != nil {
                self.streamInfoModel = StreamInfoModel(withDictionary: stream!)
            }
            
            if !self.isSessionOwner() {
                self.finishSessionWithFinishedView()
            }
            break
        case .serviceStartedSession():
            self.applySessionStartedState(sessionStarted: true)
            
            if !self.isSessionOwner() {
                self.videoStreamService.startWatching(withServers: self.streamInfoModel?.iceServers)
            }
            break
        case .serviceStreamPublished():
            if !self.isSessionOwner() {
                self.videoStreamService.continueWatching(withServers: self.streamInfoModel?.iceServers)
            }
            break
        case .serviceStartedStreaming():
            self.applySessionConnected(self.sessionConnected)
            break
        case .serviceDidChangeStreamState(let state):
            if state == .completed || state == .connected {
                self.streamConnected = true
                if !self.isSessionOwner() {
                    self.streamingView?.isHidden = !self.videoEnabled || !self.streamConnected
                }
            } else {
                self.streamConnected = false
                if let _ = self.streamingView {
                    self.streamingView = nil
                }
            }
            self.configureButtonsAndLabels()
            break
        case .serviceChangedVideoEnabled(let enabled):
            if !self.isSessionOwner() {
                self.videoEnabled = enabled
                self.streamingView?.isHidden = !enabled || !self.streamConnected
            } else {
                // This is to fix disabled video when streamer are back from airplane mode
                self.videoStreamService.setCameraEnabled(enabled: enabled)
            }
            break
        }
    }
    
    // MARK: StreamChatServiceDelegate
    
    public func chatReceiverHandle(taskResult result: StreamChatServiceTaskResult) {
        switch result {
        case .serviceDidReceiveMessage(_):
            if bottomControlsState != .chat {
                animateChatButton()
            }
            break
        default:
            break
        }
        
        self.streamChatViewController.chatReceiverHandle(taskResult: result)
    }

}
