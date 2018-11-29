//
//  CourseSessionCollectionViewCell.swift
//  troovy-ios
//
//  Created by Daniil on 24.10.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class CourseSessionCollectionViewCell: CourseInfoCollectionViewCell {
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var dateCircleTopLine: UIView!
    @IBOutlet weak var dateCircleBottomLine: UIView!
    
    @IBOutlet weak var sessionMonthLabel: UILabel!
    @IBOutlet weak var sessionNumberLabel: UILabel!
    @IBOutlet weak var sessionTimeLabel: UILabel!
    @IBOutlet weak var sessionTitleLabel: UILabel!
    
    // MARK: Public Methods
    
    /// Configures cell with passed properties.
    ///
    /// - parameter session: Course session model.
    /// - parameter dateMonthFormatter: Date formatter for month string.
    /// - parameter dateNumberFormatter: Date formatter for number string.
    /// - parameter dateTimeFormatter: Date formatter for time string.
    /// - parameter isFirstSession: If the session first in the list.
    /// - parameter isLastSession: If the session last in the list.
    ///
    func configure(withSession session: CourseSessionModel, dateMonthFormatter: DateFormatter, dateNumberFormatter: DateFormatter, dateTimeFormatter: DateFormatter, isFirstSession: Bool, isLastSession: Bool) {
        if let startTimeInterval = TimeInterval(exactly: session.startTimestamp), let endTimeInterval = TimeInterval(exactly: (session.startTimestamp + Int64(session.duration * 60))) {
            let sessionStartDate = Date(timeIntervalSince1970: startTimeInterval)
            let sessionEndDate = Date(timeIntervalSince1970: endTimeInterval)
            
            self.sessionMonthLabel.text = dateMonthFormatter.string(from: sessionStartDate)
            self.sessionNumberLabel.text = dateNumberFormatter.string(from: sessionStartDate)
            self.sessionTimeLabel.text = (dateTimeFormatter.string(from: sessionStartDate) + " - " + dateTimeFormatter.string(from: sessionEndDate)).uppercased()
            self.sessionTitleLabel.text = session.title
        } else {
            self.sessionMonthLabel.text = "??"
            self.sessionNumberLabel.text = "???"
            self.sessionTimeLabel.text = "??:?? - ??:??"
            self.sessionTitleLabel.text = "Unknown session"
        }
        
        self.dateCircleTopLine.isHidden = isFirstSession
        self.dateCircleBottomLine.isHidden = isLastSession
    }
    
}
