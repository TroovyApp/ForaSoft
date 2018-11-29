//
//  OtherProfileViewController.swift
//  troovy-ios
//
//  Created by Daniil on 17.11.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

import Kingfisher

class OtherProfileViewController: TroovyViewController, CoursesListDelegate, CoursesReceiverDelegate {

    // MARK: Interface Builder Properties
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var topSeparatorView: UIView!
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var profileUsernameLabel: UILabel!
    
    @IBOutlet weak var titleLabelToTop: NSLayoutConstraint!
    @IBOutlet weak var profileImageViewToTop: NSLayoutConstraint!
    @IBOutlet weak var profileUsernameToTop: NSLayoutConstraint!
    
    // MARK: Public Properties
    
    /// Model of the unauthorised user.
    var authorisedUserModel: AuthorisedUserModel!
    
    /// User ID to show profile.
    var userID: String!
    
    // MARK: Private Properties
    
    private let infoPlistService = InfoPlistService()
    private var authorisedUserService: AuthorisedUserService!
    private var coursesService: CoursesService!
    
    private let courseListProperties = CourseListProperties()
    
    private var coursesListViewController: CoursesListViewController?
    private var coursesListViewControllerConfigured = false
    
    private var userModel: UserModel?
    
    private var collectionViewLayouted = false
    private var titleLabelToTopValue: CGFloat = 0.0
    private var profileImageViewToTopValue: CGFloat = 0.0
    private var profileUsernameToTopValue: CGFloat = 0.0
    
    private var loadUsersMethod: String?
    private var findCoursesIdentifiersMethod: String?
    private var loadCoursesIdentifiersMethod: String?
    private var fetchCoursesMethod: String?
    private var loadCoursesMethod: String?
    
    // MARK: Init Methods & Superclass Overriders
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.titleLabel.text = ApplicationMessages.ScreenTitles.settingsHomeScreen
        
        self.configureUserProfile()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !self.coursesListViewControllerConfigured {
            self.coursesListViewController?.configure(withListType: CourseListProperties.CourseListType.other, delegate: self)
            self.coursesListViewControllerConfigured = true
        }
        
