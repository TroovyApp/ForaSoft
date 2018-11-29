//
//  RegistrationViewController.swift
//  troovy-ios
//
//  Created by Daniil on 22.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit
import MobileCoreServices

class RegistrationViewController: TroovyViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var profilePictureButton: UIButton!
    @IBOutlet weak var usernameTextField: UITextField!
    
    // MARK: Public Properties
    
    /// Model of the unauthorised user.
    var unauthorisedUserModel: UnauthorisedUserModel!
    
    // MARK: Private Properties
    
    private var verificationService: VerificationService!
    private var unauthorisedUserService: UnauthorisedUserService!
    private var authorisedUserService: AuthorisedUserService!
    
    private var profileImageLoaded = false
    
    private var registerUserMethod: String?
    
    // MARK: Init Methods & Superclass Overriders

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.titleLabel.text = ApplicationMessages.ScreenTitles.registrationScreen
        self.profilePictureButton.imageView?.contentMode = .scaleAspectFill
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func inject(propertiesWithAssembly assembly: ViewControllerAssemblyManager) {
        self.verificationService = assembly.verificationService
        self.unauthorisedUserService = assembly.unauthorisedUserService
        self.authorisedUserService = assembly.authorisedUserService
    }
    
    override func configureServices() {
        self.unauthorisedUserService.delegate = self
    }
    
    override func serviceMethodSucceeded(withMethod method: String, resultDictionary: [String : Any]?, resultArray: [[String:Any]]?, resultString: String?) {
        if method == self.registerUserMethod {
            let authorisedUserModel = AuthorisedUserModel(withDictionary: resultDictionary!)
            self.authorisedUserService.rememberUser(withUserModel: authorisedUserModel)
            self.router.showAuthorisedViewController(withAuthorisedUserModel: authorisedUserModel)
        }
    }
    
    // MARK: Private Methods
    
    // MARK: Verification Methods
    
    private func checkFieldsInfo() {
        let username = self.verificationService.check(username: self.usernameTextField.text)
        let usernameLength = self.verificationService.check(usernameLength: self.usernameTextField.text)
        let profilePicture = (self.profileImageLoaded ? self.profilePictureButton.imageView?.image : nil)
        
        if username != nil {
            self.unauthorisedUserModel.update(withUsername: username!, profilePicture: profilePicture)
            self.registerUserMethod = self.unauthorisedUserService.registerUser(withUnauthorisedUser: self.unauthorisedUserModel)
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
    
    private func setProfilePicture(withImage image: UIImage?) {
        if let profilePicture = image {
            self.profileImageLoaded = true
            
            self.profilePictureButton.setImage(profilePicture, for: .normal)
        } else {
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
    
    @IBAction func nextButtonAction(_ sender: UIButton) {
        self.view.endEditing(true)
        
        self.checkFieldsInfo()
    }
    
    // MARK: Protocols Implementation
    
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
