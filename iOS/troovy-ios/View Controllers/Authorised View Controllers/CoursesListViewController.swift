
//
//  CoursesListViewController.swift
//  troovy-ios
//
//  Created by Daniil on 30.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class CoursesListViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var emptyView: UIView?
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: Private Properties
    
    private let infoPlistService = InfoPlistService()
    
    private let coursesUpdateQueue = DispatchQueue(label: "coursesUpdateQueue")
    private let coursesDataQueue = DispatchQueue(label: "coursesDataQueue")
    
    private weak var delegate: CoursesListDelegate?
    private var listType: CourseListProperties.CourseListType!
    
    private var coursesFetched = false
    private var viewAppeared = false
    private var firstLoading = true
    private var isReloadingCourses = false
    private var isLoadingCourses = false
    private var allCoursesLoaded = false
    private var coursesIdentifiersPage = 0
    private var coursesIdentifiersToLoad: [String] = []
    private var coursesIdentifiersToFetch: [String] = []
    
    private var loadingFooterView: LoadingFooterCollectionReusableView?
    private var refreshControl: UIRefreshControl?
    private var numberFormatter: NumberFormatter!
    
    private var courses: [CourseModel] = []
    
    // MARK: Init Methods & Superclass Overriders

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupNumberFormatter()
        
        if let emptyView = self.emptyView as? CoursesEmptyView {
            self.setupEmptyView()
        }
        
        if self.courses.count > 0 {
            self.collectionView.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.checkCollectionViewState()
        
        self.refreshControl?.setRefreshing(self.isLoadingCourses)
        self.viewAppeared = true
        
        DispatchQueue.main.async {
            self.setupCollectionView()
            
            if self.delegate != nil && !self.coursesFetched {
                self.coursesFetched = true
                self.fetchLastCourses()
            }
            
            if self.collectionView.contentOffset.y <= 0 {
                self.collectionView.contentOffset = CGPoint(x: 0.0, y: -self.collectionView.contentInset.top)
            }
            
            self.delegate?.coursesList(list: self, didScrollCollectionView: self.collectionView, withListType: self.listType)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.viewAppeared = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.collectionView?.collectionViewLayout.invalidateLayout()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: Public Methods
    
    // MARK: Configure Methods
    
    /// Configures view controller.
    ///
    /// - parameter type: Courses list type.
    /// - parameter delegate: Delegate which repsponds to CoursesListDelegate.
    ///
    func configure(withListType type: CourseListProperties.CourseListType, delegate: CoursesListDelegate?) {
        self.listType = type
        self.delegate = delegate
        
        if self.delegate != nil && !self.coursesFetched && self.isViewLoaded {
            self.coursesFetched = true
            self.fetchLastCourses()
        }
    }
    
    /// Configures view controller for reloading.
    func prepareForReload() {
        if self.courses.count == 0 {
            self.firstLoading = true
            self.checkCollectionViewState()
        }
        
        self.isReloadingCourses = true
        self.isLoadingCourses = true
        self.allCoursesLoaded = false
        self.coursesIdentifiersPage = 0
        
        self.loadingFooterView?.setVisible(visible: false)
    }
    
    /// Configures view controller for loading more.
    func prepareForLoadMore() {
        self.isLoadingCourses = true
        
        self.loadingFooterView?.setVisible(visible: true)
    }
    
    /// Configures view controller for state when reload failed.
    ///
    /// - parameter error: Error string.
    ///
    func reloadFailed(withError error: String?) {
        let firstLoading = self.firstLoading
        
        self.refreshControl?.setRefreshing(false)
        self.firstLoading = false
        self.isReloadingCourses = false
        self.isLoadingCourses = false
        
        if firstLoading {
            self.checkCollectionViewState()
        }
        
        if self.viewAppeared {
            self.delegate?.coursesList(list: self, initiateShowingError: error, withListType: self.listType)
        }
    }
    
    /// Configures view controller for state when load more failed.
    ///
    /// - parameter error: Error string.
    ///
    func loadMoreFailed(withError error: String?) {
        self.isLoadingCourses = false
        
        self.loadingFooterView?.setVisible(visible: false)
        
        if self.viewAppeared {
            self.delegate?.coursesList(list: self, initiateShowingError: error, withListType: self.listType)
        }
    }
    
    /// Configures view controller for state when all courses loaded.
    func coursesListCompleted() {
        self.isLoadingCourses = false
        self.allCoursesLoaded = true
        
        self.loadingFooterView?.setVisible(visible: false)
    }
    
    // MARK: Properties Methods
    
    /// Shows if list is ready for reloading.
    ///
    /// - returns: True if list isn't reloading now. False otherwise.
    ///
    func readyForReloadCourses() -> Bool {
        return !self.isReloadingCourses
    }
    
    /// Shows if list is ready for loading more.
    ///
    /// - returns: True if list isn't reloading and loading more now. False otherwise.
    ///
    func readyForLoadMoreCourses() -> Bool {
        return !self.isLoadingCourses && !self.isReloadingCourses
    }
    
    /// Asks for current courses count.
    ///
    /// - returns: Loaded courses count.
    ///
    func coursesCount() -> Int {
        return self.courses.count
    }
    
    /// Asks for current courses page number.
    ///
    /// - returns: Loaded courses page number.
    ///
    func coursesIdentifiersPageValue() -> Int {
        return self.coursesIdentifiersPage
    }
    
    /// Asks for current identifiers to load.
    ///
    /// - returns: Array of identifiers to load.
    ///
    func identifiersToLoad() -> [String] {
        return self.coursesIdentifiersToLoad
    }
    
    /// Asks for current identifiers to fetch.
    ///
    /// - returns: Array of identifiers to fetch.
    ///
    func identifiersToFetch() -> [String] {
        return self.coursesIdentifiersToFetch
    }
    
    // MARK: Change Properties Methods
    
    /// Increments courses page number.
    func incrementCoursesIdentifiersPage() {
        self.coursesIdentifiersPage += 1
    }
    
    /// Inserts new courses at the beggining.
    ///
    /// - parameter courses: Array of new courses.
    ///
    func insertCourses(withNew courses: [CourseModel]) {
        self.coursesUpdateQueue.async {
            self.changeCourses(byInsertingCourses: courses)
        }
    }
    
    /// Deletes courses.
    ///
    /// - parameter courses: Array of deleted courses.
    ///
    func deleteCourses(withNew courses: [CourseModel]) {
        self.coursesUpdateQueue.async {
            self.changeCourses(byDeletingCourses: courses)
        }
    }
    
    /// Replaces current courses with new courses.
    ///
    /// - parameter courses: Array of new courses.
    ///
    func replaceCourses(withNew courses: [CourseModel]) {
        let firstLoading = self.firstLoading
        
        self.refreshControl?.setRefreshing(false)
        self.firstLoading = false
        self.isReloadingCourses = false
        self.isLoadingCourses = false
        
        if firstLoading && courses.count == 0 {
            self.checkCollectionViewState()
        }
        
        self.coursesUpdateQueue.async {
            self.changeCourses(byReplacingWithCourses: courses)
        }
    }
    
    /// Appends new courses.
    ///
    /// - parameter courses: Array of new courses.
    ///
    func appendCourses(withNew courses: [CourseModel]) {
        self.isLoadingCourses = false
        
        self.loadingFooterView?.setVisible(visible: false)
        
        self.coursesUpdateQueue.async {
            self.changeCourses(byAppendingCourses: courses)
        }
    }
    
    /// Stores new identifirs to load and identifiers to fetch.
    ///
    /// - parameter identifiersToLoad: Array of identifiers to load.
    /// - parameter identifiersToFetch: Array of identifier to fetch.
    ///
    func finishIdentifiersSearch(withIdentifiersToLoad identifiersToLoad: [String], identifiersToFetch: [String]) {
        self.coursesIdentifiersToLoad = identifiersToLoad
        self.coursesIdentifiersToFetch = identifiersToFetch
    }
    
    // MARK: Private Methods
    
    private func setupEmptyView() {
        let emptyView = self.emptyView as? CoursesEmptyView
        emptyView?.configure(withCourseListType: listType)
        emptyView?.leftButtonHandler = {
            self.reloadButtonAction()
        }
        if listType == .subscribed {
            emptyView?.rightButtonHandler = {
                self.delegate?.coursesList(list: self, initiateSwitchingToListType: .all)
            }
        } else {
            emptyView?.rightButtonHandler = {
                self.delegate?.coursesListInitiateCreatingNewCourse(list: self)
            }
        }
        
    }
    
    private func setupNumberFormatter() {
        self.numberFormatter = NumberFormatter()
        self.numberFormatter.numberStyle = .currency
        if let currency = TroovyProducts.shared.getCurrentCurrency(), let locale = TroovyProducts.shared.getCurrentCurrencyLocale() {
            self.numberFormatter.currencyCode = currency
            self.numberFormatter.locale = locale
        }
        self.numberFormatter.minimumFractionDigits = 2
    }
    
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
        
        if #available(iOS 11.0, *) {
            self.collectionView.contentInsetAdjustmentBehavior = .never
        }
    }
    
    private func fetchLastCourses() {
        self.delegate?.coursesList(list: self, initiateFetchingLastCoursesWithListType: self.listType)
    }
    
    private func courseSelected(_ course: CourseModel) {
        self.delegate?.coursesList(list: self, initiateShowingCourse: course, withListType: self.listType)
    }
    
    // MARK: Update Collection View
    
    private func updateCollectionView(byReplacingWithCourses replaceCourses: [CourseModel]?, orByAppendingCourses appendCourses: [CourseModel]?, orByInsertingCourses insertCourses: [CourseModel]?, orByDeletingCourses deleteCourses: [CourseModel]?, completion: @escaping (() -> ())) {
        if let courses = replaceCourses {
            self.courses = courses
            
            DispatchQueue.main.async {
                if self.collectionView != nil {
                    self.collectionView.reloadData()
                    self.checkCollectionViewState()
                }
                completion()
            }
        } else if appendCourses != nil || insertCourses != nil {
            var indexPaths: [IndexPath] = []
            if let courses = appendCourses {
                for course in courses {
                    let indexPath = IndexPath(row: self.courses.count, section: 0)
                    indexPaths.append(indexPath)
                    
                    self.courses.append(course)
                }
            } else if let courses = insertCourses {
                var index = 0
                for course in courses {
                    let indexPath = IndexPath(row: index, section: 0)
                    indexPaths.append(indexPath)
                    
                    self.courses.insert(course, at: index)
                    
                    index += 1
                }
            }
            
            DispatchQueue.main.async {
                if indexPaths.count > 0 {
                    if self.viewAppeared {
                        if self.collectionView != nil {
                            self.collectionView.performBatchUpdates({
                                self.collectionView.insertItems(at: indexPaths)
                            }, completion: { (succeed) in
                                self.checkCollectionViewState()
                                completion()
                            })
                        }
                    } else {
                        if self.collectionView != nil {
                            self.collectionView.reloadData()
                            self.checkCollectionViewState()
                        }
                        completion()
                    }
                } else {
                    self.checkCollectionViewState()
                    completion()
                }
            }
        } else if deleteCourses != nil {
            var indexPaths: [IndexPath] = []
            if let courses = deleteCourses {
                for course in courses {
                    if let index = self.courses.index(where: { $0.id == course.id }) {
                        let indexPath = IndexPath(row: index, section: 0)
                        indexPaths.append(indexPath)
                    }
                }
                
                for indexPath in indexPaths {
                    let index = indexPath.row
                    self.courses.remove(at: index)
                }
                
                DispatchQueue.main.async {
                    if indexPaths.count > 0 {
                        if self.viewAppeared {
                            if self.collectionView != nil {
                                self.collectionView.performBatchUpdates({
                                    self.collectionView.deleteItems(at: indexPaths)
                                }, completion: { (succeed) in
                                    self.checkCollectionViewState()
                                    completion()
                                })
                            }
                        } else {
                            if self.collectionView != nil {
                                self.collectionView.reloadData()
                                self.checkCollectionViewState()
                            }
                            completion()
                        }
                    } else {
                        self.checkCollectionViewState()
                        completion()
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                if self.collectionView != nil {
                    self.collectionView.reloadData()
                    self.checkCollectionViewState()
                }
                completion()
            }
        }
    }
    
    // MARK: Support Methods
    
    private func checkCollectionViewState() {
        if self.courses.count == 0 && self.firstLoading {
            self.emptyView?.isHidden = true
            self.collectionView?.isHidden = true
            
            self.activityIndicator?.startAnimating()
        } else {
            self.activityIndicator?.stopAnimating()
            
            if self.courses.count == 0 {
                self.emptyView?.isHidden = false
                self.collectionView?.isHidden = true
            } else {
                self.emptyView?.isHidden = true
                self.collectionView?.isHidden = false
            }
        }
        
        if let collectionView = self.collectionView {
            self.delegate?.coursesList(list: self, didScrollCollectionView: collectionView, withListType: self.listType)
        }
    }
    
    private func changeCourses(byInsertingCourses courses: [CourseModel]) {
        let semaphore = DispatchSemaphore.init(value: 0)
        
        self.coursesDataQueue.async {
            self.updateCollectionView(byReplacingWithCourses: nil, orByAppendingCourses: nil, orByInsertingCourses: courses, orByDeletingCourses: nil, completion: {
                semaphore.signal()
            })
        }
        
        semaphore.wait()
    }
    
    private func changeCourses(byDeletingCourses courses: [CourseModel]) {
        let semaphore = DispatchSemaphore.init(value: 0)
        
        self.coursesDataQueue.async {
            self.updateCollectionView(byReplacingWithCourses: nil, orByAppendingCourses: nil, orByInsertingCourses: nil, orByDeletingCourses: courses, completion: {
                semaphore.signal()
            })
        }
        
        semaphore.wait()
    }
    
    private func changeCourses(byReplacingWithCourses courses: [CourseModel]) {
        let semaphore = DispatchSemaphore.init(value: 0)
        
        self.coursesDataQueue.async {
            self.updateCollectionView(byReplacingWithCourses: courses, orByAppendingCourses: nil, orByInsertingCourses: nil, orByDeletingCourses: nil, completion: {
                semaphore.signal()
            })
        }
        
        semaphore.wait()
    }
    
    private func changeCourses(byAppendingCourses courses: [CourseModel]) {
        if courses.count == 0 {
            return
        }
        
        let semaphore = DispatchSemaphore.init(value: 0)
        
        self.coursesDataQueue.async {
            self.updateCollectionView(byReplacingWithCourses: nil, orByAppendingCourses: courses, orByInsertingCourses: nil, orByDeletingCourses: nil, completion: {
                semaphore.signal()
            })
        }
        
        semaphore.wait()
    }
    
    // MARK: Controls Actions
    
    @objc private func refreshControlTriggered(_ sender: UIRefreshControl) {
        self.refreshControl?.setRefreshing(true)
        self.delegate?.coursesList(list: self, initiateReloadingCoursesWithListType: self.listType)
    }
    
    @IBAction func reloadButtonAction() {
        self.delegate?.coursesList(list: self, initiateReloadingCoursesWithListType: self.listType)
    }
    
    // MARK: Protocols Implementation
    
    // MARK: UIScrollViewDelegate
    
    internal func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.delegate?.coursesList(list: self, didScrollCollectionView: self.collectionView, withListType: self.listType)
    }
    
    // MARK: UICollectionViewDelegate && UICollectionViewDataSource
    
    internal func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let index = indexPath.row
        let course = self.courses[index]
        
        var cell: CourseCollectionViewCell
        
        if let type = self.listType, type == .subscribed {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CourseCollectionViewCellLarge", for: indexPath) as! CourseCollectionViewCell
        } else if let type = self.listType, type == .all {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CourseCollectionViewCellMedium", for: indexPath) as! CourseCollectionViewCell
        } else {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CourseCollectionViewCell", for: indexPath) as! CourseCollectionViewCell
        }
        
        cell.configure(withCourse: course, serverAddress: self.infoPlistService.serverURL(), numberFormatter: self.numberFormatter)
        cell.alpha = 1.0
        cell.contentView.alpha = 1.0
        return cell
    }
    
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        guard let type = self.listType else {
            return 0.0
        }
        
        if type == .subscribed {
            return 24.0
        } else if type == .all {
            return 16.0
        } else {
            return 12.0
        }
    }
    
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        guard let type = self.listType else {
            return 0.0
        }
        
        if type == .subscribed {
            return 24.0
        } else if type == .all {
            return 16.0
        } else {
            return 12.0
        }
    }
    
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        guard let type = self.listType else {
            return UIEdgeInsets.zero
        }
        
        if type == .subscribed {
            return UIEdgeInsets(top: 16.0, left: 0.0, bottom: 0.0, right: 0.0)
        } else if type == .all {
            return UIEdgeInsets(top: 16.0, left: 16.0, bottom: 0.0, right: 16.0)
        } else {
            return UIEdgeInsets(top: 16.0, left: 0.0, bottom: 0.0, right: 0.0)
        }
    }
    
    internal func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if !self.allCoursesLoaded {
            if indexPath.row > self.courses.count * 2 / 3 {
                self.delegate?.coursesList(list: self, initiateLoadingMoreCoursesWithListType: self.listType)
            }
        }
    }
    
    internal func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.courses.count
    }
    
    internal func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let index = indexPath.row
        let course = self.courses[index]
        
        self.courseSelected(course)
    }
    
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var width = collectionView.frame.size.width
        var height: CGFloat = 108.0
        
        if let type = self.listType {
            if type == .subscribed {
                height = ceil(width * 1.0987)
            } else if type == .all {
                width = (width - 16.0 * 3.0) / 2.0
                height = ceil(width * 2.0305)
            }
        }
        
        return CGSize(width: width, height: height)
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
    
    internal func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if let footerView = self.loadingFooterView {
            return footerView
        } else {
            let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "LoadingFooterCollectionReusableView", for: indexPath) as! LoadingFooterCollectionReusableView
            self.loadingFooterView = footerView
            
            if !self.isReloadingCourses && self.isLoadingCourses {
                footerView.setVisible(visible: true)
            } else {
                footerView.setVisible(visible: false)
            }
            
            return footerView
        }
    }
    
    @objc internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.size.width, height: 30.0)
    }

}
