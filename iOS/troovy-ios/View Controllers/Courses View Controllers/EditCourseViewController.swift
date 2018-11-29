//
//  EditCourseViewController.swift
//  troovy-ios
//
//  Created by Daniil on 21.09.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices

import IQKeyboardManager

class EditCourseViewController: TroovyViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, StepInfoCellDelegate, StepDragCellDelegate {
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var topShadowView: ShadowView!
    @IBOutlet weak var bottomShadowView: ShadowView!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    
    @IBOutlet weak var deleteContainerView: UIView!
    @IBOutlet weak var deleteView: UIView!
    @IBOutlet weak var deleteHeaderView: ShadowView!
    @IBOutlet weak var deleteGradientView: ShadowView!
    
    @IBOutlet weak var bottomShadowViewToBottom: NSLayoutConstraint!
    @IBOutlet weak var nextButtonToBottom: NSLayoutConstraint!
    @IBOutlet weak var tableViewToBottom: NSLayoutConstraint!
    
    // MARK: Public Properties
    
    /// Model of the unauthorised user.
    var authorisedUserModel: AuthorisedUserModel!
    
    /// Model of the course.
    var courseModel: CourseModel! {
        didSet {
            print(courseModel)
        }
    }
    
    // MARK: Private Properties
    
    private let infoPlistService = InfoPlistService()
    
    private var verificationService: VerificationService!
    private var coursesService: CoursesService!
    private var createCoursesService: CreateCoursesService!
    private var paymentService: PaymentService!
    
    private var unfinishedCourseModel: UnfinishedCourseModel!
    
    private var steps: [StepInfo] = []
    private var selectedStep: StepInfo?
    private var selectedMediaIndex: Int = 0
    private var deleteViewInDeletableZone = false
    
    private var courseInfoChanged = false
    private var courseIntrosReordered = false
    private var courseIntrosAdded = false
    private var courseIntroToDelete: [String] = []
    private var courseIntroOrder: [[String:Any]] = []
    
    private var bottomShadowViewToBottomValue: CGFloat?
    private var nextButtonToBottomValue: CGFloat?
    private var tableViewToBottomValue: CGFloat?
    
    private var editCourseMethod: String?
    private var reorderCourseIntrosMethod: String?
    private var deleteCourseIntrosMethod: String?
    
    // MARK: Init Methods & Superclass Overriders
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.titleLabel.text = ApplicationMessages.ScreenTitles.editCourseScreen
        
        self.deleteContainerView.alpha = 0.0
        self.deleteHeaderView.setupGradientShadow(fromColor: UIColor(white: 1.0, alpha: 1.0), toColor: UIColor(white: 1.0, alpha: 1.0))
        self.deleteGradientView.setupGradientShadow(fromColor: UIColor(white: 1.0, alpha: 1.0), toColor: UIColor(white: 1.0, alpha: 0.0))
        self.topShadowView.setupGradientShadow(fromColor: UIColor(white: 1.0, alpha: 1.0), toColor: UIColor(white: 1.0, alpha: 0.0))
        self.bottomShadowView.setupGradientShadow(fromColor: UIColor(white: 1.0, alpha: 0.0), toColor: UIColor(white: 1.0, alpha: 1.0))
        self.nextButton.alpha = 0.0
        
        self.createUnfinishedModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        self.turnOffKeyboardManager()
        self.configureWithCourseModel()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.changeTableInsets()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.turnOnKeyboardManager()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func inject(propertiesWithAssembly assembly: ViewControllerAssemblyManager) {
        self.verificationService = assembly.verificationService
        self.coursesService = assembly.coursesService
        self.createCoursesService = assembly.createCoursesService
        self.paymentService = assembly.paymentService
    }
    
    override func configureServices() {
        self.createCoursesService.delegate = self
    }
    
