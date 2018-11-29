//
//  CreateCourseSessionsViewController.swift
//  troovy-ios
//
//  Created by Daniil on 23.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class CreateCourseSessionsViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate, SessionCellDelegate {
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var bottomSeparatorView: UIView!
    @IBOutlet weak var instructionsLabel: UILabel!
    
    // MARK: Private Properties
    
    private weak var delegate: CreateCourseDelegate?
    
    private var dateMonthFormatter: DateFormatter!
    private var dateNumberFormatter: DateFormatter!
    private var dateTimeFormatter: DateFormatter!
    
    private var sessions: [CourseSessionModel] = []
    
    private var viewAppeared = false
    
    // MARK: Init Methods & Superclass Overriders
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupDateFormatters()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.configure()
        self.viewAppeared = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.collectionView?.collectionViewLayout.invalidateLayout()
        self.configureSeparatorsStateForScroll()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.viewAppeared = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: Public Methods
    
    /// Configures creation view with course model.
    ///
    /// - parameter delegate: Delegate which responds to CreateCourseDelegate protocol.
    ///
    func configure(withDelegate delegate: CreateCourseDelegate?) {
        self.delegate = delegate
        
        if self.viewAppeared {
            self.configure()
        }
    }
    
    // MARK: Private Methods
    
    private func setupDateFormatters() {
        self.dateMonthFormatter = DateFormatter()
        self.dateMonthFormatter.locale = Locale(identifier: "en_US")
        self.dateMonthFormatter.dateFormat = "MMM"
        
        self.dateNumberFormatter = DateFormatter()
        self.dateNumberFormatter.locale = Locale(identifier: "en_US")
        self.dateNumberFormatter.dateFormat = "d"
        
        self.dateTimeFormatter = DateFormatter()
        self.dateTimeFormatter.locale = Locale(identifier: "en_US_POSIX")
        self.dateTimeFormatter.dateFormat = "h:mm a"
    }
    
    private func configure() {
        guard let unfinishedCourseModel = self.delegate?.currentCourseModel() else {
            return
        }
        
        self.sessions = unfinishedCourseModel.sessions
        self.sessions.sort { (firstSession, secondSession) -> Bool in
            return firstSession.startTimestamp < secondSession.startTimestamp
        }
        
        self.collectionView.reloadData()
        self.configureSeparatorsStateForScroll()
    }
    
    private func configureSeparatorsStateForScroll() {
        self.instructionsLabel.isHidden = (self.sessions.count > 0)
        self.bottomSeparatorView.isHidden = !(collectionView.contentSize.height - collectionView.contentOffset.y - collectionView.bounds.height >= 16.0)
    }
    
    private func deleteSession(atIndex index: Int) {
        guard var unfinishedCourseModel = self.delegate?.currentCourseModel() else {
            return
        }
        
        if index >= 0 && index < self.sessions.count {
            let indexPath = IndexPath(row: index + 1, section: 0)
            self.sessions.remove(at: index)
            self.configureSeparatorsStateForScroll()
            
            unfinishedCourseModel.update(withSessions: self.sessions)
            self.delegate?.coursePage(page: self, didChangeCourseModel: unfinishedCourseModel)
            
            if self.viewAppeared && self.collectionView.visibleCells.count > 0 {
                let firstIndexPath = IndexPath(row: 0, section: 0)
                self.collectionView.performBatchUpdates({
                    self.collectionView.deleteItems(at: [indexPath])
                    self.collectionView.reloadItems(at: [firstIndexPath])
                }, completion: { (success) in
                    self.configureSeparatorsStateForScroll()
                })
            } else {
                self.collectionView.reloadData()
                self.configureSeparatorsStateForScroll()
            }
        }
    }
    
    // MARK: Controls Actions
    
    @IBAction func nextButtonAction(_ sender: UIButton) {
        self.view.endEditing(true)
        
        self.delegate?.coursePageShouldPublishCourse(page: self)
    }
    
    // MARK: Protocols Implementation
    
    // MARK: UIScrollViewDelegate
    
    internal func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.configureSeparatorsStateForScroll()
    }
    
    // MARK: SessionCellDelegate
    
    internal func sessionCell(cell: SessionCollectionViewCell, shouldDeleteSessionWithIdentifier identifier: String) {
        if let index = self.sessions.index(where: {$0.identifier == identifier}) {
            self.deleteSession(atIndex: index)
        }
    }
    
    // MARK: UICollectionViewDelegate && UICollectionViewDataSource
    
    internal func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CreateSessionCollectionViewCell", for: indexPath) as! CreateSessionCollectionViewCell
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SessionCollectionViewCell", for: indexPath) as! SessionCollectionViewCell
            return cell
        }
    }
    
    internal func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let createSessionCell = cell as? CreateSessionCollectionViewCell {
            let hasSessions = (self.sessions.count > 0)
            
            createSessionCell.configure(withTitle: ApplicationMessages.ButtonsTitles.createSession, hasSessions: hasSessions)
        } else if let sessionCell = cell as? SessionCollectionViewCell {
            let index = indexPath.row - 1
            let session = self.sessions[index]
            let isFirstSession = false
            let isLastSession = ((index + 1) == self.sessions.count)
            
            sessionCell.configure(withSession: session, dateMonthFormatter: self.dateMonthFormatter, dateNumberFormatter: self.dateNumberFormatter, dateTimeFormatter: self.dateTimeFormatter, isFirstSession: isFirstSession, isLastSession: isLastSession, delegate: self)
        }
    }
    
    internal func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.sessions.count + 1
    }
    
    internal func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            self.delegate?.coursePage(page: self, shouldOpenSessionModel: nil)
        } else {
            let index = indexPath.row - 1
            let session = self.sessions[index]
            
            self.delegate?.coursePage(page: self, shouldOpenSessionModel: session)
        }
    }
    
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.size.width
        let height: CGFloat = 82.0
        
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

}
