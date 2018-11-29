//
//  CreateCourseMainInfoViewController.swift
//  troovy-ios
//
//  Created by Daniil on 23.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit
import StoreKit
import AVFoundation
import MobileCoreServices
import NVActivityIndicatorView

protocol CourseDeleteIntroDelegate: class {
    func coursePage(_ page: UIViewController, didBeginMoveDeletableView view: UIView, atPoint: CGPoint)
    func coursePage(_ page: UIViewController, didMoveDeletableViewToFrame frame: CGRect)
    func coursePage(_ page: UIViewController, shouldDeleteViewWithFrame frame: CGRect) -> Bool
    func coursePage(_ page: UIViewController, didEndMoveDeletableViewAnimated animated: Bool)
}

class CreateCourseMainInfoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, StepInfoCellDelegate, StepDragCellDelegate, NVActivityIndicatorViewable {
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var topShadowView: ShadowView!
    @IBOutlet weak var bottomShadowView: ShadowView!
    @IBOutlet weak var nextButton: UIButton!
    
    @IBOutlet weak var bottomShadowViewToBottom: NSLayoutConstraint!
    @IBOutlet weak var nextButtonToBottom: NSLayoutConstraint!
    @IBOutlet weak var tableViewToBottom: NSLayoutConstraint!
    
    // MARK: Private Properties
    
    private weak var delegate: CreateCourseDelegate?
    private weak var deleteDelegate: CourseDeleteIntroDelegate?
    
    private var createCourseHintsViewController: CreateCourseHintsViewController?
    
    private var bottomShadowViewToBottomValue: CGFloat?
    private var nextButtonToBottomValue: CGFloat?
    private var tableViewToBottomValue: CGFloat?
    
    private var viewAppeared = false
    
    private var steps: [StepInfo] = []
    private var selectedStep: StepInfo?
    private var selectedMediaIndex: Int = 0
    
    // MARK: Init Methods & Superclass Overriders
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.topShadowView.setupGradientShadow(fromColor: UIColor(white: 1.0, alpha: 1.0), toColor: UIColor(white: 1.0, alpha: 0.0))
        self.bottomShadowView.setupGradientShadow(fromColor: UIColor(white: 1.0, alpha: 0.0), toColor: UIColor(white: 1.0, alpha: 1.0))
        self.nextButton.alpha = 0.0
        
        self.tableViewToBottomValue = self.tableViewToBottom.constant
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        self.subscribeToProductUpdates()
        self.configure()
        self.viewAppeared = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.viewAppeared = false
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
            self.createCourseHintsViewController = createCourseHintsViewController
            self.createCourseHintsViewController?.hints = ["Write down in a clear and short description of what your workshop is about.",
                                                           "Emphasize at least 3 benefits someone will reap from attending the workshop.",
                                                           "Upload a vertical video (like you would on Instagram). This video should give viewers a good idea of what your workshop is about.",
                                                           "Set the price for your workshop. Earnings are available for withdrawal."]
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
    
    // MARK: Public Methods
    
    /// Configures creation view with course model.
    ///
    /// - parameter delegate: Delegate which responds to CreateCourseDelegate protocol.
    /// - parameter deleteDelegate: Delegate which responds to CourseDeleteIntroDelegate protocol.
    ///
    func configure(withDelegate delegate: CreateCourseDelegate?, deleteDelegate: CourseDeleteIntroDelegate) {
        self.delegate = delegate
        self.deleteDelegate = deleteDelegate
        
        if self.viewAppeared {
            self.configure()
        }
    }
    
    // MARK: Private Methods
    
