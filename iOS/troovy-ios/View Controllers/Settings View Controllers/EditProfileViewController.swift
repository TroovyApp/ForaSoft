//
//  EditProfileViewController.swift
//  troovy-ios
//
//  Created by Daniil on 17.11.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit
import MobileCoreServices

import Kingfisher

class EditProfileViewController: TroovyViewController, AuthorisedUserModelDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate , UITextFieldDelegate {
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var profilePictureButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var emailTextField: RoundedTextField!
    
    // MARK: Public Properties
    
    /// Model of the unauthorised user.
    var authorisedUserModel: AuthorisedUserModel! {
        willSet {
            self.authorisedUserModel?.removeDelegate(self)
        }
        didSet {
            self.authorisedUserModel?.delegate = self
        }
    }
    
    // MARK: Private Properties
    
    private let infoPlistService = InfoPlistService()
    private var verificationService: VerificationService!
    private var authorisedUserService: AuthorisedUserService!
    
    private var profileImageDeleted = false
    private var profileImageChanged = false
    private var profileImageLoaded = false
    
    private var changeUserMethod: String?
    
    // MARK: Init Methods & Superclass Overriders
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.titleLabel.text = ApplicationMessages.ScreenTitles.editProfileScreen
        self.profilePictureButton.imageView?.contentMode = .scaleAspectFill
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.configureUserProfile()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func inject(propertiesWithAssembly assembly: ViewControllerAssemblyManager) {
        self.verificationService = assembly.verificationService
        self.authorisedUserService = assembly.authorisedUserService
    }
    
    override func configureServices() {
        self.authorisedUserService.delegate = self
    }
    
