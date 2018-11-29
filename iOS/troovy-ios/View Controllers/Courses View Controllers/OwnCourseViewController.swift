//
//  OwnCourseViewController.swift
//  troovy-ios
//
//  Created by Daniil on 29.09.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit
import Branch

class OwnCourseViewController: CourseInfoViewController, CourseAttachmentsCellDelegate {
    
    // MARK: Init Methods & Superclass Overriders

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func thisCourseIsMine() -> Bool {
        return true
    }
    
    override func structCourseInfo() {
        super.structCourseInfo()
        
        self.cellsTypes = []
        
        if let course = self.courseModel {
            if self.verificationService.check(string: course.title) != nil {
                self.cellsTypes += [CourseCellType.title]
            }
            
            self.cellsTypes += [CourseCellType.earnings]
            
            if self.verificationService.check(string: course.specification) != nil {
                self.cellsTypes += [CourseCellType.description]
            }
            
            self.cellsTypes += [CourseCellType.schedule]
            self.cellsTypes += [CourseCellType.createSession]
            
            if self.upcomingSessions.count > 0 {
                self.sessionStartIndex = self.cellsTypes.count
                for _ in self.upcomingSessions {
                    self.cellsTypes += [CourseCellType.sessions]
                }
            }
            
            self.cellsTypes += [CourseCellType.attachments]
        }
        
        self.collectionView.reloadData()
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellType = self.cellsTypes[indexPath.row]
        switch cellType {
        case .title:
            let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "CourseTitleCollectionViewCell", for: indexPath) as! CourseTitleCollectionViewCell
            if cell.titleLabel.text != self.courseModel!.title {
                cell.configure(withTitle: self.courseModel!.title)
                
                let cellHeight = cell.contentHeight()
                self.apply(cellHeight: cellHeight, forCellType: cellType)
            }
            return cell
        case .earnings:
            let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "CourseEarningsCollectionViewCell", for: indexPath) as! CourseEarningsCollectionViewCell
            if self.cellsHeights[cellType] == nil {
                let cellHeight = cell.contentHeight()
                self.apply(cellHeight: cellHeight, forCellType: cellType)
            }
            cell.configure(withEarnings: self.courseModel!.earnings, numberFormatter: self.numberFormatter, subscribersCount: self.courseModel!.subscribersCount)
            return cell
        case .description:
            let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "CourseDescriptionCollectionViewCell", for: indexPath) as! CourseDescriptionCollectionViewCell
            if cell.descriptionLabel.text != self.courseModel!.specification {
                cell.configure(withDescription: self.courseModel!.specification)
                
                let cellHeight = cell.contentHeight()
                self.apply(cellHeight: cellHeight, forCellType: cellType)
            }
            return cell
        case .createSession:
            let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "CourseCreateSessionCollectionViewCell", for: indexPath) as! CourseCreateSessionCollectionViewCell
            if self.cellsHeights[cellType] == nil {
                let cellHeight = cell.contentHeight()
                self.apply(cellHeight: cellHeight, forCellType: cellType)
            }
            let hasSessions = (self.upcomingSessions.count > 0)
            cell.configure(withTitle: ApplicationMessages.ButtonsTitles.createSession, hasSessions: hasSessions)
            return cell
        case .schedule:
            let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "CourseScheduleCollectionViewCell", for: indexPath) as! CourseScheduleCollectionViewCell
            if self.cellsHeights[cellType] == nil {
                let cellHeight = cell.contentHeight()
                self.apply(cellHeight: cellHeight, forCellType: cellType)
            }
            cell.configure(withScheduleTitle: ApplicationMessages.Instructions.courseSchedule)
            return cell
        case .sessions:
            let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "CourseSessionCollectionViewCell", for: indexPath) as! CourseSessionCollectionViewCell
            if self.cellsHeights[cellType] == nil {
                let cellHeight = cell.contentHeight()
                self.apply(cellHeight: cellHeight, forCellType: cellType)
            }
            let index = indexPath.row - self.sessionStartIndex
            let session = self.upcomingSessions[index]
            let isFirstSession = false
            let isLastSession = ((index + 1) == self.upcomingSessions.count)
            cell.configure(withSession: session, dateMonthFormatter: self.dateMonthFormatter, dateNumberFormatter: self.dateNumberFormatter, dateTimeFormatter: self.dateTimeFormatter, isFirstSession: isFirstSession, isLastSession: isLastSession)
            return cell
        case .attachments:
            let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "CourseAttachmentsCollectionViewCell", for: indexPath) as! CourseAttachmentsCollectionViewCell
            if self.cellsHeights[cellType] == nil {
                let cellHeight = cell.contentHeight()
                self.apply(cellHeight: cellHeight, forCellType: cellType)
            }
            cell.configure(withTitle: ApplicationMessages.ButtonsTitles.attachments, delegate: self)
            return cell
        default:
            fatalError("Cell type doesn't handled")
        }
    }
    
    // MARK: Private Methods
    
    private func shareCourse() {
//        let branchUniversalObject: BranchUniversalObject = BranchUniversalObject(canonicalIdentifier: "course/\(courseID!)")
//        branchUniversalObject.title = courseModel?.title
//        branchUniversalObject.imageUrl = courseModel?.imageSharingURL
//        branchUniversalObject.contentDescription = courseModel?.specification
//        branchUniversalObject.contentMetadata.contentSchema = BranchContentSchema.commerceProduct
//        branchUniversalObject.contentMetadata.customMetadata["courseId"] = courseID
//
//        let linkProperties: BranchLinkProperties = BranchLinkProperties()
//        linkProperties.feature = "sharing"
//
//        branchUniversalObject.showShareSheet(with: linkProperties,
//                                             andShareText: "Check out this workshop!",
//                                             from: self) { (activityType, completed) in
//        }
        
        guard let courseLink = self.courseModel?.webPage else {
            return
        }
        let activityViewController = UIActivityViewController(activityItems: [courseLink], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    private func editCourse() {
        guard let course = self.courseModel, let userModel = self.authorisedUserModel else {
            return
        }
        
        self.router.showEditCourseScreen(withAuthorisedUserModel: userModel, courseModel: course)
    }
    
    // MARK: Controls Actions
    
    @IBAction func actionsButtonAction(_ sender: UIButton) {
        let actionSheetMenu = UIAlertController(title: ApplicationMessages.AlertTitles.chooseAction, message: nil, preferredStyle: .actionSheet)
        actionSheetMenu.addAction(UIAlertAction(title: ApplicationMessages.AlertButtonsTitles.close, style: .cancel, handler: nil))
        
        if self.courseModel?.webPage != nil && !(self.courseModel?.webPage?.isEmpty ?? true) {
            actionSheetMenu.addAction(UIAlertAction(title: ApplicationMessages.AlertButtonsTitles.shareCourse, style: .default, handler: { [weak self] (action) in
                self?.shareCourse()
            }))
        }
        
        actionSheetMenu.addAction(UIAlertAction(title: ApplicationMessages.AlertButtonsTitles.editCourse, style: .default, handler: { [weak self] (action) in
            self?.editCourse()
        }))
        
        actionSheetMenu.addAction(UIAlertAction(title: ApplicationMessages.AlertButtonsTitles.deleteCourse, style: .default, handler: { [weak self] (action) in
            self?.deleteCourse(ignoreSubscribers: false)
        }))
        
        self.present(actionSheetMenu, animated: true, completion: nil)
    }
    
    // MARK: Protocols Implementation
    
    // MARK: CourseAttachmentsCellDelegate
    
    internal func courseAttachmentsButtonClicked(_ cell: CourseAttachmentsCollectionViewCell) {
        guard let course = self.courseModel, let userModel = self.authorisedUserModel  else {
            return
        }
        
        self.router.showCourseAttachmentsScreen(withAuthorisedUserModel: userModel, courseModel: course)
    }

}
