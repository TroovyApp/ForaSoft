//
//  CommonCourseViewController.swift
//  troovy-ios
//
//  Created by Daniil on 29.09.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit
import MessageUI
import Branch

class CommonCourseViewController: CourseInfoViewController, CourseSubscribeCellDelegate {
    
    // MARK: Init Methods & Superclass Overriders

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func thisCourseIsMine() -> Bool {
        return false
    }
    
    override func structCourseInfo() {
        super.structCourseInfo()
        
        self.cellsTypes = []
        
        if let course = self.courseModel {
            if self.verificationService.check(string: course.title) != nil {
                self.cellsTypes += [CourseCellType.title]
            }
            
            if self.verificationService.check(string: course.creatorName) != nil {
                self.cellsTypes += [CourseCellType.subtitle]
            }
            
            if self.verificationService.check(string: course.specification) != nil {
                self.cellsTypes += [CourseCellType.description]
            }
            
            if self.upcomingSessions.count > 0 {
                self.cellsTypes += [CourseCellType.schedule]
                
                self.sessionStartIndex = self.cellsTypes.count
                for _ in self.upcomingSessions {
                    self.cellsTypes += [CourseCellType.sessions]
                }
            }
            
            if course.creatorID != nil && course.creatorID != self.authorisedUserModel?.id && !course.subscribed {
                self.cellsTypes += [CourseCellType.subscribe]
            }
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
        case .subtitle:
            let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "CourseSubtitleCollectionViewCell", for: indexPath) as! CourseSubtitleCollectionViewCell
            if cell.subtitleLabel.text != self.courseModel!.creatorName {
                cell.configure(withUsername: self.courseModel!.creatorName)
                
                let cellHeight = cell.contentHeight()
                self.apply(cellHeight: cellHeight, forCellType: cellType)
            }
            return cell
        case .description:
            let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "CourseDescriptionCollectionViewCell", for: indexPath) as! CourseDescriptionCollectionViewCell
            if cell.descriptionLabel.text != self.courseModel!.specification {
                cell.configure(withDescription: self.courseModel!.specification)
                
                let cellHeight = cell.contentHeight()
                self.apply(cellHeight: cellHeight, forCellType: cellType)
            }
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
            let isFirstSession = (index == 0)
            let isLastSession = ((index + 1) == self.upcomingSessions.count)
            cell.configure(withSession: session, dateMonthFormatter: self.dateMonthFormatter, dateNumberFormatter: self.dateNumberFormatter, dateTimeFormatter: self.dateTimeFormatter, isFirstSession: isFirstSession, isLastSession: isLastSession)
            return cell
        case .subscribe:
            let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "CourseSubscribeCollectionViewCell", for: indexPath) as! CourseSubscribeCollectionViewCell
            if self.cellsHeights[cellType] == nil {
                let cellHeight = cell.contentHeight()
                self.apply(cellHeight: cellHeight, forCellType: cellType)
            }
            
            if self.authorisedUserModel != nil {
                cell.configure(withTitle: ApplicationMessages.ButtonsTitles.subscribe, price: self.courseModel!.price, numberFormatter: self.numberFormatter, delegate: self)
            } else {
                cell.configure(withTitle: ApplicationMessages.ButtonsTitles.register, price: nil, numberFormatter: self.numberFormatter, delegate: self)
            }
            
            return cell
        default:
            fatalError("Cell type doesn't handled")
        }
    }
    
    // MARK: Private Methods
    
    private func shareCourse() {
//        let serverAddress = self.infoPlistService.serverURL()
//        let branchUniversalObject: BranchUniversalObject = BranchUniversalObject(canonicalIdentifier: "course/\(courseID!)")
//        branchUniversalObject.title = courseModel?.title
//        branchUniversalObject.imageUrl = URL.address(byAppendingServerAddress: serverAddress, toContentPath: courseModel?.previewImageURL)?.absoluteString
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
//                                                //NSLog("done showing share sheet!" + activityType!)
//        }
        guard let courseLink = self.courseModel?.webPage else {
            return
        }
        let activityViewController = UIActivityViewController(activityItems: [courseLink], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    private func reportCourse() {
        guard let userModel = self.authorisedUserModel else {
            return
        }
        
        self.router.showReportCourseScreen(withAuthorisedUserModel: userModel, courseID: self.courseID)
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
        
        if self.courseModel?.creatorID != nil && self.authorisedUserModel?.id != nil && self.courseModel?.creatorID != self.authorisedUserModel?.id {
            actionSheetMenu.addAction(UIAlertAction(title: ApplicationMessages.AlertButtonsTitles.reportCourse, style: .default, handler: { [weak self] (action) in
                self?.reportCourse()
            }))
        }
        
        self.present(actionSheetMenu, animated: true, completion: nil)
    }
    
    // MARK: Protocols Implementation
    
    // MARK: CourseSubscribeCellDelegate
    
    internal func courseSubscribeButtonClicked(_ cell: CourseSubscribeCollectionViewCell) {
        guard let course = self.courseModel else {
            return
        }
        
        if let userModel = self.authorisedUserModel {
            self.router.showBuyCourseScreen(withAuthorisedUserModel: userModel, course: course)
        } else {
            self.applicationService.rememberCourseToOpen(courseModel: course, courseID: self.courseID)
            self.exitButtonAction(self.exitButton)
        }
    }

}
