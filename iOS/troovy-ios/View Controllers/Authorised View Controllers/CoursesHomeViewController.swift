
//
//  CoursesHomeViewController.swift
//  troovy-ios
//
//  Created by Daniil on 23.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

import EMPageViewController

class CoursesHomeViewController: TroovyViewController, EMPageViewControllerDelegate, EMPageViewControllerDataSource, CoursesListDelegate, CoursesReceiverDelegate {
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var segmentedControl: NLSegmentControl?
    @IBOutlet weak var topSeparatorView: UIView!
    @IBOutlet weak var bottomSeparatorView: UIView!
    
    // MARK: Public Properties
    
    /// Model of the unauthorised user.
    var authorisedUserModel: AuthorisedUserModel!
    
    // MARK: Private Properties
    
    private var coursesService: CoursesService!
    private var applicationService: ApplicationService!
    private var authorisedUserService: AuthorisedUserService!
    
    private let courseListProperties = CourseListProperties()
    
    private var pageViewController: EMPageViewController!
    private var coursesListPages: [UIViewController] = []
    
    private var listAnimationPerformed = false
    
    private var findCoursesIdentifiersMethod: String?
    private var loadCoursesIdentifiersMethod: String?
    private var fetchCoursesMethod: String?
    private var loadCoursesMethod: String?
    private var updateUserInfoMethod: String?
    
    private var updatingUser = false
    
    // MARK: Init Methods & Superclass Overriders
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = nil
        self.titleLabel?.text = ApplicationMessages.ScreenTitles.coursesHomeScreen
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.setupSegmentedControl()
        self.setupCoursesListPages()
        self.updateUser()
        
