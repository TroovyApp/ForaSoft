//
//  UnauthorisedViewController.swift
//  troovy-ios
//
//  Created by Daniil on 11.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

import PhoneNumberKit

class UnauthorisedViewController: TroovyViewController, CountriesPickerDelegate, UITextFieldDelegate {
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var phoneCodeTextField: UITextField!
    @IBOutlet weak var phoneCodeTextFieldWidth: NSLayoutConstraint!
    @IBOutlet weak var validateButton: UIButton!
    
    // MARK: Public Properties
    
    /// Error message to show on appear.
    var errorMessage: String?
    
    // MARK: Private Properties
    
    private var countryListDataService: CountryListDataService!
    private var verificationService: VerificationService!
    private var unauthorisedUserService: UnauthorisedUserService!
    
    private let phoneNumberFormatter = PartialFormatter()
    private var regionCode: String?
    private var callingCode: String?
    private var countryName: String?
    
    private var phoneCodeTextFieldWidthValue: CGFloat = 0.0
    
    private var unauthorisedUserModel = UnauthorisedUserModel()
    
    private var requestVerificationCodeMethod: String?
    
    // MARK: Init Methods & Superclass Overriders

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupPhoneNumberVariables()
        self.setupPhoneTextFields()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.checkFieldsFilled()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let message = self.errorMessage {
            self.errorMessage = nil
            self.showAlert(withTitle: ApplicationMessages.AlertTitles.message, message: message)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func inject(propertiesWithAssembly assembly: ViewControllerAssemblyManager) {
        self.countryListDataService = assembly.countryListDataService
        self.verificationService = assembly.verificationService
        self.unauthorisedUserService = assembly.unauthorisedUserService
    }
    
    override func configureServices() {
        self.unauthorisedUserService.delegate = self
    }
    
    override func serviceMethodSucceeded(withMethod method: String, resultDictionary: [String : Any]?, resultArray: [[String:Any]]?, resultString: String?) {
        if method == self.requestVerificationCodeMethod {
            self.requestVerificationCodeMethod = nil
            self.router.showUserVerificationViewController(withUnauthorisedUserModel: self.unauthorisedUserModel)
        }
    }
    
    // MARK: Private Methods
    
    // MARK: Setups Methods
    
    private func setupPhoneNumberVariables() {
        if let regionCode = Locale.current.regionCode {
            self.countryName = Locale.init(identifier: "en_US").localizedString(forRegionCode: regionCode)
            self.regionCode = self.countryListDataService.countryRegionCode(forCountryName: self.countryName)
            self.callingCode = self.countryListDataService.countryCode(forCountryName: self.countryName)
        }
    }
    
    private func setupPhoneTextFields() {
        self.phoneCodeTextFieldWidthValue = self.phoneCodeTextFieldWidth.constant
        
        self.phoneNumberTextField.inputAccessoryView = self.accesstoryView()
        self.phoneNumberTextField.text = nil
        
        self.phoneCodeTextField.inputAccessoryView = self.accesstoryView()
        self.phoneCodeTextField.inputView = self.countriesInputView()
        self.phoneCodeTextField.text = (self.callingCode != nil ? self.callingCode! : nil)
        
        self.layoutPhoneCodeTextField()
    }
    
    // MARK: Verification Methods
    
    private func checkFieldsFilled() {
        let phoneCode = self.verificationService.check(string: self.phoneCodeTextField.text)
        let phoneNumber = self.verificationService.check(string: self.phoneNumberTextField.text)
        
        if phoneNumber != nil && phoneCode != nil {
            self.validateButton.enableButton()
        } else {
            self.validateButton.disableButton()
        }
    }
    
    private func checkFieldsInfo() {
        let phoneNumber = self.verificationService.check(phoneNumber:  self.phoneNumberTextField.text)
        
        if phoneNumber != nil && self.callingCode != nil && self.regionCode != nil {
            let formattedPhoneNumber = self.callingCode! + " " + self.phoneNumberTextField.text!
            self.unauthorisedUserModel.update(withCallingCode: self.callingCode!, regionCode: self.regionCode!, phoneNumber: phoneNumber!, formattedPhoneNumber: formattedPhoneNumber)
            
            self.requestVerificationCodeMethod = self.unauthorisedUserService.requestVerificationCode(withUnauthorisedUser: self.unauthorisedUserModel)
        } else {
            self.showError(withPhoneNumber: phoneNumber, callingCode: self.callingCode, regionCode: self.regionCode)
        }
    }
    
    private func showError(withPhoneNumber phoneNumber: String?, callingCode: String?, regionCode: String?) {
        var messages: [String] = []
        
        if phoneNumber == nil || phoneNumber?.count == 0 {
            messages.append(ApplicationMessages.ErrorMessages.wrongPhoneNumber)
        }
        
        if callingCode == nil || callingCode?.count == 0 {
            messages.append(ApplicationMessages.ErrorMessages.wrongCallingCode)
        }
        
        if regionCode == nil || regionCode?.count == 0 {
            messages.append(ApplicationMessages.ErrorMessages.wrongRegionCode)
        }
        
        if messages.count > 0 {
            self.showAlert(withErrorsMessages: messages)
        }
    }
    
    // MARK: Support Methods
    
    private func layoutPhoneCodeTextField() {
        let string = (self.phoneCodeTextField.text ?? "") as NSString
        let stringSize = string.size(withAttributes: [NSAttributedStringKey.font : self.phoneCodeTextField.font!])
        let codeTextFieldWidth: CGFloat = ceil(stringSize.width) + 47.0
        
        if codeTextFieldWidth <= self.phoneCodeTextFieldWidthValue {
            self.phoneCodeTextFieldWidth.constant = self.phoneCodeTextFieldWidthValue
        } else {
            self.phoneCodeTextFieldWidth.constant = codeTextFieldWidth
        }
        
        self.view.setNeedsLayout()
    }
    
    private func countriesInputView() -> UIView {
        let countriesPickerView = CountriesPickerView(frame: CGRect.zero, countryListDataService: self.countryListDataService)
        countriesPickerView.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        countriesPickerView.countriesDelegate = self
        countriesPickerView.select(countryWithCountryName: self.countryName, regionCode: self.regionCode, indexPath: nil)
        countriesPickerView.configure()
        return countriesPickerView
    }
    
    private func accesstoryView() -> UIView {
        let flexButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let doneButton = UIBarButtonItem(title: ApplicationMessages.ButtonsTitles.done, style: .done, target: self, action: #selector(doneButtonAction(_:)))
        let items = [flexButton, doneButton]
        
        let accesstoryView = UIToolbar()
        accesstoryView.barStyle = .default
        accesstoryView.isTranslucent = false
        accesstoryView.setBackgroundImage(UIImage.image(fromColor: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)), forToolbarPosition: .any, barMetrics: .default)
        accesstoryView.setItems(items, animated: false)
        accesstoryView.sizeToFit()
        return accesstoryView
    }
    
    private func applyFormattedPhoneNumber(withString string: String) {
        if let regionCode = self.regionCode {
            if self.phoneNumberFormatter.defaultRegion != regionCode {
                self.phoneNumberFormatter.defaultRegion = regionCode
            }
        }
        
        self.phoneNumberTextField.text = self.phoneNumberFormatter.formatPartial(string)
    }
    
    // MARK: Controls Actions
    
    @objc private func doneButtonAction(_ sender: UIBarButtonItem) {
        self.view.endEditing(true)
    }
    
    @IBAction func validateButtonAction(_ sender: UIButton) {
        self.view.endEditing(true)
        
        self.checkFieldsInfo()
    }
    
    // MARK: Protocols Implementation
    
    // MARK: UITextFieldDelegate
    
    internal func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == self.phoneNumberTextField {
            let phoneNumberCharacterSet = CharacterSet(charactersIn: "0123456789+-() ").inverted
            let phoneString = (self.phoneNumberTextField.text ?? "") as NSString
            let phoneStringAfterReplacement = phoneString.replacingCharacters(in: range, with: string).components(separatedBy: phoneNumberCharacterSet).joined(separator: "")
            
            self.applyFormattedPhoneNumber(withString: phoneStringAfterReplacement)
            
            return false
        }
        
        return true
    }
    
    @objc internal func textFieldDidEndEditing(_ textField: UITextField) {
        self.checkFieldsFilled()
    }
    
    internal func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.phoneCodeTextField {
            self.phoneNumberTextField.becomeFirstResponder()
        } else if textField == self.phoneNumberTextField {
            self.phoneNumberTextField.resignFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        
        return true
    }
    
    // MARK: CountriesPickerDelegate
    
    internal func pickerView(view: CountriesPickerView, didSelectCountry country: CountryModel, atIndexPath indexPath: IndexPath) {
        self.regionCode = country.regionCode
        self.callingCode = country.callingCode
        self.countryName = country.countryName
        
        self.phoneCodeTextField.text = (self.callingCode != nil ? self.callingCode! : nil)
        self.layoutPhoneCodeTextField()
        
        let phoneString = (self.phoneNumberTextField.text ?? "")
        self.applyFormattedPhoneNumber(withString: phoneString)
        
        self.checkFieldsFilled()
    }

}