    private func configure() {
        if self.steps.count > 0 {
            return
        }
        
        let unfinishedCourseModel = self.delegate?.currentCourseModel()
        
        var steps: [StepInfo] = []
        for index in 0..<CreateCourseSteps.count.rawValue {
            if let stepType = CreateCourseSteps(rawValue: index), let step = self.createStep(withType: stepType, unfinishedCourseModel: unfinishedCourseModel) {
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
    
    // MARK: Take Picture Methods
    
    private func takePreviewFromCamera() {
        self.delegate?.coursePageShouldTakeCoursePreviewFromCamera(page: self)
    }
    
    private func takePreviewFromCameraRoll(replacingExistOne: Bool) {
        self.delegate?.coursePageShouldTakeCoursePreviewFromCameraRoll(page: self, replacingExistOne: replacingExistOne, didSelect: { [weak self] (assets) in
            if assets.count == 0 {
                return
            }
            
            self?.delegate?.coursePageShouldShowLoadingView()
            
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
                    self?.delegate?.coursePageShouldHideLoadingView()
                    self?.contentPicked(content, errorMessage: nil)
                }
            }
        })
    }
    
    // MARK: Configure Steps
    
    private func createStep(withType type: CreateCourseSteps, unfinishedCourseModel: UnfinishedCourseModel?) -> StepInfo? {
        switch type {
        case .title:
            return StepInfo(title: "Workshop Headline", placeholder: "Put Here Your Workshop Headline", text: unfinishedCourseModel?.title, media: nil, date: nil, segments: nil)
        case .description:
            return StepInfo(title: "Workshop Description", placeholder: "Describe What This Workshop is About", text: unfinishedCourseModel?.description, media: nil, date: nil, segments: nil)
        case .media:
            let media = self.loadPreviewsFromModel(unfinishedCourseModel)
            return StepInfo(title: "Introduction video or photo", placeholder: "Upload an Introduction Video", text: nil, media: media, date: nil, segments: nil)
        case .price:
            return StepInfo(title: "Workshop Price", placeholder: "Set the Price", text: unfinishedCourseModel?.priceTier, media: nil, date: nil, segments: nil)
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
        let stepType = CreateCourseSteps(rawValue: index)
        
        if index < self.steps.count {
            let step = self.steps[index]
            let stepSelected = (step.identificator == self.selectedStep?.identificator)
            let stepFilled = step.isStepFilled()
            let nextStep = (index + 1 >= self.steps.count ? nil : self.steps[index + 1])
            let nextStepSelected = (nextStep != nil && nextStep!.identificator == self.selectedStep?.identificator)
            
            if stepType == CreateCourseSteps.media {
                if stepSelected || stepFilled {
                    return CreateCourseStepsHeight.detailedHeight(forStepType: stepType)
                } else if nextStepSelected {
                    let previousStepType = CreateCourseSteps(rawValue: index - 1)
                    return CreateCourseStepsHeight.detailedHeight(forStepType: previousStepType)
                }
            }
            
            if stepType == CreateCourseSteps.price {
                if stepSelected || nextStepSelected {
                    return CreateCourseStepsHeight.detailedHeight(forStepType: stepType)
                } else {
                    return CreateCourseStepsHeight.normalHeight(forStepType: stepType)
                }
            }
            
            if stepSelected || stepFilled || nextStepSelected {
                return CreateCourseStepsHeight.detailedHeight(forStepType: stepType)
            }
        }
        
        return CreateCourseStepsHeight.normalHeight(forStepType: stepType)
    }
    
    // MARK: Support Methods
    
    private func subscribeToProductUpdates() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleProductsUpdateNotification(_:)),
                                               name: NSNotification.Name(rawValue: TroovyProducts.TroovyProductsUpdatedNotification),
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleProductsUpdateNotification(_:)),
                                               name: NSNotification.Name(rawValue: TroovyProducts.TroovyProductsFailPurchaseNotification),
                                               object: nil)
    }
    
    private func loadPreviewsFromModel(_ courseModel: UnfinishedCourseModel?) -> [Any] {
        var media: [Any] = []
        if let model = courseModel, let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
            for filename in model.mediaFilenames ?? [] {
                let path = documentsPath + "/" + filename
                if let previewImage = UIImage(contentsOfFile: path) {
                    media.append(previewImage)
                } else {
                    let videoURL = URL(fileURLWithPath: path)
                    if FileManager.default.fileExists(atPath: videoURL.path) {
                        media.append(videoURL)
                    }
                }
            }
        }
        
        return media
    }
    
    private func checkShouldChangeModel() {
        guard var unfinishedCourseModel = self.delegate?.currentCourseModel() else {
            return
        }
        
        let courseTitle = (self.steps[CreateCourseSteps.title.rawValue].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let courseDescription = (self.steps[CreateCourseSteps.description.rawValue].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        var coursePriceTier: String?
        if let coursePriceTierString = self.steps[CreateCourseSteps.price.rawValue].text?.trimmingCharacters(in: .whitespacesAndNewlines), coursePriceTierString.count != 0 {
            coursePriceTier = coursePriceTierString
        }
        
        if unfinishedCourseModel.title != courseTitle || unfinishedCourseModel.description != courseDescription || coursePriceTier != unfinishedCourseModel.priceTier {
            unfinishedCourseModel.update(withTitle: courseTitle, description: courseDescription)
            unfinishedCourseModel.update(withPriceTier: coursePriceTier)
            
            self.delegate?.coursePage(page: self, didChangeCourseModel: unfinishedCourseModel)
        }
    }
    
    private func shouldChangeCourse(withContent content: [Any]) {
        guard let unfinishedCourseModel = self.delegate?.currentCourseModel() else {
            return
        }
        
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
        
        self.delegate?.coursePage(page: self, didChangeCourseWithContent: content, forCourseModel: unfinishedCourseModel, mediaIndex: self.selectedMediaIndex)
    }
    
    private func contentPicked(_ content: [Any], errorMessage: String?) {
        if content.count > 0 {
            self.shouldChangeCourse(withContent: content)
        } else {
            if let message = errorMessage {
                self.delegate?.coursePage(page: self, shouldShowAlertWithMessages: [message])
            } else {
                self.delegate?.coursePage(page: self, shouldShowAlertWithMessage: ApplicationMessages.ErrorMessages.exportFailed)
            }
        }
    }
    
    private func showChangeImageMenu(step: StepInfo, mediaIndex: Int) {
        guard let unfinishedCourseModel = self.delegate?.currentCourseModel() else {
            return
        }
        
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
    
    // MARK: Controls Actions
    
    @IBAction func nextButtonAction(_ sender: UIButton) {
        if let selectedStepIdentificator = self.selectedStep?.identificator, let index = self.steps.index(where: { $0.identificator == selectedStepIdentificator }) {
            let nextIndex = index + 1
            if nextIndex < self.steps.count {
                if let cell = self.tableView.cellForRow(at: IndexPath(row: nextIndex, section: 0)) as? StepInfoTableViewCell {
                    self.select(cell: cell, forIndex: nextIndex)
                }
            } else {
                self.deselect()
                self.delegate?.coursePageWantsNextPage(page: self)
            }
        }
    }
    
    // MARK: Protocols Implementation
    
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
                if let error = self.delegate?.coursePage(page: self, checkVideoWithPickerInfo: info) {
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
    
    // MARK: StepDragCellDelegate
    
    internal func cell(_ cell: StepInfoTableViewCell, changeOrderFrom from: Int, to: Int) {
        guard var unfinishedCourseModel = self.delegate?.currentCourseModel() else {
            return
        }
        
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
        
        unfinishedCourseModel.update(mediaFilenamesOrderFrom: from, to: to)
        self.delegate?.coursePage(page: self, didChangeCourseModel: unfinishedCourseModel)
    }
    
    internal func cell(_ cell: StepInfoTableViewCell, beginMoveOfView view: UIView, withPoint point: CGPoint, mediaIndex: Int) {
        let convertedPoint = cell.contentContainer.convert(point, to: self.view)
        
        self.selectedMediaIndex = mediaIndex
        self.deleteDelegate?.coursePage(self, didBeginMoveDeletableView: view, atPoint: convertedPoint)
    }
    
    internal func cell(_ cell: StepInfoTableViewCell, moveView view: UIView, withTransform transform: CGAffineTransform) {
        view.transform = transform
        
        let position = view.center.applying(view.transform)
        let frame = CGRect(x: position.x - view.frame.width / 2.0, y: position.y - view.frame.height / 2.0, width: view.frame.width, height: view.frame.height)
        
        self.deleteDelegate?.coursePage(self, didMoveDeletableViewToFrame: frame)
    }
    
    internal func cell(_ cell: StepInfoTableViewCell, endMoveOfView view: UIView) {
        let position = view.center.applying(view.transform)
        let frame = CGRect(x: position.x - view.frame.width / 2.0, y: position.y - view.frame.height / 2.0, width: view.frame.width, height: view.frame.height)
        
        let shouldDelete = self.deleteDelegate?.coursePage(self, shouldDeleteViewWithFrame: frame) ?? false
        if shouldDelete {
            self.shouldChangeCourse(withContent: [])
        }
        
        self.deleteDelegate?.coursePage(self, didEndMoveDeletableViewAnimated: true)
    }
    
    internal func cell(_ cell: StepInfoTableViewCell, cancelMoveOfView view: UIView) {
        self.deleteDelegate?.coursePage(self, didEndMoveDeletableViewAnimated: false)
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
        
        let stepType = CreateCourseSteps(rawValue: indexPath.row)
        if stepType == .price {
            startAnimating(message: ApplicationMessages.Instructions.loadingPriceList)
            TroovyProducts.shared.requestProducts()
        }
        
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
        let maximumContentSize: CGFloat = 337.0
        let currentContentSize: CGFloat = self.currentContentSize()
        
        var height: CGFloat = CGFloat.leastNormalMagnitude
        if (maximumContentSize - currentContentSize) > 0.0 {
            height = (maximumContentSize - currentContentSize)
        }
        
        return height
    }
    
    // MARK: NSNotificationCenter
    
    @objc func handleProductsUpdateNotification(_ notification: Notification) {
        stopAnimating()
        
        if notification.name.rawValue == TroovyProducts.TroovyProductsUpdatedNotification, let products = notification.object as? [SKProduct] {
            if products.count == 0 {
                showAlert(withTitle: ApplicationMessages.AlertTitles.error, message: "Unable to load prices")
            }
        }
    }
    
}
