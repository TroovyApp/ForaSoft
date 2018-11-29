//
//  SessionPageViewController.swift
//  troovy-ios
//
//  Created by Daniil on 26.09.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class SessionPageViewController: TroovyViewController, CreateSessionDelegate, UIScrollViewDelegate {
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var topSeparatorView: UIView!
    
    @IBOutlet weak var exitButton: UIButton!
    @IBOutlet weak var actionsButton: UIButton!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var sessionTitleLabel: UILabel!
    @IBOutlet weak var sessionDescriptionLabel: UILabel!
    @IBOutlet weak var sessionStartTimeLabel: UILabel!
    @IBOutlet weak var sessionEndTimeLabel: UILabel!
    @IBOutlet weak var sessionStartDateLabel: UILabel!
    @IBOutlet weak var sessionEndDateLabel: UILabel!
    @IBOutlet weak var sessionTipLabel: UILabel!
    @IBOutlet weak var enterButton: UIButton!
    
    // MARK: Public Properties
    
    /// Model of the unauthorised user.
    var authorisedUserModel: AuthorisedUserModel?
    
    /// Course session model.
    var sessionModel: CourseSessionModel!
    
    // MARK: Private Properties
    
    private var verificationService: VerificationService!
    private var coursesService: CoursesService!
    private var createCoursesService: CreateCoursesService!
    
    private var dateFormatter: DateFormatter!
    private var timeFormatter: DateFormatter!
    
    private var timeUpdateTime: Timer?
    
    private var cancelSessionMethod: String?
    
    // MARK: Init Methods & Superclass Overriders

    override func viewDidLoad() {
        super.viewDidLoad()
        self.titleLabel.text = ApplicationMessages.ScreenTitles.sessionScreen
        
        self.setupDateFormatters()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.hideLoadingView()
        self.structSessionInfo()
        self.startTimeUpdateTimer()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.configureSeparatorsStateForScroll()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.stopTimeUpdateTimer()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func inject(propertiesWithAssembly assembly: ViewControllerAssemblyManager) {
        self.verificationService = assembly.verificationService
        self.coursesService = assembly.coursesService
        self.createCoursesService = assembly.createCoursesService
    }
    
    override func configureServices() {
        self.createCoursesService.delegate = self
    }
    
    override func serviceMethodSucceeded(withMethod method: String, resultDictionary: [String : Any]?, resultArray: [[String : Any]]?, resultString: String?) {
        if method == self.cancelSessionMethod {
            NotificationCenter.default.post(name: Notification.Name(CreateCoursesNotificationNames.subscribedSessionFinished), object: self.sessionModel)
            
            self.coursesService.deleteOwnSession(self.sessionModel)
            self.showDismissalAlert(withTitle: ApplicationMessages.AlertTitles.success, message: ApplicationMessages.SuccessMessages.sessionCancelled)
        }
    }
    
    override func showLoadingView(withMethod method: String) {
        if method == self.cancelSessionMethod {
            self.showLoadingView()
        } else {
            super.showLoadingView(withMethod: method)
        }
    }
    
    // MARK: Private Methods
    
    private func setupDateFormatters() {
        self.dateFormatter = DateFormatter()
        self.dateFormatter.locale = Locale(identifier: "en_US")
        self.dateFormatter.dateFormat = "d MMM yyyy"
        
        self.timeFormatter = DateFormatter()
        self.timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        self.timeFormatter.dateFormat = "h:mm a"
    }
    
    private func configureSeparatorsStateForScroll() {
        self.topSeparatorView.isHidden = !(self.scrollView.contentOffset.y >= 12.0)
    }
    
    private func structSessionInfo() {
        self.sessionTitleLabel.text = self.sessionModel.title
        self.sessionDescriptionLabel.text = self.sessionModel.specification
        
        let startDate = Date(timeIntervalSince1970: TimeInterval(self.sessionModel.startTimestamp))
        self.sessionStartTimeLabel.text = self.timeFormatter.string(from: startDate)
        self.sessionStartDateLabel.text = self.dateFormatter.string(from: startDate)
        
        let endDate = Date(timeIntervalSince1970: TimeInterval(self.sessionModel.startTimestamp + Int64(self.sessionModel.duration * 60)))
        self.sessionEndTimeLabel.text = self.timeFormatter.string(from: endDate)
        self.sessionEndDateLabel.text = self.dateFormatter.string(from: endDate)
        
        if let userModel = self.authorisedUserModel {
            let sessionEnterMinutesLeft = self.verificationService.sessionEnterMinutesLeft()
            self.sessionTipLabel.text = ApplicationMessages.Instructions.enterSessionMessage(withMinutesLeft: sessionEnterMinutesLeft)
            
            if self.sessionModel.creatorID != nil && self.sessionModel.creatorID == userModel.id {
                self.actionsButton.isHidden = false
            } else {
                self.actionsButton.isHidden = true
            }
        } else {
            let sessionEnterMinutesLeft = self.verificationService.sessionEnterMinutesLeft()
            self.sessionTipLabel.text = ApplicationMessages.Instructions.enterSessionUnregisteredMessage(withMinutesLeft: sessionEnterMinutesLeft)
            
            self.actionsButton.isHidden = true
            self.enterButton.isHidden = true
        }
        
        if self.presentingViewController != nil {
            self.exitButton.setImage(UIImage.tv_navbarCloseSmall(), for: .normal)
        } else {
            self.exitButton.setImage(UIImage.tv_navbarBack(), for: .normal)
        }
        
        self.checkEnterMinutesLeft()
        self.configureSeparatorsStateForScroll()
    }
    
    private func checkEnterMinutesLeft() {
        if self.authorisedUserModel == nil {
            return
        }
        
        let currentTimestamp = Int64(Date().timeIntervalSince1970)
        let startTimestamp = self.sessionModel.startTimestamp!
        let endTimestamp = self.sessionModel.startTimestamp! + Int64(self.sessionModel.duration * 60)
        let sessionEnterMinutesLeft = self.verificationService.sessionEnterMinutesLeft()
        
        if (endTimestamp - currentTimestamp) <= 0 {
            self.enterButton.isHidden = true
            self.sessionTipLabel.isHidden = true
        } else {
            if (startTimestamp - currentTimestamp) <= (sessionEnterMinutesLeft * 60) {
                self.enterButton.isHidden = false
                self.sessionTipLabel.isHidden = true
            } else {
                self.enterButton.isHidden = true
                self.sessionTipLabel.isHidden = false
            }
        }
    }
    
    private func startTimeUpdateTimer() {
        if self.timeUpdateTime != nil || self.authorisedUserModel == nil {
            return
        }
        
        self.timeUpdateTime = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] (timer) in
            DispatchQueue.main.async {
                self?.checkEnterMinutesLeft()
            }
        })
    }
    
    private func stopTimeUpdateTimer() {
        self.timeUpdateTime?.invalidate()
        self.timeUpdateTime = nil
    }
    
    private func editSession() {
        guard let userModel = self.authorisedUserModel else {
            return
        }
        
        self.router.showCourseSessionScreen(withAuthorisedUserModel: userModel, sessionModel: self.sessionModel, courseSessionAlwaysEditable: false, delegate: self)
    }
    
    private func cancelSession() {
        self.showCancelConfirmation()
    }
    
    private func cancelSessionConfirmed() {
        guard let sessionID = self.sessionModel.id, let userModel = self.authorisedUserModel else {
            return
        }
        
        self.cancelSessionMethod = self.createCoursesService.deleteSession(withSessionID: sessionID, user: userModel)
    }
    
    private func showCancelConfirmation() {
        let title = ApplicationMessages.AlertTitles.cancelSession
        let message = ApplicationMessages.Instructions.undone
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: ApplicationMessages.AlertButtonsTitles.no, style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: ApplicationMessages.AlertButtonsTitles.yes, style: .default, handler: { [weak self] (action) in
            self?.cancelSessionConfirmed()
        }))
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func showDismissalAlert(withTitle title: String, message: String?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: ApplicationMessages.AlertButtonsTitles.ok, style: .cancel, handler: { [weak self] (action) in
            if self?.presentingViewController != nil {
                self?.presentingViewController?.dismiss(animated: true, completion: nil)
            } else {
                self?.navigationController?.popToRootViewController(animated: true)
            }
        }))
        self.present(alertController, animated: true, completion: nil)
    }
    
    // MARK: Control Actions
    
    @IBAction func actionsButtonAction(_ sender: UIBarButtonItem) {
        let actionSheetMenu = UIAlertController(title: ApplicationMessages.AlertTitles.chooseAction, message: nil, preferredStyle: .actionSheet)
        actionSheetMenu.addAction(UIAlertAction(title: ApplicationMessages.AlertButtonsTitles.close, style: .cancel, handler: nil))
        actionSheetMenu.addAction(UIAlertAction(title: ApplicationMessages.AlertButtonsTitles.editSession, style: .default, handler: { [weak self] (action) in
            self?.editSession()
        }))
        actionSheetMenu.addAction(UIAlertAction(title: ApplicationMessages.AlertButtonsTitles.cancelSession, style: .default, handler: { [weak self] (action) in
            self?.cancelSession()
        }))
        
        self.present(actionSheetMenu, animated: true, completion: nil)
    }
    
    @IBAction func exitButtonAction(_ sender: UIButton) {
        if self.presentingViewController != nil {
            self.presentingViewController?.dismiss(animated: true, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func enterButtonAction(_ sender: UIButton) {
        guard let userModel = self.authorisedUserModel else {
            return
        }
        
        let sessionOwner = self.sessionModel.creatorID != nil && userModel.id == self.sessionModel.creatorID
        self.router.showVideoStreamViewController(withAuthorisedUserModel: userModel, sessionModel: self.sessionModel, sessionOwner: sessionOwner)
    }
    
    // MARK: Protocols Implementation
    
    // MARK: CreateSessionDelegate
    
    internal func sessionView(view: UIViewController, didChangeCourseSessionModel model: CourseSessionModel) {
        self.coursesService.updateCourseSession(withModel: model)
        self.structSessionInfo()
    }
    
    internal func sessionView(view: UIViewController, didCreateCourseSessionModel model: CourseSessionModel) {
        // Nothing to do.
    }
    
    internal func sessionView(view: UIViewController, checkNewSessionModelDoesNotConflictWithOthers model: CourseSessionModel) -> Bool {
        return true
    }
    
    internal func sessionViewSelectedCourseID(view: UIViewController) -> String? {
        return self.sessionModel.courseID
    }
    
    // MARK: UIScrollViewDelegate
    
    internal func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.configureSeparatorsStateForScroll()
    }

}
