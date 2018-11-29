//
//  SettingsHomeViewController.swift
//  troovy-ios
//
//  Created by Daniil on 23.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

import Kingfisher
import PhoneNumberKit

class SettingsHomeViewController: TroovyViewController, AuthorisedUserModelDelegate, SettingsControlsDelegate {
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var titleLabel: UILabel?
    
    @IBOutlet weak var scrollView: UIScrollView?
    @IBOutlet weak var profileImageView: UIImageView?
    @IBOutlet weak var profileUsernameLabel: UILabel?
    @IBOutlet weak var profilePhoneNumberLabel: UILabel?
    @IBOutlet weak var profileBalanceLabel: UILabel?
    @IBOutlet weak var balanceView: UIView?
    @IBOutlet weak var profileEmailLabel: UILabel!
    
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
    private var countryListDataService: CountryListDataService!
    private var authorisedUserService: AuthorisedUserService!
    private var createCoursesService: CreateCoursesService!
    private var coursesService: CoursesService!
    
    private let phoneNumberFormatter = PartialFormatter()
    private var numberFormatter: NumberFormatter!
    
    private var updatingUser = false
    private var updateUserInfoMethod: String?
    
    private var viewDidLoaded = false
    private var viewControllerPushed = false

    // MARK: Init Methods & Superclass Overriders
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = nil
        self.titleLabel?.text = ApplicationMessages.ScreenTitles.settingsHomeScreen
        
        self.viewDidLoaded = true
        
        self.setupNumberFormatter()
        self.configureUserProfile()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !self.viewControllerPushed {
            self.updateUser()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.viewControllerPushed = false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let settingsControlsTableViewController = segue.destination as? SettingsControlsTableViewController {
            settingsControlsTableViewController.delegate = self
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func inject(propertiesWithAssembly assembly: ViewControllerAssemblyManager) {
        self.countryListDataService = assembly.countryListDataService
        self.authorisedUserService = assembly.authorisedUserService
        self.createCoursesService = assembly.createCoursesService
        self.coursesService = assembly.coursesService
    }
    
    override func configureServices() {
        self.authorisedUserService.delegate = self
    }
    
    override func serviceMethodSucceeded(withMethod method: String, resultDictionary: [String : Any]?, resultArray: [[String : Any]]?, resultString: String?) {
        if method == self.updateUserInfoMethod {
            self.updatingUser = false
            
            guard let dictionary = resultDictionary else {
                return
            }
            
            self.authorisedUserModel.update(withDictionary: dictionary)
            self.authorisedUserService.rememberUser(withUserModel: self.authorisedUserModel)
        }
    }
    
    override func serviceMethodFailed(withMethod method: String) {
        if method == self.updateUserInfoMethod {
            self.updatingUser = false
        }
    }
    
    override func showLoadingView(withMethod method: String) {
        if method == self.updateUserInfoMethod {
            return
        }
    }
    
    override func shouldShowAlert(forMethod method: String) -> Bool {
        if method == self.updateUserInfoMethod {
            return false
        }
        
        return super.shouldShowAlert(forMethod: method)
    }
    
    // MARK: Private Properties
    
    private func setupNumberFormatter() {
        self.numberFormatter = NumberFormatter()
        self.numberFormatter.numberStyle = .currency
        if let currency = TroovyProducts.shared.getCurrentCurrency(), let locale = TroovyProducts.shared.getCurrentCurrencyLocale() {
            self.numberFormatter.currencyCode = currency
            self.numberFormatter.locale = locale
        }
        self.numberFormatter.minimumFractionDigits = 2
    }
    
    private func updateUser() {
        if self.updatingUser {
            return
        }
        
        self.updatingUser = true
        self.updateUserInfoMethod = self.authorisedUserService.loadRegisteredUser(withModel: self.authorisedUserModel)
    }
    
    private func configureUserProfile() {
        self.loadProfileImage()
        
        if let currencyCode = authorisedUserModel.currency {
            self.numberFormatter.currencyCode = currencyCode
        }
        
        self.profileUsernameLabel?.text = self.authorisedUserModel.username
        self.profileBalanceLabel?.text = self.numberFormatter.string(from: self.authorisedUserModel.credits)
        self.profileEmailLabel.text = self.authorisedUserModel.email
        
        self.configurePhoneNumber()
    }
    
    private func configurePhoneNumber() {
        var regionCode: String?
        if let code = self.countryListDataService.countryRegionCode(forCountryCode: self.authorisedUserModel.callingCode) {
            regionCode = code
        } else if let localeRegionCode = Locale.current.regionCode, let countryName = Locale.init(identifier: "en_US").localizedString(forRegionCode: localeRegionCode) {
            regionCode = self.countryListDataService.countryRegionCode(forCountryName: countryName)
        }
        
        if let code = regionCode, self.phoneNumberFormatter.defaultRegion != code {
            self.phoneNumberFormatter.defaultRegion = code
        }
        
        let phoneNumberString = self.authorisedUserModel.callingCode + " " + self.phoneNumberFormatter.formatPartial(self.authorisedUserModel.phoneNumber)
        self.profilePhoneNumberLabel?.text = phoneNumberString
    }
    
    private func loadProfileImage() {
        let serverAddress = self.infoPlistService.serverURL()
        if let profileImageURL = self.authorisedUserModel.profilePictureURL, let imageURL = URL.address(byAppendingServerAddress: serverAddress, toContentPath: profileImageURL) {
            let resourse = ImageResource(downloadURL: imageURL)
            self.profileImageView?.kf.indicatorType = .activity
            (self.profileImageView?.kf.indicator?.view as? UIActivityIndicatorView)?.color = .white
            self.profileImageView?.kf.setImage(with: resourse)
        } else {
            self.profileImageView?.kf.cancelDownloadTask()
            self.profileImageView?.image = UIImage.tv_profilePlaceholder()
        }
    }
    
    // MARK: Controls Actions
    
    @IBAction func editButtonAction(_ sender: UIButton) {
        self.viewControllerPushed = true
        self.router.showEditProfileViewController(withAuthorisedUserModel: self.authorisedUserModel)
    }
    
    @IBAction func balanceTapGestureAction(_ sender: UIGestureRecognizer) {
        switch sender.state {
        case .began:
            self.balanceView?.alpha = 0.5
            break
        case .changed:
            self.balanceView?.alpha = 0.5
            break
        case .ended:
            self.balanceView?.alpha = 1.0
            
            self.viewControllerPushed = true
            self.router.showCreditsViewController(withAuthorisedUserModel: self.authorisedUserModel)
            break
        default:
            self.balanceView?.alpha = 1.0
        }
    }
    
    // MARK: Protocols Implementation
    
    // MARK: SettingsControls
    
    internal func settingsControlsShouldLogout(_ controls: SettingsControlsTableViewController) {
        self.authorisedUserService.deauthoriseUser()
        self.createCoursesService.cancelUploadCourseResources()
        self.createCoursesService.deleteSavedCourseModel()
        self.coursesService.cancelAllCoursesLoading()
        self.coursesService.removeCoursesAndIdentifiers()
        
        self.router.showUnauthorisedViewController()
    }
    
    // MARK: AuthorisedUserModelDelegate
    
    internal func authorisedUserChagned(user: AuthorisedUserModel) {
        if self.authorisedUserModel.id == user.id && self.viewDidLoaded {
            self.configureUserProfile()
        }
    }

}