        if !self.collectionViewLayouted {
            self.titleLabelToTopValue = self.titleLabelToTop.constant
            self.profileImageViewToTopValue = self.profileImageViewToTop.constant
            self.profileUsernameToTopValue = self.profileUsernameToTop.constant
            
            self.changeCollectionInsets()
            
            self.collectionViewLayouted = true
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    deinit {
        self.authorisedUserService.cancelUserLoading()
        self.coursesService.cancelCoursesLoading(forListType: .other)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let coursesListViewController = segue.destination as? CoursesListViewController {
            self.coursesListViewController = coursesListViewController
        }
    }
    
    override func inject(propertiesWithAssembly assembly: ViewControllerAssemblyManager) {
        self.authorisedUserService = assembly.authorisedUserService
        self.coursesService = assembly.coursesService
    }
    
    override func configureServices() {
        self.authorisedUserService.delegate = self
        self.coursesService.delegate = self
        self.coursesService.coursesReceiver = self
    }
    
    override func serviceStateChanged(withActionResult result: ServiceActionResult) {
        switch result {
        case .methodFailed(let method, let error):
            if method == self.loadUsersMethod {
                self.showDismissalAlert(withTitle: ApplicationMessages.AlertTitles.message, message: error)
            }
            break
        default:
            super.serviceStateChanged(withActionResult: result)
            break
        }
    }
    
    override func serviceMethodSucceeded(withMethod method: String, resultDictionary: [String : Any]?, resultArray: [[String : Any]]?, resultString: String?) {
        if method == self.loadUsersMethod {
            if let usersDictionaries = resultArray {
                for dictionary in usersDictionaries {
                    self.userModel = UserModel(withDictionary: dictionary)
                    self.configureUserProfile()
                    break
                }
            }
        }
    }
    
    // MARK: Private Methods
    
    private func configureUserProfile() {
        if self.userModel != nil {
            self.loadProfileImage()
            self.profileUsernameLabel?.text = self.userModel?.username
        } else {
            self.loadUsersMethod = self.authorisedUserService.loadUsers(withUsersIdentifiers: [self.userID], user: self.authorisedUserModel)
            self.profileUsernameLabel?.text = nil
            self.profileImageView?.image = UIImage.tv_profilePlaceholder()
        }
    }
    
    // MARK: Load Courses Methods
    
    private func fetchLastCourses(forListType type: CourseListProperties.CourseListType) {
        guard let coursesListViewController = self.coursesListViewController(forListType: type) else {
            return
        }
        
        if !coursesListViewController.readyForReloadCourses() {
            return
        } else if !coursesListViewController.readyForLoadMoreCourses() {
            self.coursesService.cancelCoursesLoading(forListType: type)
        }
        
        coursesListViewController.prepareForReload()
        coursesListViewController.finishIdentifiersSearch(withIdentifiersToLoad: [], identifiersToFetch: [])
        
        let coursesLoadedCount = coursesListViewController.coursesCount()
        let coursesCountToLoad = self.courseListProperties.countOfCoursesPerPage
        if coursesLoadedCount == 0 {
            self.findCoursesIdentifiersMethod = self.coursesService.coursesIdentifiersToLoadAndFetch(forListType: type, methodType: CourseListProperties.CourseListMethodType.fetchLastCourses, userID: self.userID, shouldReloadData: true, coursesLoadedCount: coursesLoadedCount, coursesCountToLoad: coursesCountToLoad)
        } else {
            self.reloadContent(forListType: type)
        }
    }
    
    private func loadMoreContent(forListType type: CourseListProperties.CourseListType) {
        guard let coursesListViewController = self.coursesListViewController(forListType: type) else {
            return
        }
        
        if !coursesListViewController.readyForLoadMoreCourses() {
            return
        }
        
        coursesListViewController.prepareForLoadMore()
        coursesListViewController.finishIdentifiersSearch(withIdentifiersToLoad: [], identifiersToFetch: [])
        
        let coursesLoadedCount = coursesListViewController.coursesCount()
        let coursesCountToLoad = self.courseListProperties.countOfCoursesPerPage
        self.findCoursesIdentifiersMethod = self.coursesService.coursesIdentifiersToLoadAndFetch(forListType: type, methodType: CourseListProperties.CourseListMethodType.loadMoreCourses, userID: self.userID, shouldReloadData: false, coursesLoadedCount: coursesLoadedCount, coursesCountToLoad: coursesCountToLoad)
    }
    
    private func reloadContent(forListType type: CourseListProperties.CourseListType) {
        guard let coursesListViewController = self.coursesListViewController(forListType: type) else {
            return
        }
        
        let coursesIdentifiersPage = coursesListViewController.coursesIdentifiersPageValue()
        let coursesIdentifiersCountToLoad = self.courseListProperties.countOfCoursesIdentifiersPerPage
        self.loadCoursesIdentifiersMethod = self.coursesService.loadCoursesIdentifiers(forListType: type, methodType: CourseListProperties.CourseListMethodType.reloadCourses, user: self.authorisedUserModel, userID: self.userID, page: coursesIdentifiersPage, count: coursesIdentifiersCountToLoad)
    }
    
    // MARK: Support Methods
    
    private func moveProfileInfoWithScroll() {
        guard let coursesListViewController = self.coursesListViewController(forListType: CourseListProperties.CourseListType.other), let collectionView = coursesListViewController.collectionView else {
            return
        }
        
        if !self.collectionViewLayouted {
            return
        }
        
        if collectionView.contentInset.top + collectionView.contentOffset.y <= 0 {
            self.titleLabelToTop.constant = self.titleLabelToTopValue
            self.profileImageViewToTop.constant = self.profileImageViewToTopValue
            self.profileUsernameToTop.constant = self.profileUsernameToTopValue
        } else {
            self.profileImageViewToTop.constant = self.profileImageViewToTopValue - (collectionView.contentInset.top + collectionView.contentOffset.y)
            
            if (self.profileUsernameToTopValue - (collectionView.contentInset.top + collectionView.contentOffset.y)) < 16.0 {
                self.profileUsernameToTop.constant = 16.0
            } else {
                self.profileUsernameToTop.constant = self.profileUsernameToTopValue - (collectionView.contentInset.top + collectionView.contentOffset.y)
            }
            
            let profileUsernameProgress = (self.profileUsernameToTopValue - self.profileUsernameToTop.constant) / (self.profileUsernameToTopValue - 16.0)
            let newFontSize = (16.0 - (2.0 * profileUsernameProgress))
            self.profileUsernameLabel.font = UIFont.systemFont(ofSize: newFontSize, weight: (newFontSize == 14.0 ? .semibold : .medium))
            
            if self.titleLabelToTopValue + self.titleLabel.bounds.height > (self.profileUsernameToTopValue - (collectionView.contentInset.top + collectionView.contentOffset.y)) {
                self.titleLabelToTop.constant = (self.profileUsernameToTopValue - (collectionView.contentInset.top + collectionView.contentOffset.y)) - self.titleLabel.bounds.height
            } else {
                self.titleLabelToTop.constant = self.titleLabelToTopValue
            }
        }
    }
    
    private func coursesListViewController(forListType type: CourseListProperties.CourseListType) -> CoursesListViewController? {
        switch type {
        case .other:
            return self.coursesListViewController
        default:
            break
        }
        return nil
    }
    
    private func loadProfileImage() {
        let serverAddress = self.infoPlistService.serverURL()
        if let profileImageURL = self.userModel?.profilePictureURL, let imageURL = URL.address(byAppendingServerAddress: serverAddress, toContentPath: profileImageURL) {
            let resourse = ImageResource(downloadURL: imageURL)
            self.profileImageView?.kf.indicatorType = .activity
            (self.profileImageView?.kf.indicator?.view as? UIActivityIndicatorView)?.color = .white
            self.profileImageView?.kf.setImage(with: resourse)
        } else {
            self.profileImageView?.kf.cancelDownloadTask()
            self.profileImageView?.image = UIImage.tv_profilePlaceholder()
        }
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
    
    private func changeCollectionInsets() {
        guard let coursesListViewController = self.coursesListViewController(forListType: CourseListProperties.CourseListType.other) else {
            return
        }
        
        let topInset: CGFloat = self.profileUsernameToTopValue - 10.0
        if coursesListViewController.collectionView.contentInset.top != topInset {
            coursesListViewController.collectionView.contentInset = UIEdgeInsetsMake(topInset, 0.0, 0.0, 0.0)
        }
    }
    
    // MARK: Protocols Implementation
    
    // MARK: CoursesReceiverDelegate
    
    internal func coursesReceiverHandle(taskResult result: CoursesReceiverTaskResult) {
        switch result {
        case .methodSucceededWithObject(let method, let object):
            if method == self.findCoursesIdentifiersMethod {
                let coursesIdentifiersModel = object as! CoursesIdentifiersModel
                let listType = coursesIdentifiersModel.coursesServiceModel.listType
                let methodType = coursesIdentifiersModel.coursesServiceModel.methodType
                if let coursesListViewController = self.coursesListViewController(forListType: listType) {
                    coursesListViewController.finishIdentifiersSearch(withIdentifiersToLoad: coursesIdentifiersModel.identifiersToLoad, identifiersToFetch: coursesIdentifiersModel.identifiersToFetch)
                    
                    if methodType == .fetchLastCourses {
                        if coursesIdentifiersModel.identifiersToFetch.count > 0 {
                            self.fetchCoursesMethod = self.coursesService.fetchCourses(forListType: listType, methodType: methodType, identifiers: coursesIdentifiersModel.identifiersToFetch)
                        } else {
                            self.reloadContent(forListType: listType)
                        }
                    } else if methodType == .loadMoreCourses {
                        if coursesIdentifiersModel.identifiersToLoad.count > 0 {
                            self.loadCoursesMethod = self.coursesService.loadCourses(forListType: listType, methodType: methodType, user: self.authorisedUserModel, identifiers: coursesIdentifiersModel.identifiersToLoad)
                        } else {
                            if coursesIdentifiersModel.identifiersToFetch.count > 0 {
                                self.fetchCoursesMethod = self.coursesService.fetchCourses(forListType: listType, methodType: methodType, identifiers: coursesIdentifiersModel.identifiersToFetch)
                            } else if coursesIdentifiersModel.shouldLoadNextPage {
                                coursesListViewController.incrementCoursesIdentifiersPage()
                                
                                let coursesIdentifiersPage = coursesListViewController.coursesIdentifiersPageValue()
                                let coursesIdentifiersCountToLoad = self.courseListProperties.countOfCoursesIdentifiersPerPage
                                self.loadCoursesIdentifiersMethod = self.coursesService.loadCoursesIdentifiers(forListType: listType, methodType: methodType, user: self.authorisedUserModel, userID: self.userID, page: coursesIdentifiersPage, count: coursesIdentifiersCountToLoad)
                            } else {
                                coursesListViewController.coursesListCompleted()
                            }
                        }
                    } else if methodType == .reloadCourses {
                        if coursesIdentifiersModel.identifiersToLoad.count > 0 {
                            self.loadCoursesMethod = self.coursesService.loadCourses(forListType: listType, methodType: methodType, user: self.authorisedUserModel, identifiers: coursesIdentifiersModel.identifiersToLoad)
                        } else {
                            self.fetchCoursesMethod = self.coursesService.fetchCourses(forListType: listType, methodType: methodType, identifiers: coursesIdentifiersModel.identifiersToFetch)
                        }
                    }
                }
            } else if method == self.fetchCoursesMethod {
                let coursesModel = object as! CoursesModel
                let listType = coursesModel.coursesServiceModel.listType
                let methodType = coursesModel.coursesServiceModel.methodType
                if let coursesListViewController = self.coursesListViewController(forListType: listType) {
                    if methodType == .fetchLastCourses {
                        coursesListViewController.replaceCourses(withNew: coursesModel.courses)
                        self.reloadContent(forListType: listType)
                    } else if methodType == .loadMoreCourses {
                        coursesListViewController.appendCourses(withNew: coursesModel.courses)
                    } else if methodType == .reloadCourses {
                        coursesListViewController.replaceCourses(withNew: coursesModel.courses)
                    }
                }
            } else if method == self.loadCoursesIdentifiersMethod {
                let coursesServiceModel = object as! CoursesServiceModel
                let listType = coursesServiceModel.listType
                let methodType = coursesServiceModel.methodType
                let shouldReloadData = (methodType != .loadMoreCourses)
                if let coursesListViewController = self.coursesListViewController(forListType: listType) {
                    let coursesLoadedCount = coursesListViewController.coursesCount()
                    let coursesCountToLoad = self.courseListProperties.countOfCoursesPerPage
                    self.findCoursesIdentifiersMethod = self.coursesService.coursesIdentifiersToLoadAndFetch(forListType: listType, methodType: methodType, userID: self.userID, shouldReloadData: shouldReloadData, coursesLoadedCount: coursesLoadedCount, coursesCountToLoad: coursesCountToLoad)
                }
            } else if method == self.loadCoursesMethod {
                let coursesServiceModel = object as! CoursesServiceModel
                let listType = coursesServiceModel.listType
                let methodType = coursesServiceModel.methodType
                if let coursesListViewController = self.coursesListViewController(forListType: listType) {
                    let identifiers = coursesListViewController.identifiersToLoad() + coursesListViewController.identifiersToFetch()
                    self.fetchCoursesMethod = self.coursesService.fetchCourses(forListType: listType, methodType: methodType, identifiers: identifiers)
                }
            } else {
                if let coursesModel = object as? CoursesModel {
                    let listType = coursesModel.coursesServiceModel.listType
                    let methodType = coursesModel.coursesServiceModel.methodType
                    if let coursesListViewController = self.coursesListViewController(forListType: listType) {
                        if methodType == .deleteCourse {
                            coursesListViewController.deleteCourses(withNew: coursesModel.courses)
                        } else if methodType == .addNewCourses {
                            coursesListViewController.insertCourses(withNew: coursesModel.courses)
                        }
                    }
                }
            }
            break
        case .methodFailedWithObject( _, let error, let object):
            if let coursesServiceModel = object as? CoursesServiceModel {
                let listType = coursesServiceModel.listType
                let methodType = coursesServiceModel.methodType
                if let coursesListViewController = self.coursesListViewController(forListType: listType) {
                    coursesListViewController.finishIdentifiersSearch(withIdentifiersToLoad: [], identifiersToFetch: [])
                    
                    if methodType == .reloadCourses || methodType == .fetchLastCourses {
                        coursesListViewController.reloadFailed(withError: error)
                    } else if methodType == .loadMoreCourses {
                        coursesListViewController.loadMoreFailed(withError: error)
                    }
                }
            }
            break
        }
    }
    
    // MARK: CoursesListDelegate
    
    internal func coursesList(list: UIViewController, initiateFetchingLastCoursesWithListType type: CourseListProperties.CourseListType) {
        self.fetchLastCourses(forListType: type)
    }
    
    internal func coursesList(list: UIViewController, initiateLoadingMoreCoursesWithListType type: CourseListProperties.CourseListType) {
        self.loadMoreContent(forListType: type)
    }
    
    internal func coursesList(list: UIViewController, initiateReloadingCoursesWithListType type: CourseListProperties.CourseListType) {
        guard let coursesListViewController = self.coursesListViewController(forListType: type) else {
            return
        }
        
        if !coursesListViewController.readyForReloadCourses() {
            return
        } else if !coursesListViewController.readyForLoadMoreCourses() {
            self.coursesService.cancelCoursesLoading(forListType: type)
        }
        
        coursesListViewController.prepareForReload()
        coursesListViewController.finishIdentifiersSearch(withIdentifiersToLoad: [], identifiersToFetch: [])
        
        self.reloadContent(forListType: type)
    }
    
    internal func coursesList(list: UIViewController, initiateShowingError error: String?, withListType type: CourseListProperties.CourseListType) {
        if list == self.coursesListViewController {
            self.showAlert(withTitle: ApplicationMessages.AlertTitles.message, message: error)
        }
    }
    
    internal func coursesList(list: UIViewController, initiateShowingCourse course: CourseModel, withListType type: CourseListProperties.CourseListType) {
        if list == self.coursesListViewController {
            if type == .own {
                self.router.showOwnCourseScreen(withAuthorisedUserModel: self.authorisedUserModel, courseModel: course)
            } else {
                self.router.showCommonCourseScreen(withAuthorisedUserModel: self.authorisedUserModel, courseModel: course, courseID: course.id)
            }
        }
    }
    
    internal func coursesList(list: UIViewController, didScrollCollectionView collectionView: UICollectionView, withListType type: CourseListProperties.CourseListType) {
        if list == self.coursesListViewController {
            self.moveProfileInfoWithScroll()
            
            self.topSeparatorView.isHidden = !((collectionView.contentInset.top + collectionView.contentOffset.y) >= 26.0)
        }
    }

}