        if let courseToOpen = self.applicationService.restoreCourseToOpen() {
            DispatchQueue.main.async {
                self.router.showCommonCourseScreen(withAuthorisedUserModel: self.authorisedUserModel, courseModel: courseToOpen.0, courseID: courseToOpen.1)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let pageViewController = segue.destination as? EMPageViewController {
            self.pageViewController = pageViewController
            self.pageViewController.delegate = self
            self.pageViewController.dataSource = self
        }
    }
    
    override func inject(propertiesWithAssembly assembly: ViewControllerAssemblyManager) {
        self.coursesService = assembly.coursesService
        self.applicationService = assembly.applicationService
        self.authorisedUserService = assembly.authorisedUserService
    }
    
    override func configureServices() {
        self.coursesService.delegate = self
        self.coursesService.coursesReceiver = self
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
    
    // MARK: Private Methods
    
    private func updateUser() {
        if self.updatingUser {
            return
        }
        
        self.updatingUser = true
        self.updateUserInfoMethod = self.authorisedUserService.loadRegisteredUser(withModel: self.authorisedUserModel)
    }
    
    private func setupSegmentedControl() {
        if self.coursesListPages.count != 0 {
            return
        }
        
        self.segmentedControl?.segments = ["Subscribed", "Featured", "My Workshops"]
        self.segmentedControl?.selectionIndicatorStyle = .textWidthStripe
        self.segmentedControl?.segmentWidthStyle = .fixed
        self.segmentedControl?.selectionIndicatorColor = UIColor.tv_purpleColor()
        self.segmentedControl?.selectionIndicatorHeight = 3.0
        self.segmentedControl?.selectionIndicatorPosition = .bottom
        self.segmentedControl?.selectionIndicatorEdgeInset = UIEdgeInsetsMake(0.0, -3.5, 0.0, -3.5)
        self.segmentedControl?.segmentEdgeInset = UIEdgeInsetsMake(-10.0, 0.0, 0.0, 0.0)
        self.segmentedControl?.selectedTitleTextAttributes = [NSAttributedStringKey.font : UIFont.systemFont(ofSize: 14.0, weight: .medium), NSAttributedStringKey.foregroundColor : UIColor.tv_purpleColor()]
        self.segmentedControl?.titleTextAttributes = [NSAttributedStringKey.font : UIFont.systemFont(ofSize: 14.0, weight: .regular), NSAttributedStringKey.foregroundColor : UIColor.tv_grayTextColor()]
        self.segmentedControl?.indexChangedHandler = { [weak self] (index) in
            self?.segmentedControlDidChange(index)
        }
        
        self.segmentedControl?.reloadSegments()
        self.segmentedControl?.layoutIfNeeded()
    }
    
    private func setupCoursesListPages() {
        if self.coursesListPages.count != 0 {
            return
        }
        
        let ownCoursesViewController = self.storyboard?.instantiateViewController(withIdentifier: "CoursesListViewController") as! CoursesListViewController
        ownCoursesViewController.configure(withListType: CourseListProperties.CourseListType.own, delegate: self)
        
        let allCoursesViewController = self.storyboard?.instantiateViewController(withIdentifier: "CoursesListViewController") as! CoursesListViewController
        allCoursesViewController.configure(withListType: CourseListProperties.CourseListType.all, delegate: self)
        
        let subscribedCoursesViewController = self.storyboard?.instantiateViewController(withIdentifier: "CoursesListViewController") as! CoursesListViewController
        subscribedCoursesViewController.configure(withListType: CourseListProperties.CourseListType.subscribed, delegate: self)
        
        self.coursesListPages.insert(subscribedCoursesViewController, at: CourseListProperties.CourseListType.subscribed.rawValue)
        self.coursesListPages.insert(allCoursesViewController, at: CourseListProperties.CourseListType.all.rawValue)
        self.coursesListPages.insert(ownCoursesViewController, at: CourseListProperties.CourseListType.own.rawValue)
        
        self.segmentedControl?.setSelectedSegmentIndex(0, animated: false)
        self.pageViewController.selectViewController(subscribedCoursesViewController, direction: .forward, animated: false, completion: nil)
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
            self.findCoursesIdentifiersMethod = self.coursesService.coursesIdentifiersToLoadAndFetch(forListType: type, methodType: CourseListProperties.CourseListMethodType.fetchLastCourses, userID: nil, shouldReloadData: true, coursesLoadedCount: coursesLoadedCount, coursesCountToLoad: coursesCountToLoad)
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
        self.findCoursesIdentifiersMethod = self.coursesService.coursesIdentifiersToLoadAndFetch(forListType: type, methodType: CourseListProperties.CourseListMethodType.loadMoreCourses, userID: nil, shouldReloadData: false, coursesLoadedCount: coursesLoadedCount, coursesCountToLoad: coursesCountToLoad)
    }
    
    private func reloadContent(forListType type: CourseListProperties.CourseListType) {
        guard let coursesListViewController = self.coursesListViewController(forListType: type) else {
            return
        }
        
        let coursesIdentifiersPage = coursesListViewController.coursesIdentifiersPageValue()
        let coursesIdentifiersCountToLoad = self.courseListProperties.countOfCoursesIdentifiersPerPage
        self.loadCoursesIdentifiersMethod = self.coursesService.loadCoursesIdentifiers(forListType: type, methodType: CourseListProperties.CourseListMethodType.reloadCourses, user: self.authorisedUserModel, userID: nil, page: coursesIdentifiersPage, count: coursesIdentifiersCountToLoad)
    }
    
    // MARK: Support Methods
    
    private func coursesListViewController(forListType type: CourseListProperties.CourseListType) -> CoursesListViewController? {
        var coursesListViewController: CoursesListViewController?
        if type.rawValue < self.coursesListPages.count {
            coursesListViewController = self.coursesListPages[type.rawValue] as? CoursesListViewController
        }
        return coursesListViewController
    }
    
    // MARK: Controls Actions
    
    @IBAction func createCourseButtonAction(_ sender: UIButton) {
        self.view.endEditing(true)
        
        self.router.showCreateCourseMainInfoScreen(withAuthorisedUserModel: self.authorisedUserModel, courseModel: nil)
    }
    
    private func segmentedControlDidChange(_ index: Int) {
        self.view.endEditing(true)
        
        guard let selectedViewController = self.pageViewController.selectedViewController, let viewControllerIndex = self.coursesListPages.index(of: selectedViewController) else {
            return
        }
        
        if index >= 0 && index < self.coursesListPages.count {
            if self.listAnimationPerformed {
                return
            }
            
            self.listAnimationPerformed = true
            
            let newViewController = self.coursesListPages[index]
            let direction = (viewControllerIndex <= index ? EMPageViewControllerNavigationDirection.forward : EMPageViewControllerNavigationDirection.reverse)
            
            self.pageViewController.selectViewController(newViewController, direction: direction, animated: true, completion: nil)
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
                                self.loadCoursesIdentifiersMethod = self.coursesService.loadCoursesIdentifiers(forListType: listType, methodType: methodType, user: self.authorisedUserModel, userID: nil, page: coursesIdentifiersPage, count: coursesIdentifiersCountToLoad)
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
                    self.findCoursesIdentifiersMethod = self.coursesService.coursesIdentifiersToLoadAndFetch(forListType: listType, methodType: methodType, userID: nil, shouldReloadData: shouldReloadData, coursesLoadedCount: coursesLoadedCount, coursesCountToLoad: coursesCountToLoad)
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
        if list == self.pageViewController.selectedViewController {
            self.showAlert(withTitle: ApplicationMessages.AlertTitles.message, message: error)
        }
    }
    
    internal func coursesList(list: UIViewController, initiateShowingCourse course: CourseModel, withListType type: CourseListProperties.CourseListType) {
        if list == self.pageViewController.selectedViewController {
            if type == .own {
                self.router.showOwnCourseScreen(withAuthorisedUserModel: self.authorisedUserModel, courseModel: course)
            } else {
                self.router.showCommonCourseScreen(withAuthorisedUserModel: self.authorisedUserModel, courseModel: course, courseID: course.id)
            }
        }
    }
    
    internal func coursesList(list: UIViewController, didScrollCollectionView collectionView: UICollectionView, withListType type: CourseListProperties.CourseListType) {
        if list == self.pageViewController.selectedViewController {
            self.topSeparatorView.isHidden = !(collectionView.contentOffset.y >= 15.0)
            self.bottomSeparatorView.isHidden = !(collectionView.contentSize.height - collectionView.contentOffset.y - collectionView.bounds.height >= 29.0)
        }
    }
    
    internal func coursesListInitiateCreatingNewCourse(list: UIViewController) {
        self.view.endEditing(true)
        self.router.showCreateCourseMainInfoScreen(withAuthorisedUserModel: self.authorisedUserModel, courseModel: nil)
    }
    
    internal func coursesList(list: UIViewController, initiateSwitchingToListType type: CourseListProperties.CourseListType) {
        var index = 0
        switch type {
        case .subscribed:
            index = 0
        case .all:
            index = 1
        case .own:
            index = 2
        default:
            break
        }
        
        segmentedControl?.setSelectedSegmentIndex(index, animated: true)
        self.segmentedControlDidChange(index)
    }
    
    // MARK: EMPageViewControllerDelegate & EMPageViewControllerDataSource
    
    internal func em_pageViewController(_ pageViewController: EMPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        if let viewControllerIndex = self.coursesListPages.index(of: viewController) {
            let newIndex = viewControllerIndex - 1
            if newIndex >= 0 && newIndex < self.coursesListPages.count {
                let newViewController = self.coursesListPages[newIndex]
                return newViewController
            }
        }
        
        return nil
    }
    
    internal func em_pageViewController(_ pageViewController: EMPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        if let viewControllerIndex = self.coursesListPages.index(of: viewController) {
            let newIndex = viewControllerIndex + 1
            if newIndex >= 0 && newIndex < self.coursesListPages.count {
                let newViewController = self.coursesListPages[newIndex]
                return newViewController
            }
        }
        
        return nil
    }
    
    internal func em_pageViewController(_ pageViewController: EMPageViewController, didFinishScrollingFrom startingViewController: UIViewController?, destinationViewController:UIViewController, transitionSuccessful: Bool) {
        if !transitionSuccessful {
            return
        }
        
        if let viewControllerIndex = self.coursesListPages.index(of: destinationViewController) {
            self.listAnimationPerformed = false
            
            self.segmentedControl?.setSelectedSegmentIndex(viewControllerIndex, animated: true)
        }
    }

}
