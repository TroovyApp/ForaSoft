//
//  CourseAttachmentsViewController.swift
//  troovy-ios
//
//  Created by Daniil on 22.09.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit
import MobileCoreServices

class CourseAttachmentsViewController: TroovyViewController, CourseModelDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var topSeparatorView: UIView?
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: Public Properties
    
    /// Model of the unauthorised user.
    var authorisedUserModel: AuthorisedUserModel?
    
    /// Model of the course.
    var courseModel: CourseModel! {
        willSet {
            self.courseModel?.removeDelegate(self)
        }
        didSet {
            self.courseModel?.delegate = self
        }
    }
    
    // MARK: Private Properties
    
    private let infoPlistService = InfoPlistService()
    
    private var verificationService: VerificationService!
    private var coursesService: CoursesService!
    private var createCoursesService: CreateCoursesService!
    
    private var modelChanged = false
    private var firstLaunch = true
    private var loadingWithPullToRefresh = false
    private var loadingCourseAttachments = false
    private var refreshControl: UIRefreshControl?
    
    private var uploadFileURL: URL?
    private var attachments: [CourseAttachmentModel] = []
    
    private var loadCourseAttachmentsMethod: String?
    private var createCourseAttachmentMethod: String?
    
    // MARK: Init Methods & Superclass Overriders
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.titleLabel.text = ApplicationMessages.ScreenTitles.attachmentsScreen
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.firstLaunch {
            self.firstLaunch = false
            self.checkCourseAttachmentsLoaded()
        } else if self.modelChanged {
            self.modelChanged = false
            self.apply(courseAttachments: self.courseModel.attachments)
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
    
    override func inject(propertiesWithAssembly assembly: ViewControllerAssemblyManager) {
        self.verificationService = assembly.verificationService
        self.coursesService = assembly.coursesService
        self.createCoursesService = assembly.createCoursesService
    }
    
    override func configureServices() {
        self.coursesService.delegate = self
        self.createCoursesService.delegate = self
    }
    
    override func serviceMethodSucceeded(withMethod method: String, resultDictionary: [String : Any]?, resultArray: [[String : Any]]?, resultString: String?) {
        if method == self.loadCourseAttachmentsMethod {
            if let attachmentsInfo = resultArray {
                var attachments: [CourseAttachmentModel] = []
                for info in attachmentsInfo {
                    let attachment = CourseAttachmentModel(withDictionary: info)
                    attachments.append(attachment)
                }

                self.courseModel.update(withAttachments: attachments)
                self.coursesService.updateCourseAttachments(withModels: attachments, forCourseID: self.courseModel.id)
            }
            
            self.loadingWithPullToRefresh = false
            self.loadingCourseAttachments = false
            self.refreshControl?.setRefreshing(false)
            self.apply(courseAttachments: self.courseModel.attachments)
        } else if method == self.createCourseAttachmentMethod {
            var createdAttachment: CourseAttachmentModel?
            if let attachmentDictionary = resultDictionary {
                createdAttachment = CourseAttachmentModel(withDictionary: attachmentDictionary)
            }
            
            if let uploadURL = self.uploadFileURL, let attachment = createdAttachment {
                attachment.update(withFilePath: uploadURL.path)
                self.uploadAttachment(attachment)
            }
        }
    }
    
    override func serviceMethodFailed(withMethod method: String) {
        if method == self.loadCourseAttachmentsMethod {
            self.loadingWithPullToRefresh = false
            self.loadingCourseAttachments = false
            self.refreshControl?.setRefreshing(false)
            self.apply(courseAttachments: nil)
        } else if method == self.createCourseAttachmentMethod {
            super.serviceMethodFailed(withMethod: method)
        }
    }
    
    override func showLoadingView(withMethod method: String) {
        if method == self.loadCourseAttachmentsMethod {
            if !self.loadingWithPullToRefresh {
                if !self.activityIndicator.isAnimating {
                    self.activityIndicator.startAnimating()
                }
                
                self.collectionView.isHidden = true
            } else {
                self.hideLoadingView(withMethod: method)
            }
        } else {
            super.showLoadingView(withMethod: method)
        }
    }
    
    override func hideLoadingView(withMethod method: String) {
        if method == self.loadCourseAttachmentsMethod {
            self.collectionView.isHidden = false
            
            if self.activityIndicator.isAnimating {
                self.activityIndicator.stopAnimating()
            }
        } else {
            super.hideLoadingView(withMethod: method)
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
        
        self.collectionView.insertSubview(refreshControl, at: 0)
        self.collectionView.alwaysBounceVertical = true
        self.refreshControl = refreshControl
    }
    
    private func configureSeparatorsStateForScroll() {
        guard let collectionView = self.collectionView else {
            return
        }
        
        self.topSeparatorView?.isHidden = !(collectionView.contentOffset.y >= 15.0)
    }
    
    private func checkCourseAttachmentsLoaded() {
        self.refreshControl?.setRefreshing(self.loadingCourseAttachments)
        
        if self.courseModel.attachments != nil && self.courseModel.attachments.count > 0 {
            self.apply(courseAttachments: self.courseModel.attachments)
            
            if self.activityIndicator.isAnimating {
                self.activityIndicator.stopAnimating()
            }
        } else {
            self.loadCourseAttachments()
        }
    }
    
    private func apply(courseAttachments: [CourseAttachmentModel]?) {
        var attachmentsChanged = false
        if let attachments = courseAttachments {
            self.attachments = attachments.sorted { (firstAttachment, secondAttachment) -> Bool in
                return firstAttachment.createdTimestamp > secondAttachment.createdTimestamp
            }
            attachmentsChanged = true
        }
        
        self.collectionView.isHidden = false
        
        if attachmentsChanged {
            self.collectionView.reloadData()
        }
        
        self.configureSeparatorsStateForScroll()
    }
    
    private func loadCourseAttachments() {
        if self.loadingCourseAttachments {
            self.loadingWithPullToRefresh = false
            return
        }
        
        self.loadingCourseAttachments = true
        self.loadCourseAttachmentsMethod = self.coursesService.loadCourseAttachments(withCourseID: self.courseModel.id, user: self.authorisedUserModel)
    }
    
    private func takeVideoFromCameraRoll() {
        self.checkPhotosPermission { [unowned self] (granted) in
            if granted {
                self.showLoadingView(withMethod: "takeVideoFromCameraRoll")
                self.router.takeCourseAttachmentFromCameraRoll(withDelegate: self) {
                    self.hideLoadingView(withMethod: "takeVideoFromCameraRoll")
                }
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
    
    private func attachmentSelected(_ attachment: CourseAttachmentModel) {
        if let filePath = attachment.filePath {
            let fileURL = URL.init(fileURLWithPath: filePath)
            self.router.showVideo(withVideoURL: fileURL)
        } else if let fileAddress = attachment.fileAddress {
            let serverAddress = self.infoPlistService.serverURL()
            if let fileURL = URL.address(byAppendingServerAddress: serverAddress, toContentPath: fileAddress) {
                self.router.showVideo(withVideoURL: fileURL)
            }
        }
    }
    
    private func createAttachment(withVideoURL url: URL) {
        guard let userModel = self.authorisedUserModel else {
            return
        }
        
        self.uploadFileURL = url
        self.createCourseAttachmentMethod = self.createCoursesService.createCourseVideoAttachment(withCourseID: self.courseModel.id, user: userModel)
    }
    
    private func uploadAttachment(_ attachment: CourseAttachmentModel) {
        guard let userModel = self.authorisedUserModel else {
            return
        }
        
        self.router.showUploadAttachmentScreen(withAuthorisedUserModel: userModel, courseModel: self.courseModel, attachmentModel: attachment)
    }
    
    private func contentPicked(videoURL: URL?, errorMessage: String?) {
        if let url = videoURL {
            self.createAttachment(withVideoURL: url)
        } else {
            if let message = errorMessage {
                self.showAlert(withErrorsMessages: [message])
            } else {
                self.showAlert(withTitle: ApplicationMessages.AlertTitles.message, message: ApplicationMessages.ErrorMessages.exportFailed)
            }
        }
    }
    
    // MARK: Controls Actions
    
    @objc private func refreshControlTriggered(_ sender: UIRefreshControl) {
        self.refreshControl?.setRefreshing(true)
        self.loadingWithPullToRefresh = true
        self.loadCourseAttachments()
    }
    
    @IBAction func reloadButtonAction(_ sender: UIButton) {
        self.loadCourseAttachments()
    }
    
    // MARK: Protocols Implementation
    
    // MARK: CourseModelDelegate
    
    internal func courseChagned(course: CourseModel) {
        if self.courseModel.id == course.id {
            if self.viewAppeared {
                self.apply(courseAttachments: self.courseModel.attachments)
            } else {
                self.modelChanged = true
            }
        }
    }
    
    // MARK: UIImagePickerControllerDelegate
    
    internal func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        DispatchQueue.main.async {
            picker.dismiss(animated: true, completion: nil)
        }
    }
    
    internal func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String:Any]) {
        var errorMessage: String?
        
        var videoURL: URL?
        if let mediaType = info[UIImagePickerControllerMediaType] as? String {
            let videoMediaType = kUTTypeMovie as String
            if mediaType == videoMediaType {
                if let mediaURL = info[UIImagePickerControllerMediaURL] as? URL {
                    if let url = self.verificationService.check(libraryCourseVideoURL: mediaURL) {
                        videoURL = url
                    } else {
                        errorMessage = ApplicationMessages.ErrorMessages.wrongCourseVideoSize(withMaxSize: self.verificationService.maximumLibraryCourseVideoSize())
                    }
                }
            }
        }
        
        picker.dismiss(animated: true) {
            if videoURL != nil {
                self.contentPicked(videoURL: videoURL, errorMessage: errorMessage)
            } else {
                self.contentPicked(videoURL: nil, errorMessage: errorMessage)
            }
        }
    }
    
    // MARK: UIScrollViewDelegate
    
    internal func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.configureSeparatorsStateForScroll()
    }
    
    // MARK: UICollectionViewDelegate && UICollectionViewDataSource
    
    internal func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CourseAddAttachmentCollectionViewCell", for: indexPath) as! CourseAddAttachmentCollectionViewCell
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CourseAttachmentCollectionViewCell", for: indexPath) as! CourseAttachmentCollectionViewCell
            return cell
        }
    }
    
    internal func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let attachmentCell = cell as? CourseAttachmentCollectionViewCell {
            let index = indexPath.row - 1
            let attachment = self.attachments[index]
            
            attachmentCell.alpha = 1.0
            attachmentCell.contentView.alpha = 1.0
            attachmentCell.configure(withAttachment: attachment, serverAddress: self.infoPlistService.serverURL())
        }
    }
    
    internal func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.attachments.count + 1
    }
    
    internal func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            let actionSheetMenu = UIAlertController(title: ApplicationMessages.AlertTitles.chooseAction, message: nil, preferredStyle: .actionSheet)
            actionSheetMenu.addAction(UIAlertAction(title: ApplicationMessages.AlertButtonsTitles.close, style: .cancel, handler: nil))
            actionSheetMenu.addAction(UIAlertAction(title: ApplicationMessages.AlertButtonsTitles.cameraRoll, style: .default, handler: { [weak self] (action) in
                self?.takeVideoFromCameraRoll()
            }))
            
            self.present(actionSheetMenu, animated: true, completion: nil)
        } else {
            let index = indexPath.row - 1
            let course = self.attachments[index]
            
            self.attachmentSelected(course)
        }
    }
    
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let side = (collectionView.frame.size.width - 22.0) / 3.0
        return CGSize(width: side, height: side)
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