    override func serviceMethodSucceeded(withMethod method: String, resultDictionary: [String : Any]?, resultArray: [[String:Any]]?, resultString: String?) {
        if method == self.changeUserMethod {
            if let userDictionary = resultDictionary {
                self.authorisedUserModel.update(withDictionary: userDictionary)
                self.authorisedUserService.rememberUser(withUserModel: self.authorisedUserModel)
                
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    // MARK: Private Methods
    
    private func configureUserProfile() {
        self.loadProfileImage()
        
        self.usernameTextField.text = self.authorisedUserModel.username
        self.emailTextField.text = self.authorisedUserModel.email
        
        self.checkFieldsFilled()
    }
    
    private func loadProfileImage() {
        let serverAddress = self.infoPlistService.serverURL()
        if let profileImageURL = self.authorisedUserModel.profilePictureURL, let imageURL = URL.address(byAppendingServerAddress: serverAddress, toContentPath: profileImageURL) {
            self.profileImageLoaded = true
            self.startImageLoading(withURL: imageURL)
        } else {
            self.profileImageLoaded = false
            self.stopImageLoading()
            
            let profilePicture = UIImage.tv_cameraPlaceholder()
            self.profilePictureButton.setImage(profilePicture, for: .normal)
        }
    }
    
    private func startImageLoading(withURL url: URL) {
        let imageResource = ImageResource(downloadURL: url)
        
        if !self.activityIndicator.isAnimating {
            self.activityIndicator.startAnimating()
        }
        
        self.profilePictureButton.backgroundColor = .black
        self.profilePictureButton.kf.setImage(with: imageResource, for: .normal, placeholder: nil, options: nil, progressBlock: nil) { [weak self] (loadedImage, error, cacheType, url) in
            self?.stopImageLoading()
        }
    }
    
    private func stopImageLoading() {
        if self.activityIndicator.isAnimating {
            self.activityIndicator.stopAnimating()
        }
        
        self.profilePictureButton.backgroundColor = UIColor.tv_grayLightColor()
        self.profilePictureButton.kf.cancelImageDownloadTask()
    }
    
    // MARK: Verification Methods
    
    private func checkFieldsFilled() {
        let username = self.verificationService.check(string: self.usernameTextField.text)
        
        if username != nil {
            self.saveButton.enableButton()
        } else {
            self.saveButton.disableButton()
        }
    }
    
    
    private func checkFieldsInfo() {
        let username = self.verificationService.check(username: self.usernameTextField.text)
        let usernameLength = self.verificationService.check(usernameLength: self.usernameTextField.text)
        let changedUsername = ((username != self.authorisedUserModel.username) ? username : nil)
        let profilePicture = (self.profileImageChanged && !self.profileImageDeleted ? self.profilePictureButton.imageView?.image : nil)
        
        var email = self.emailTextField.text
        if email != "" {
            email = self.verificationService.check(email: self.emailTextField.text)
            
            if email == nil {
                self.showAlert(withTitle: ApplicationMessages.AlertTitles.error, message: ApplicationMessages.ErrorMessages.wrongEmail)
                return
            }
        }
        let changedEmail = ((email != self.authorisedUserModel.email) ? email : nil)
        
        if username != nil {
            if self.profileImageChanged || self.profileImageDeleted || changedUsername != nil || changedEmail != nil {
                self.changeUserMethod = self.authorisedUserService.editUser(withModel: self.authorisedUserModel, username: changedUsername, email: changedEmail, profilePicture: profilePicture, shouldDeletePicture: self.profileImageDeleted)
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        } else {
            self.showError(withUsername: username, usernameLength: usernameLength)
        }
    }
    
    private func showError(withUsername username: String?, usernameLength: String?) {
        var messages: [String] = []
        
        if username == nil || username?.count == 0 {
            messages.append(ApplicationMessages.ErrorMessages.wrongUsername)
        } else if usernameLength == nil || usernameLength?.count == 0 {
            messages.append(ApplicationMessages.ErrorMessages.wrongUsernameLength(withMinLength: self.verificationService.usernameMinimumLength(), maxLength: self.verificationService.usernameMaximumLength()))
        }
        
        if messages.count > 0 {
            self.showAlert(withErrorsMessages: messages)
        }
    }
    
    // MARK: Take Picture Methods
    
    private func takePhotoFromCamera() {
        self.checkCameraPermission { [unowned self] (granted) in
            if granted {
                self.showLoadingView(withMethod: "takePhotoFromCamera")
                self.router.takeProfilePictureFromCamera(withDelegate: self) {
                    self.hideLoadingView(withMethod: "takePhotoFromCamera")
                }
            } else {
                self.showPermissionAlert(withMicrophonePermission: true, camera: false, photos: true)
            }
        }
    }
    
    private func takePhotoFromCameraRoll() {
        self.checkPhotosPermission { [unowned self] (granted) in
            if granted {
                self.showLoadingView(withMethod: "takePhotoFromCameraRoll")
                self.router.takeProfilePictureFromCameraRoll(withDelegate: self) {
                    self.hideLoadingView(withMethod: "takePhotoFromCameraRoll")
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
    
    private func setProfilePicture(withImage image: UIImage?) {
        self.stopImageLoading()
        
        if let profilePicture = image {
            self.profileImageChanged = true
            self.profileImageDeleted = false
            self.profileImageLoaded = true
            
            self.profilePictureButton.setImage(profilePicture, for: .normal)
        } else {
            self.profileImageChanged = false
            self.profileImageDeleted = true
            self.profileImageLoaded = false
            
            let profilePicture = UIImage.tv_cameraPlaceholder()
            self.profilePictureButton.setImage(profilePicture, for: .normal)
        }
    }
    
    private func imagePicked(_ image: UIImage?) {
        if image != nil {
            self.setProfilePicture(withImage: image)
        } else {
            self.showAlert(withTitle: ApplicationMessages.AlertTitles.message, message: ApplicationMessages.ErrorMessages.exportFailed)
        }
    }
    
    // MARK: Controls Actions
    
    @IBAction func profilePictureButtonAction(_ sender: UIButton) {
        self.view.endEditing(true)
        
        let actionSheetMenu = UIAlertController(title: ApplicationMessages.AlertTitles.chooseAction, message: nil, preferredStyle: .actionSheet)
        actionSheetMenu.addAction(UIAlertAction(title: ApplicationMessages.AlertButtonsTitles.close, style: .cancel, handler: nil))
        actionSheetMenu.addAction(UIAlertAction(title: ApplicationMessages.AlertButtonsTitles.camera, style: .default, handler: { [weak self] (action) in
            self?.takePhotoFromCamera()
        }))
        actionSheetMenu.addAction(UIAlertAction(title: ApplicationMessages.AlertButtonsTitles.cameraRoll, style: .default, handler: { [weak self] (action) in
            self?.takePhotoFromCameraRoll()
        }))
        
        if self.profileImageLoaded {
            actionSheetMenu.addAction(UIAlertAction(title: ApplicationMessages.AlertButtonsTitles.delete, style: .default, handler: { [weak self] (action) in
                self?.setProfilePicture(withImage: nil)
            }))
        }
        
        self.present(actionSheetMenu, animated: true, completion: nil)
    }
    
    @IBAction func saveButtonAction(_ sender: UIButton) {
        self.view.endEditing(true)
        
        self.checkFieldsInfo()
    }
    
    // MARK: Protocols Implementation
    
    // MARK: UITextFieldDelegate
    
    @objc internal func textFieldDidEndEditing(_ textField: UITextField) {
        self.checkFieldsFilled()
    }
    
    // MARK: AuthorisedUserModelDelegate
    
    internal func authorisedUserChagned(user: AuthorisedUserModel) {
        if self.authorisedUserModel.id == user.id {
            self.configureUserProfile()
        }
    }
    
    // MARK: UIImagePickerControllerDelegate
    
    internal func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        DispatchQueue.main.async {
            picker.dismiss(animated: true, completion: nil)
        }
    }
    
    internal func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String:Any]) {
        var profilePicture: UIImage? = nil
        if let mediaType = info[UIImagePickerControllerMediaType] as? String {
            let imageMediaType = kUTTypeImage as String
            if mediaType == imageMediaType {
                if let editedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
                    profilePicture = UIImage.roundedImage(fromImage: editedImage, scaledToWidth: 450.0, height: 450.0)
                }
            }
        }
        
        picker.dismiss(animated: true) {
            self.imagePicked(profilePicture)
        }
    }
    
    // MARK: UITextFieldDelegate
    
    @objc internal func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.usernameTextField {
            self.usernameTextField.resignFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        
        return true
    }
    
}