    override func serviceMethodSucceeded(withMethod method: String, resultDictionary: [String : Any]?, resultArray: [[String : Any]]?, resultString: String?) {
        if method == self.editCourseMethod {
            if let courseDictionary = resultDictionary {
                let course = CourseModel(withDictionary: courseDictionary)
                
                self.courseModel.update(withModel: course)
                self.coursesService.updateCourse(withModel: course)
            }
            
            self.courseInfoChanged = false
            self.applyChanges()
        } else if method == self.reorderCourseIntrosMethod {
            if let introsDictionaries = resultArray {
                var intros: [CourseIntroModel] = []
                for introDictionary in introsDictionaries {
                    let intro = CourseIntroModel(withDictionary: introDictionary)
                    intros.append(intro)
                }
                
                self.courseModel.update(withIntros: intros)
                self.coursesService.updateCourseIntros(withModels: intros, forCourseID: self.courseModel.id)
            }
            
            self.courseIntrosReordered = false
            self.applyChanges()
        } else if method == self.deleteCourseIntrosMethod {
            self.courseIntroToDelete.removeFirst()
            self.applyChanges()
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
                self.view.layoutIfNeeded()
            })
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
                self.view.layoutIfNeeded()
            })
        }
    }
    
    // MARK: Private Methods
    
    private func createUnfinishedModel() {
        self.unfinishedCourseModel = UnfinishedCourseModel(withCourseModel: self.courseModel)
    }
    
    private func configureWithCourseModel() {
        if self.steps.count > 0 {
            return
        }
        
        var steps: [StepInfo] = []
        for index in 0..<CreateCourseSteps.count.rawValue {
            if let stepType = CreateCourseSteps(rawValue: index), let step = self.createStep(withType: stepType, unfinishedCourseModel: self.unfinishedCourseModel) {
                steps.append(step)
            }
        }
        
        self.steps = steps
        self.selectedStep = steps.first
        
        self.changeTableInsets()
        self.tableView.reloadData()
    }
    
    private func changeTableInsets() {
        var topInset = ceil(self.view.bounds.height * 0.1624)
        if topInset > 89.0 {
            topInset = 89.0
        }
        
        var bottomInset = ceil(self.view.bounds.height * 0.3485)
        if bottomInset > 191.0 {
            bottomInset = 191.0
        }
        if #available(iOS 11.0, *) {
            bottomInset -= self.view.safeAreaInsets.bottom
        }
        
        if self.tableView.contentInset.top != topInset {
            self.tableView.contentInset = UIEdgeInsetsMake(topInset, 0.0, bottomInset, 0.0)
        }
    }
    
    // MARK: Take Picture Methods
    
    private func takePreviewFromCamera() {
        self.checkCameraPermission { [unowned self] (granted) in
            if granted {
                self.showLoadingView(withMethod: "takePreviewFromCamera")
                self.router.takeCoursePreviewFromCamera(withDelegate: self) {
                    self.hideLoadingView(withMethod: "takePreviewFromCamera")
                }
            } else {
                self.showPermissionAlert(withMicrophonePermission: true, camera: false, photos: true)
            }
        }
    }
    
    private func takePreviewFromCameraRoll(replacingExistOne: Bool) {
        self.checkPhotosPermission { [unowned self] (granted) in
            if granted {
                var maxSelectableCount = (replacingExistOne ? 1 : (3 - (self.unfinishedCourseModel.mediaFilenames?.count ?? 0)))
                if maxSelectableCount <= 0 {
                    maxSelectableCount = 1
                }
                
                self.router.takeCoursePreviewFromCameraRoll(withDidSelect: { [weak self] (assets) in
                    if assets.count == 0 {
                        return
                    }
                    
                    self?.showLoadingView()
                    
                    DispatchQueue.global(qos: .userInitiated).async {
                        var content: [Any] = []
                        
                        let dispatchGroup = DispatchGroup()
                        for asset in assets {
                            dispatchGroup.enter()
                            
                            if asset.isVideo {
                                let folderPath = NSTemporaryDirectory()
                                let filename = UUID().uuidString
                                let filePath = folderPath + "/" + filename + ".mp4"
                                let fileURL = URL(fileURLWithPath: filePath)
                                
                                asset.writeAVToFile(filePath, presetName: AVAssetExportPreset1920x1080, outputFileType: AVFileType.mp4.rawValue, completeBlock: { (success) in
                                    if success {
                                        content.append(fileURL)
                                    }
                                    dispatchGroup.leave()
                                })
                            } else {
                                asset.fetchOriginalImageWithCompleteBlock({ (image, info) in
                                    if let originalImage = image {
                                        let scaledImage = UIImage.image(fromImage: originalImage, scaledToWidth: 1920.0, height: 1920.0)
                                        content.append(scaledImage)
                                    }
                                    dispatchGroup.leave()
                                })
                            }
                        }
                        
                        dispatchGroup.wait()
                        
                        DispatchQueue.main.async {
                            self?.hideLoadingView(withMethod: "takePreviewFromCameraRoll")
                            self?.contentPicked(content, errorMessage: nil)
                        }
                    }
                }, maxSelectableCount: maxSelectableCount, completion: nil)
            } else {
                self.showPermissionAlert(withMicrophonePermission: true, camera: true, photos: false)
            }
        }
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
    
    // MARK: Configure Steps
    
    private func createStep(withType type: CreateCourseSteps, unfinishedCourseModel: UnfinishedCourseModel?) -> StepInfo? {
        switch type {
        case .title:
            return StepInfo(title: "Workshop Headline", placeholder: "Put Here Your Workshop Headline", text: self.unfinishedCourseModel?.title, media: nil, date: nil, segments: nil)
        case .description:
            return StepInfo(title: "Workshop Description", placeholder: "Describe What This Workshop is About", text: self.unfinishedCourseModel?.description, media: nil, date: nil, segments: nil)
        case .media:
            let media = self.courseModel.intros
            return StepInfo(title: "Introduction video or photo", placeholder: "Upload an Introduction Video", text: nil, media: media, date: nil, segments: nil)
        case .price:
            return StepInfo(title: "Workshop Price", placeholder: "Set the Price", text: self.unfinishedCourseModel?.priceTier, media: nil, date: nil, segments: nil)
        default:
            return nil
        }
    }
    
    private func configure(cell: StepInfoTableViewCell, forIndex index: Int) {
        if index >= self.steps.count {
            return
        }
        
        let step = self.steps[index]
        let stepType = CreateCourseSteps(rawValue: index)
        let stepOrder = (index + 1)
        let stepSelected = (step.identificator == self.selectedStep?.identificator)
        
        let previousStep = (index - 1 < 0 ? nil : self.steps[index - 1])
        let previousStepSelected = (previousStep != nil && previousStep!.identificator == self.selectedStep?.identificator)
        
        let nextStep = (index + 1 >= self.steps.count ? nil : self.steps[index + 1])
        let nextStepSelected = (nextStep != nil && nextStep!.identificator == self.selectedStep?.identificator)
        
        cell.configure(withStep: step, stepOrder: stepOrder, stepSelected: stepSelected, previousStep: previousStep, previousStepSelected: previousStepSelected, nextStep: nextStep, nextStepSelected: nextStepSelected, fullSizeHeight: CreateCourseStepsHeight.detailedHeight(forStepType: stepType))
        cell.delegate = self
        cell.moveDelegate = self
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
            self.tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .top, animated: true)
        }
    }
    
    private func stepContentOffset(forIndex index: Int) -> CGPoint {
        var totalHeight: CGFloat = 0.0
        var heightBeforeStep: CGFloat = 0.0
        for order in 0..<self.steps.count {
            let height = self.stepHeight(atIndex: order)
            if order < index {
                heightBeforeStep += height
            }
            totalHeight += height
        }
        
        var offset = CGPoint(x: 0.0, y: heightBeforeStep - self.tableView.contentInset.top)
        if offset.y > 0.0 - (self.tableView.bounds.height - totalHeight - self.tableView.contentInset.bottom) {
            offset.y = 0.0 - (self.tableView.bounds.height - totalHeight - self.tableView.contentInset.bottom)
        }
        
        return offset
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
        let stepType = CreateCourseSteps(rawValue: index)
        
        if index < self.steps.count {
            let step = self.steps[index]
            let stepSelected = (step.identificator == self.selectedStep?.identificator)
            let nextStep = (index + 1 >= self.steps.count ? nil : self.steps[index + 1])
            let nextStepSelected = (nextStep != nil && nextStep!.identificator == self.selectedStep?.identificator)
            
            if stepType == .media {
                if stepSelected || step.media!.count > 0 {
                    return CreateCourseStepsHeight.detailedHeight(forStepType: stepType)
                } else if nextStepSelected {
                    let nextStepType = CreateCourseSteps(rawValue: index + 1)
                    return CreateCourseStepsHeight.detailedHeight(forStepType: nextStepType)
                }
            }
            
            if stepType == CreateCourseSteps.price {
                if stepSelected || nextStepSelected {
                    return CreateCourseStepsHeight.detailedHeight(forStepType: stepType)
                } else {
                    return CreateCourseStepsHeight.normalHeight(forStepType: stepType)
                }
            }
            
            if stepSelected || nextStepSelected {
                return CreateCourseStepsHeight.detailedHeight(forStepType: stepType)
            }
        }
        
        return CreateCourseStepsHeight.normalHeight(forStepType: stepType)
    }
    
    // MARK: Support Methods
    
    private func checkShouldChangeModel() {
        let courseTitle = (self.steps[CreateCourseSteps.title.rawValue].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let courseDescription = (self.steps[CreateCourseSteps.description.rawValue].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        var coursePriceTier: String?
        if let coursePriceTierString = self.steps[CreateCourseSteps.price.rawValue].text?.trimmingCharacters(in: .whitespacesAndNewlines), coursePriceTierString.count != 0 {
            coursePriceTier = coursePriceTierString
        }
        
        if self.unfinishedCourseModel.title != courseTitle || self.unfinishedCourseModel.description != courseDescription || coursePriceTier != unfinishedCourseModel.priceTier {
            self.unfinishedCourseModel.update(withTitle: courseTitle, description: courseDescription)
            self.unfinishedCourseModel.update(withPriceTier: coursePriceTier)
        }
    }
    
    private func checkCourseChanged() -> Bool {
        let mediaFilenames = self.unfinishedCourseModel.mediaFilenames ?? []
        
        self.courseInfoChanged = (self.courseModel.title != self.unfinishedCourseModel.title) || (self.courseModel.specification != self.unfinishedCourseModel.description) || (self.courseModel.priceTier != self.unfinishedCourseModel.priceTier)
        self.courseIntrosAdded = false
        self.courseIntrosReordered = false
        self.courseIntroToDelete = []
        self.courseIntroOrder = []
        
        for index in 0..<mediaFilenames.count {
            let filename = mediaFilenames[index]
            
            var filenameFounded = false
            for intro in self.courseModel.intros {
                if intro.id == filename {
                    filenameFounded = true
                    let order: [String:Any] = ["id" : intro.id,
                                               "order" : index + 1]
                    self.courseIntroOrder.append(order)
                    break
                }
            }
            
            if !filenameFounded {
                self.courseIntrosAdded = true
            }
        }
        
        
        for index in 0..<self.courseModel.intros.count {
            let intro = self.courseModel.intros[index]
            
            var introDeleted = true
            for filenameIndex in 0..<mediaFilenames.count {
                let filename = mediaFilenames[filenameIndex]
                if intro.id == filename {
                    introDeleted = false
                    break
                }
            }
            
            if introDeleted {
                self.courseIntroToDelete.append(intro.id)
            }
            
            if mediaFilenames.count > index {
                let filename = mediaFilenames[index]
                if intro.id != filename {
                    self.courseIntrosReordered = true
                }
            } else {
                self.courseIntrosReordered = true
            }
        }
        
        return (self.courseInfoChanged || self.courseIntrosReordered || self.courseIntrosAdded || self.courseIntroToDelete.count > 0)
    }
    
    private func applyChanges() {
        if let introID = self.courseIntroToDelete.first {
            self.deleteCourseIntrosMethod = self.createCoursesService.deleteCourseIntro(withIntroID: introID, user: self.authorisedUserModel)
            return
        }
        
        if self.courseIntrosReordered {
            self.reorderCourseIntrosMethod = self.createCoursesService.editCourseIntrosOrder(withCourseID: self.courseModel.id, order: self.courseIntroOrder, user: self.authorisedUserModel)
            return
        }
        
        if self.courseInfoChanged  {
            self.editCourseMethod = self.createCoursesService.editCourse(withUnfinishedCourse: self.unfinishedCourseModel, forCourseID: self.courseModel.id, user: self.authorisedUserModel)
            return
        }
        
        if self.courseIntrosAdded, let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
            self.router.showUploadCourseIntroScreen(withAuthorisedUserModel: self.authorisedUserModel, courseModel: self.courseModel, introFilePath: documentsPath, courseCreation: false, unfinishedCourseModel: self.unfinishedCourseModel)
            return
        }
        
        self.router.routerShouldRelease()
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    private func shouldChangeCourse(withContent content: [Any]) {
        var step = self.steps[CreateCourseSteps.media.rawValue]
        var media: [Any] = step.media!
        if media.count > self.selectedMediaIndex {
            let image = content.first as? UIImage
            let videoURL = content.first as? URL
            
            if image != nil || videoURL != nil {
                media[self.selectedMediaIndex] = (image != nil ? image! : videoURL!)
            } else {
                media.remove(at: self.selectedMediaIndex)
            }
        } else {
            var mediaIndex = self.selectedMediaIndex
            for object in content {
                let image = object as? UIImage
                let videoURL = object as? URL
                
                if image != nil || videoURL != nil {
                    media.insert((image != nil ? image! : videoURL!), at: mediaIndex)
                    mediaIndex += 1
                }
            }
        }
        step.changeMedia(media: media)
        self.steps[CreateCourseSteps.media.rawValue] = step
        
        if let cell = self.tableView.cellForRow(at: IndexPath(row: CreateCourseSteps.media.rawValue, section: 0)) as? StepInfoTableViewCell {
            self.configure(cell: cell, forIndex: CreateCourseSteps.media.rawValue)
        }
        
        self.courseDidChangeWithImage(withContent: content, forCourseModel: self.unfinishedCourseModel, mediaIndex: self.selectedMediaIndex)
    }
    
    private func courseDidChangeWithImage(withContent content: [Any], forCourseModel model: UnfinishedCourseModel, mediaIndex: Int) {
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
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.hideLoadingView(withMethod: "didChangeCourseMedia")
            }
        }
    }
    
    private func contentPicked(_ content: [Any], errorMessage: String?) {
        if content.count > 0 {
            self.shouldChangeCourse(withContent: content)
        } else {
            if let message = errorMessage {
                self.showAlert(withErrorsMessages: [message])
            } else {
                self.showAlert(withTitle: ApplicationMessages.AlertTitles.message, message: ApplicationMessages.ErrorMessages.exportFailed)
            }
        }
    }
    
    private func showChangeImageMenu(step: StepInfo, mediaIndex: Int) {
        self.selectedMediaIndex = mediaIndex
        
        let actionSheetMenu = UIAlertController(title: ApplicationMessages.AlertTitles.chooseAction, message: nil, preferredStyle: .actionSheet)
        
        actionSheetMenu.addAction(UIAlertAction(title: ApplicationMessages.AlertButtonsTitles.close, style: .cancel, handler: nil))
        actionSheetMenu.addAction(UIAlertAction(title: ApplicationMessages.AlertButtonsTitles.camera, style: .default, handler: { [weak self] (action) in
            self?.takePreviewFromCamera()
        }))
        
        let replacingExistOne = ((unfinishedCourseModel.mediaFilenames?.count ?? 0) > mediaIndex)
        actionSheetMenu.addAction(UIAlertAction(title: ApplicationMessages.AlertButtonsTitles.cameraRoll, style: .default, handler: { [weak self] (action) in
            self?.takePreviewFromCameraRoll(replacingExistOne: replacingExistOne)
        }))
        
        self.present(actionSheetMenu, animated: true, completion: nil)
    }
    
    private func checkRectInDeletableZone(_ rect: CGRect) -> Bool {
        return self.deleteView.frame.contains(rect)
    }
    
    private func checkVideo(withPickerInfo info: [String : Any]) -> String? {
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
    
    private func checkFieldsInfo() {
        let courseTitle = self.verificationService.check(string: self.unfinishedCourseModel!.title)
        let courseDescription = self.verificationService.check(string: self.unfinishedCourseModel!.description)
        let coursePriceTierString = self.verificationService.check(string: self.unfinishedCourseModel!.priceTier)
        
        if courseTitle != nil && courseDescription != nil && coursePriceTierString != nil {
            let courseChanged = self.checkCourseChanged()
            if courseChanged {
                self.applyChanges()
            } else {
                self.router.routerShouldRelease()
                self.presentingViewController?.dismiss(animated: true, completion: nil)
            }
        } else {
            self.showError(withCourseTitle: courseTitle, courseDescription: courseDescription, coursePriceString: coursePriceTierString)
        }
    }
    
    private func showError(withCourseTitle courseTitle: String?, courseDescription: String?, coursePriceString: String?) {
        var messages: [String] = []
        
        if courseTitle == nil || courseTitle?.count == 0 {
            messages.append(ApplicationMessages.ErrorMessages.wrongCourseTitle)
        }
        
        if courseDescription == nil || courseDescription?.count == 0 {
            messages.append(ApplicationMessages.ErrorMessages.wrongCourseDescription)
        }
        
        if coursePriceString == nil || coursePriceString?.count == 0 {
            messages.append(ApplicationMessages.ErrorMessages.wrongCoursePrice(withMinCount: self.verificationService.courseMinimumPrice()))
        }
        
        if messages.count > 0 {
            self.showAlert(withErrorsMessages: messages)
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
    
    // MARK: Controls Actions
    
    override func closeButtonAction(_ sender: UIButton) {
        self.router.routerShouldRelease()
        
        super.closeButtonAction(sender)
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
    
    @IBAction func saveButtonAction(_ sender: UIButton) {
        self.view.endEditing(true)
        
        self.checkFieldsInfo()
    }
    
    // MARK: Protocols Implementation
    
    // MARK: StepDragCellDelegate
    
    internal func cell(_ cell: StepInfoTableViewCell, changeOrderFrom from: Int, to: Int) {
        var step = self.steps[CreateCourseSteps.media.rawValue]
        var media: [Any] = step.media!
        if media.count > to {
            let fromObject = media[from]
            let toObject = media[to]
            
            media[from] = toObject
            media[to] = fromObject
        }
        step.changeMedia(media: media)
        self.steps[CreateCourseSteps.media.rawValue] = step
        
        self.unfinishedCourseModel.update(mediaFilenamesOrderFrom: from, to: to)
    }
    
    internal func cell(_ cell: StepInfoTableViewCell, beginMoveOfView view: UIView, withPoint point: CGPoint, mediaIndex: Int) {
        self.selectedMediaIndex = mediaIndex
        
        let convertedPoint = cell.contentContainer.convert(point, to: self.view)
        view.center = convertedPoint
        self.view.addSubview(view)
        
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .beginFromCurrentState, animations: {
            self.deleteContainerView.alpha = 1.0
        }, completion: nil)
    }
    
    internal func cell(_ cell: StepInfoTableViewCell, moveView view: UIView, withTransform transform: CGAffineTransform) {
        view.transform = transform
        
        let position = view.center.applying(view.transform)
        let frame = CGRect(x: position.x - view.frame.width / 2.0, y: position.y - view.frame.height / 2.0, width: view.frame.width, height: view.frame.height)
        
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
    
    internal func cell(_ cell: StepInfoTableViewCell, endMoveOfView view: UIView) {
        self.deleteViewInDeletableZone = false
        
        let position = view.center.applying(view.transform)
        let frame = CGRect(x: position.x - view.frame.width / 2.0, y: position.y - view.frame.height / 2.0, width: view.frame.width, height: view.frame.height)
        let shouldDelete = self.checkRectInDeletableZone(frame)
        if shouldDelete {
            self.shouldChangeCourse(withContent: [])
        }
        
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .beginFromCurrentState, animations: {
            self.deleteContainerView.alpha = 0.0
            self.deleteHeaderView.animateGradientShadow(fromColor: UIColor(white: 1.0, alpha: 1.0), toColor: UIColor(white: 1.0, alpha: 1.0))
            self.deleteGradientView.animateGradientShadow(fromColor: UIColor(white: 1.0, alpha: 1.0), toColor: UIColor(white: 1.0, alpha: 0.0))
        }, completion: nil)
    }
    
    internal func cell(_ cell: StepInfoTableViewCell, cancelMoveOfView view: UIView) {
        self.deleteContainerView.alpha = 0.0
        self.deleteHeaderView.animateGradientShadow(fromColor: UIColor(white: 1.0, alpha: 1.0), toColor: UIColor(white: 1.0, alpha: 1.0))
        self.deleteGradientView.animateGradientShadow(fromColor: UIColor(white: 1.0, alpha: 1.0), toColor: UIColor(white: 1.0, alpha: 0.0))
    }
    
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
            self.checkShouldChangeModel()
        }
    }
    
    internal func cell(_ cell: StepInfoTableViewCell, shouldChangeMediaForStep step: StepInfo, order: Int, mediaIndex: Int) {
        self.showChangeImageMenu(step: step, mediaIndex: mediaIndex)
    }
    
    // MARK: UIImagePickerControllerDelegate
    
    internal func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        DispatchQueue.main.async {
            picker.dismiss(animated: true, completion: nil)
        }
    }
    
    internal func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String:Any]) {
        var content: [Any] = []
        var errorMessage: String?
        
        if let mediaType = info[UIImagePickerControllerMediaType] as? String {
            let imageMediaType = kUTTypeImage as String
            if mediaType == imageMediaType {
                if let originalImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
                    let scaledImage = UIImage.image(fromImage: originalImage, scaledToWidth: 1920.0, height: 1920.0)
                    content.append(scaledImage)
                }
            }
        }
        
        if let mediaType = info[UIImagePickerControllerMediaType] as? String {
            let videoMediaType = kUTTypeMovie as String
            if mediaType == videoMediaType {
                if let error = self.checkVideo(withPickerInfo: info) {
                    errorMessage = error
                } else if let videoURL = info[UIImagePickerControllerMediaURL] as? URL {
                    content.append(videoURL)
                }
            }
        }
        
        picker.dismiss(animated: true) {
            self.contentPicked(content, errorMessage: errorMessage)
        }
    }
    
    // MARK: UITableViewDelegate & UITableViewDataSource
    
    internal func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    internal func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return CreateCourseSteps.count.rawValue
    }
    
    internal func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let stepType = CreateCourseSteps(rawValue: indexPath.row)
        if stepType == .media {
            let cell = tableView.dequeueReusableCell(withIdentifier: "StepImagesInfoTableViewCell") as! StepImagesInfoTableViewCell
            return cell
        } else if stepType == .price {
            let cell = tableView.dequeueReusableCell(withIdentifier: "StepMoneyTableViewCell") as! StepMoneyTableViewCell
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
    
    internal func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
}
