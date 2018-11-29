//
//  CreateSessionViewController.swift
//  troovy-ios
//
//  Created by Daniil on 28.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class CreateSessionViewController: TroovyViewController, UITableViewDelegate, UITableViewDataSource, StepInfoCellDelegate {
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var navigationBar: UINavigationItem!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var topShadowView: ShadowView!
    @IBOutlet weak var bottomShadowView: ShadowView!
    @IBOutlet weak var nextButton: UIButton!
    
    @IBOutlet weak var bottomShadowViewToBottom: NSLayoutConstraint!
    @IBOutlet weak var nextButtonToBottom: NSLayoutConstraint!
    @IBOutlet weak var tableViewToBottom: NSLayoutConstraint!
    
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
    
    private var verificationService: VerificationService!
    private var createCoursesService: CreateCoursesService!
    
    private var createCourseHintsViewController: CreateCourseHintsViewController?
    
    private var bottomShadowViewToBottomValue: CGFloat?
    private var nextButtonToBottomValue: CGFloat?
    private var tableViewToBottomValue: CGFloat?
    
    private var steps: [StepInfo] = []
    private var selectedStep: StepInfo?
    
    private var createCourseSessionMethod: String?
    private var editCourseSessionMethod: String?
    
    // MARK: Init Methods & Superclass Overriders
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationBar.title = (self.courseSessionModel != nil ? (self.isEditable() ? ApplicationMessages.ScreenTitles.editSessionScreen : ApplicationMessages.ScreenTitles.sessionScreen) : ApplicationMessages.ScreenTitles.createSessionScreen)
        
        self.topShadowView.setupGradientShadow(fromColor: UIColor(white: 1.0, alpha: 1.0), toColor: UIColor(white: 1.0, alpha: 0.0))
        self.bottomShadowView.setupGradientShadow(fromColor: UIColor(white: 1.0, alpha: 0.0), toColor: UIColor(white: 1.0, alpha: 1.0))
        self.nextButton.alpha = 0.0
        self.tableViewToBottomValue = self.tableViewToBottom.constant
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        self.configure()
        self.checkFieldsFilled()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.changeTableInsets()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let createCourseHintsViewController = segue.destination as? CreateCourseHintsViewController {
            let sessionEnterMinutesLeft = self.verificationService.sessionEnterMinutesLeft()
            
            self.createCourseHintsViewController = createCourseHintsViewController
            self.createCourseHintsViewController?.hints = ["Write down in a clear and short description of what your session about.",
                                                           "Emphasize at least 3 benefits someone will reap from attending the session.",
                                                           "You will be able to enter a session \(sessionEnterMinutesLeft) minutes before the time you set.",
                                                           "The session will last no more than the time specified in the duration."]
        }
    }
    
    override func inject(propertiesWithAssembly assembly: ViewControllerAssemblyManager) {
        self.verificationService = assembly.verificationService
        self.createCoursesService = assembly.createCoursesService
    }
    
    override func configureServices() {
        self.createCoursesService.delegate = self
    }
    
    override func serviceMethodSucceeded(withMethod method: String, resultDictionary: [String : Any]?, resultArray: [[String : Any]]?, resultString: String?) {
        if method == self.createCourseSessionMethod {
            if let sessionInfo = resultDictionary {
                let courseSession = CourseSessionModel(withDictionary: sessionInfo)
                self.delegate?.sessionView(view: self, didCreateCourseSessionModel: courseSession)
                
                NotificationCenter.default.post(name: Notification.Name(CreateCoursesNotificationNames.subscribedSessionsChanged), object: nil)
            }
            self.presentingViewController?.dismiss(animated: true, completion: nil)
        } else if method == self.editCourseSessionMethod {
            if let sessionInfo = resultDictionary, let session = self.courseSessionModel {
                session.update(withDictionary: sessionInfo)
                
                self.delegate?.sessionView(view: self, didChangeCourseSessionModel: session)
            }
            self.presentingViewController?.dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: Notifications & Observers
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let info = notification.userInfo else {
            return
        }
        
        if self.nextButtonToBottomValue == nil {
            self.nextButtonToBottomValue = self.nextButtonToBottom.constant
        }
        
        if self.tableViewToBottomValue == nil {
            self.tableViewToBottomValue = self.tableViewToBottom.constant
        }
        
        if self.bottomShadowViewToBottomValue == nil {
            self.bottomShadowViewToBottomValue = self.bottomShadowViewToBottom.constant
        }
        
        let keyboardFrame = (info[UIKeyboardFrameEndUserInfoKey] as? CGRect) ?? CGRect.zero
        let animationDuration = (info[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval) ?? 0.0
        if self.nextButtonToBottom.constant != keyboardFrame.size.height + 4.0 || self.tableViewToBottom.constant != keyboardFrame.size.height || self.bottomShadowViewToBottom.constant != keyboardFrame.size.height {
            self.nextButtonToBottom.constant = keyboardFrame.size.height + 4.0
            self.tableViewToBottom.constant = keyboardFrame.size.height
            self.bottomShadowViewToBottom.constant = keyboardFrame.size.height
            
            UIView.animate(withDuration: animationDuration, animations: {
                self.nextButton.alpha = 1.0
                self.createCourseHintsViewController?.view.alpha = 0.0
                self.view.layoutIfNeeded()
            })
        }
        
        let selectedIndex = self.steps.index(where: {$0.identificator == selectedStep?.identificator})
        if let selectedIndex = selectedIndex {
            DispatchQueue.main.async {
                self.tableView.scrollToRow(at: IndexPath(row: selectedIndex, section: 0), at: .middle, animated: true)
            }
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let info = notification.userInfo else {
            return
        }
        
        let animationDuration = (info[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval) ?? 0.0
        if self.nextButtonToBottom.constant != self.nextButtonToBottomValue || self.tableViewToBottom.constant != self.tableViewToBottomValue || self.bottomShadowViewToBottom.constant != self.bottomShadowViewToBottomValue {
            self.nextButtonToBottom.constant = self.nextButtonToBottomValue ?? 0.0
            self.tableViewToBottom.constant = self.tableViewToBottomValue ?? 0.0
            self.bottomShadowViewToBottom.constant = self.bottomShadowViewToBottomValue ?? 0.0
            
            UIView.animate(withDuration: animationDuration, animations: {
                self.nextButton.alpha = 0.0
                self.createCourseHintsViewController?.view.alpha = 1.0
                self.view.layoutIfNeeded()
            })
        }
    }
    
    // MARK: Private Methods
    
    private func configure() {
        if self.steps.count > 0 {
            return
        }
        
        if !self.isEditable() {
            self.navigationBar.rightBarButtonItem = nil
        }
        
        var steps: [StepInfo] = []
        for index in 0..<CreateSessionSteps.count.rawValue {
            if let stepType = CreateSessionSteps(rawValue: index), let step = self.createStep(withType: stepType, courseSessionModel: self.courseSessionModel) {
                steps.append(step)
            }
        }
        
        self.steps = steps
        self.selectedStep = steps.first
        
        self.changeTableInsets()
        self.tableView.reloadData()
        self.checkFieldsFilled()
    }
    
    private func changeTableInsets() {
        var topInset = ceil(self.view.bounds.height * 0.1837)
        if topInset > 115.0 {
            topInset = 115.0
        }
        
        var bottomInset = ceil(self.view.bounds.height * 0.219)
        if bottomInset > 120.0 {
            bottomInset = 120.0
        }
        
        if #available(iOS 11.0, *) {
            bottomInset -= self.view.safeAreaInsets.bottom
        }
        
        if self.tableView.contentInset.top != topInset {
            self.tableView.contentInset = UIEdgeInsetsMake(topInset, 0.0, bottomInset, 0.0)
        }
    }
    
    // MARK: Configure Steps
    
    private func createStep(withType type: CreateSessionSteps, courseSessionModel: CourseSessionModel?) -> StepInfo? {
        switch type {
        case .title:
            return StepInfo(title: "Session Headline", placeholder: "Put Here Your Session Headline", text: courseSessionModel?.title, media: nil, date: nil, segments: nil)
        case .description:
            return StepInfo(title: "Session Description", placeholder: "Describe What This Session is About", text: courseSessionModel?.specification, media: nil, date: nil, segments: nil)
        case .date:
            let timestamp = courseSessionModel?.startTimestamp ?? 0
            let date = (timestamp > 0 ? Date.init(timeIntervalSince1970: Double(timestamp)) : nil)
            return StepInfo(title: "Starts", placeholder: "Set a Date and Time", text: nil, media: nil, date: date, segments: nil)
        case .duration:
            let duration = courseSessionModel?.duration ?? 0
            let durationString = (duration > 0 ? "\(duration)" : nil)
            let segments = ["30", "45", "60"]
            return StepInfo(title: "Duration", placeholder: "Set a Duration", text: durationString, media: nil, date: nil, segments: segments)
        default:
            return nil
        }
    }
    
    private func configure(cell: StepInfoTableViewCell, forIndex index: Int) {
        if index >= self.steps.count {
            return
        }
        
        let step = self.steps[index]
        let stepType = CreateSessionSteps(rawValue: index)
        let stepOrder = (index + 1)
        let stepSelected = (step.identificator == self.selectedStep?.identificator)
        
        let previousStep = (index - 1 < 0 ? nil : self.steps[index - 1])
        let previousStepSelected = (previousStep != nil && previousStep!.identificator == self.selectedStep?.identificator)
        
        let nextStep = (index + 1 >= self.steps.count ? nil : self.steps[index + 1])
        let nextStepSelected = (nextStep != nil && nextStep!.identificator == self.selectedStep?.identificator)
        
        cell.configure(withStep: step, stepOrder: stepOrder, stepSelected: stepSelected, previousStep: previousStep, previousStepSelected: previousStepSelected, nextStep: nextStep, nextStepSelected: nextStepSelected, fullSizeHeight: CreateSessionStepsHeight.detailedHeight(forStepType: stepType))
        cell.contentContainer.isUserInteractionEnabled = self.isEditable()
        cell.delegate = self
    }
    
    private func deselect() {
        if self.selectedStep == nil {
            return
        }
        
        self.selectedStep = nil
        self.resizeSteps()
    }
    
    private func select(cell: StepInfoTableViewCell, forIndex index: Int) {
        if index >= self.steps.count {
            return
        }
        
        let step = self.steps[index]
        if self.selectedStep != nil && self.selectedStep?.identificator == step.identificator {
            return
        }
        
        self.selectedStep = step
        self.resizeSteps()
        
        DispatchQueue.main.async {
            self.tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .middle, animated: true)
            self.createCourseHintsViewController?.selectHit(atIndex: index, animated: true)
        }
    }
    
    private func currentContentSize() -> CGFloat {
        var totalHeight: CGFloat = 0.0
        for order in 0..<self.steps.count {
            let height = self.stepHeight(atIndex: order)
            totalHeight += height
        }
        
        return totalHeight
    }
    
    private func resizeSteps() {
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
        
        for indexPath in self.tableView.indexPathsForVisibleRows ?? [] {
            if let stepCell = self.tableView.cellForRow(at: indexPath) as? StepInfoTableViewCell {
                self.configure(cell: stepCell, forIndex: indexPath.row)
            }
        }
    }
    
    private func stepHeight(atIndex index: Int) -> CGFloat {
        let stepType = CreateSessionSteps(rawValue: index)
        
        if index < self.steps.count {
            let step = self.steps[index]
            let stepSelected = (step.identificator == self.selectedStep?.identificator)
            let stepFilled = step.isStepFilled()
            let nextStep = (index + 1 >= self.steps.count ? nil : self.steps[index + 1])
            let nextStepSelected = (nextStep != nil && nextStep!.identificator == self.selectedStep?.identificator)
            
            if stepType == CreateSessionSteps.date || stepType == CreateSessionSteps.duration {
                if stepSelected || nextStepSelected {
                    return CreateSessionStepsHeight.detailedHeight(forStepType: stepType)
                } else {
                    return CreateSessionStepsHeight.normalHeight(forStepType: stepType)
                }
            }
            
            if stepSelected || stepFilled || nextStepSelected {
                return CreateSessionStepsHeight.detailedHeight(forStepType: stepType)
            }
        }
        
        return CreateSessionStepsHeight.normalHeight(forStepType: stepType)
    }
    
    // MARK: Verification Methods
    
    private func checkFieldsFilled() {
        if self.steps.count == 0 {
            return
        }
        
        let sessionTitle = self.verificationService.check(string: self.steps[CreateSessionSteps.title.rawValue].text)
        let sessionDescription = self.verificationService.check(string: self.steps[CreateSessionSteps.description.rawValue].text)
        let startDateExists = (self.steps[CreateSessionSteps.date.rawValue].date != nil)
        let durationText = self.verificationService.check(string: self.steps[CreateSessionSteps.duration.rawValue].text)
        
        if sessionTitle != nil && sessionDescription != nil && startDateExists && durationText != nil {
            self.navigationBar.rightBarButtonItem?.isEnabled = true
        } else {
            self.navigationBar.rightBarButtonItem?.isEnabled = false
        }
    }
    
    private func checkFieldsInfo() {
        let sessionTitle = self.verificationService.check(string: self.steps[CreateSessionSteps.title.rawValue].text)
        let sessionDescription = self.verificationService.check(string: self.steps[CreateSessionSteps.description.rawValue].text)
        let dateTimeInterval = self.composeDateWithStartDateAndTime()
        let durationString = self.verificationService.check(numbers: self.steps[CreateSessionSteps.duration.rawValue].text)
        
        if sessionTitle != nil && sessionDescription != nil && dateTimeInterval != nil && durationString != nil {
            let startTimestamp = Int64(dateTimeInterval!)
            let duration = Int(durationString!)
            
            if self.courseSessionModel != nil {
                self.editSession(withTitle: sessionTitle!, sessionDescription: sessionDescription!, startTimestamp: startTimestamp, duration: duration!)
            } else {
                self.createSession(withTitle: sessionTitle!, sessionDescription: sessionDescription!, startTimestamp: startTimestamp, duration: duration!)
            }
        } else {
            self.showError(withSessionTitle: sessionTitle, sessionDescription: sessionDescription, dateTimeInterval: dateTimeInterval, duration: durationString)
        }
    }
    
    private func showError(withSessionTitle sessionTitle: String?, sessionDescription: String?, dateTimeInterval: TimeInterval?, duration: String?) {
        var messages: [String] = []
        
        if sessionTitle == nil || sessionTitle?.count == 0 {
            messages.append(ApplicationMessages.ErrorMessages.wrongSessionTitle)
        }
        
        if sessionDescription == nil || sessionDescription?.count == 0 {
            messages.append(ApplicationMessages.ErrorMessages.wrongSessionDescription)
        }
        
        if dateTimeInterval == nil {
            messages.append(ApplicationMessages.ErrorMessages.wrongSessionTime(withMinTime: self.verificationService.sessionEnterMinutesLeft()))
        }
        
        if duration == nil {
            messages.append(ApplicationMessages.ErrorMessages.wrongSessionDuration)
        }
        
        if messages.count > 0 {
            self.showAlert(withErrorsMessages: messages)
        }
    }
    
    // MARK: Session Methods
    
    private func editSession(withTitle title: String, sessionDescription: String, startTimestamp: Int64, duration: Int) {
        guard let session = self.courseSessionModel else {
            return
        }
        
        let courseSession = CourseSessionModel(withID: session.id, identifier: session.identifier, title: title, specification: sessionDescription, startTimestamp: startTimestamp, updatedTimestamp: session.updatedTimestamp, duration: duration)
        
        let (changedTitle, changedDescription, changedStartTimestamp, changedDuration) = self.checkSessionChanged(courseSession)
        if changedTitle != nil || changedDescription != nil || changedStartTimestamp != nil || changedDuration != nil {
            if self.delegate?.sessionView(view: self, checkNewSessionModelDoesNotConflictWithOthers: courseSession) ?? true {
                if let courseID = self.delegate?.sessionViewSelectedCourseID(view: self), let sessionID = session.id {
                    self.editCourseSessionMethod = self.createCoursesService.editCourseSession(withSessionID: sessionID, title: changedTitle, description: changedDescription, startTimestamp: changedStartTimestamp, duration: changedDuration, forCourseID: courseID, user: self.authorisedUserModel)
                } else {
                    session.update(withTitle: changedTitle, specification: changedDescription, startTimestamp: changedStartTimestamp, duration: changedDuration)
                    
                    self.delegate?.sessionView(view: self, didChangeCourseSessionModel: session)
                    self.presentingViewController?.dismiss(animated: true, completion: nil)
                }
            } else {
                self.showConflictError()
            }
        } else {
            self.presentingViewController?.dismiss(animated: true, completion: nil)
        }
    }
    
    private func createSession(withTitle title: String, sessionDescription: String, startTimestamp: Int64, duration: Int) {
        let courseSession = CourseSessionModel(withTitle: title, specification: sessionDescription, startTimestamp: startTimestamp, duration: duration)
        
        if self.delegate?.sessionView(view: self, checkNewSessionModelDoesNotConflictWithOthers: courseSession) ?? true {
            if let courseID = self.delegate?.sessionViewSelectedCourseID(view: self) {
                self.createCourseSessionMethod = self.createCoursesService.createCourseSession(withModel: courseSession, forCourseID: courseID, user: self.authorisedUserModel)
            } else {
                self.delegate?.sessionView(view: self, didCreateCourseSessionModel: courseSession)
                self.presentingViewController?.dismiss(animated: true, completion: nil)
            }
        } else {
            self.showConflictError()
        }
    }
    
    private func showConflictError() {
        self.showAlert(withTitle: ApplicationMessages.AlertTitles.message, message: ApplicationMessages.ErrorMessages.wrongSessionTiming)
    }
    
    private func checkSessionChanged(_ courseSession: CourseSessionModel) -> (String?, String?, Int64?, Int?) {
        let changedTitle = (self.courseSessionModel!.title != courseSession.title ? courseSession.title : nil)
        let changedDescription = (self.courseSessionModel!.specification != courseSession.specification ? courseSession.specification : nil)
        let changedStartTimestamp = (self.courseSessionModel!.startTimestamp != courseSession.startTimestamp ? courseSession.startTimestamp : nil)
        let changedDuration = (self.courseSessionModel!.duration != courseSession.duration ? courseSession.duration : nil)
        
        return (changedTitle, changedDescription, changedStartTimestamp, changedDuration)
    }
    
    // MARK: Support Methods
    
    private func composeDateWithStartDateAndTime() -> TimeInterval? {
        if let date = self.steps[CreateSessionSteps.date.rawValue].date, let dateTimeInterval = self.verificationService.check(time: date) {
            return dateTimeInterval
        }
        
        return nil
    }
    
    private func isEditable() -> Bool {
        if self.authorisedUserModel == nil {
            return false
        }
        
        if !self.courseSessionAlwaysEditable {
            if let session = self.courseSessionModel, let startTimestamp = session.startTimestamp {
                let currentTimestamp = Int64(Date().timeIntervalSince1970)
                if startTimestamp <= currentTimestamp {
                    return false
                }
            }
        }
        
        return true
    }
    
    // MARK: Controls Actions
    
    @IBAction func saveButtonAction(_ sender: UIButton) {
        self.view.endEditing(true)
        
        self.checkFieldsInfo()
    }
    
    @IBAction func nextButtonAction(_ sender: UIButton) {
        if let selectedStepIdentificator = self.selectedStep?.identificator, let index = self.steps.index(where: { $0.identificator == selectedStepIdentificator }) {
            let nextIndex = index + 1
            if nextIndex < self.steps.count {
                if let cell = self.tableView.cellForRow(at: IndexPath(row: nextIndex, section: 0)) as? StepInfoTableViewCell {
                    self.select(cell: cell, forIndex: nextIndex)
                }
            } else {
                self.deselect()
            }
        }
    }
    
    // MARK: Protocols Implementation
    
    // MARK: StepInfoCellDelegate
    
    internal func cell(_ cell: StepInfoTableViewCell, didResignFirstResponderWithOrder order: Int) {
        self.deselect()
    }
    
    internal func cell(_ cell: StepInfoTableViewCell, didBecomeFirstResponderWithOrder order: Int) {
        let index = (order - 1)
        self.select(cell: cell, forIndex: index)
    }
    
    internal func cell(_ cell: StepInfoTableViewCell, didChangeStep step: StepInfo, order: Int) {
        let index = (order - 1)
        
        if index < self.steps.count && index >= 0 {
            self.steps[index] = step
            self.checkFieldsFilled()
        }
    }
    
    internal func cell(_ cell: StepInfoTableViewCell, shouldChangeMediaForStep step: StepInfo, order: Int, mediaIndex: Int) {
        // Nothing to do
    }
    
    // MARK: UITableViewDelegate & UITableViewDataSource
    
    internal func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    internal func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return CreateSessionSteps.count.rawValue
    }
    
    internal func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let stepType = CreateSessionSteps(rawValue: indexPath.row)
        if stepType == .duration {
            let cell = tableView.dequeueReusableCell(withIdentifier: "StepSegmentsTableViewCell") as! StepSegmentsTableViewCell
            return cell
        } else if stepType == .date {
            let cell = tableView.dequeueReusableCell(withIdentifier: "StepDateTableViewCell") as! StepDateTableViewCell
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "StepTextInfoTableViewCell") as! StepTextInfoTableViewCell
            return cell
        }
    }
    
    internal func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let stepCell = cell as? StepInfoTableViewCell {
            self.configure(cell: stepCell, forIndex: indexPath.row)
        }
    }
    
    internal func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let index = indexPath.row
        return self.stepHeight(atIndex: index)
    }
    
    internal func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        let index = indexPath.row
        return self.stepHeight(atIndex: index)
    }
    
    internal func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let stepCell = tableView.cellForRow(at: indexPath) as? StepInfoTableViewCell {
            self.select(cell: stepCell, forIndex: indexPath.row)
        }
    }
    
    internal func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    internal func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect.zero)
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }
    
    internal func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let maximumContentSize: CGFloat = 300.0
        let currentContentSize: CGFloat = self.currentContentSize()
        
        var height: CGFloat = CGFloat.leastNormalMagnitude
        if (maximumContentSize - currentContentSize) > 0.0 {
            height = (maximumContentSize - currentContentSize)
        }
        
        return height
    }

}
