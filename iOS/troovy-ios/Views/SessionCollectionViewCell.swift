//
//  SessionCollectionViewCell.swift
//  troovy-ios
//
//  Created by Daniil on 28.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

@objc protocol SessionCellDelegate: class {
    @objc optional func sessionCell(cell: SessionCollectionViewCell, shouldDeleteSessionWithIdentifier identifier: String)
    @objc optional func sessionCell(cell: SessionCollectionViewCell, shouldEnterSessionWithID sessionID: String)
    @objc optional func sessionCell(cell: SessionCollectionViewCell, sessionEnterMinutesLeftForSessionWithID sessionID: String) -> Int
    @objc optional func sessionCell(cell: SessionCollectionViewCell, sessionBecomeReadyForEnterWithID sessionID: String)
    @objc optional func sessionCell(cell: SessionCollectionViewCell, sessionBecomeOutdatedWithID sessionID: String)
}

class SessionCollectionViewCell: UICollectionViewCell, SessionModelDelegate {

    // MARK: Interface Builder Properties
    
    @IBOutlet weak var sessionMonthLabel: UILabel!
    @IBOutlet weak var sessionNumberLabel: UILabel!
    @IBOutlet weak var sessionTimeLabel: UILabel!
    @IBOutlet weak var sessionTitleLabel: UILabel!
    @IBOutlet weak var sessionTimeLeftLabel: UILabel?
    
    @IBOutlet weak var enterButton: UIButton?
    @IBOutlet weak var deleteButton: UIButton?
    
    @IBOutlet weak var dateCircleTopLine: UIView?
    @IBOutlet weak var dateCircleBottomLine: UIView?
    
    // MARK: Private Methods
    
    private weak var delegate: SessionCellDelegate?
    
    private var sessionID: String?
    private var sessionIdentifier: String!
    private var sessionStartDate: Date?
    private var sessionEndDate: Date?
    private var sessionStartTimestamp: Int64!
    private var sessionDurationInSeconds: Int64!
    private var isFirstSession = true
    private var isLastSession = true
    
    private var timeUpdateTime: Timer?
    
    private var dateMonthFormatter: DateFormatter?
    private var dateNumberFormatter: DateFormatter?
    private var dateTimeFormatter: DateFormatter?
    
    private var sessionModel: CourseSessionModel? {
        willSet {
            self.sessionModel?.removeDelegate(self)
        }
        didSet {
            self.sessionModel?.delegate = self
        }
    }
    
    // MARK: Init Methods & Superclass Overriders
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(_:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        
        self.stopTimeUpdateTimer()
    }
    
    // MARK: Notifications & Observers
    
    @objc private func applicationDidBecomeActive(_ notification: Notification) {
        self.checkDates()
    }
    
    // MARK: Public Methods
    
    /// Configures cell with passed properties.
    ///
    /// - parameter session: Course session model.
    /// - parameter dateMonthFormatter: Date formatter for month string.
    /// - parameter dateNumberFormatter: Date formatter for number string.
    /// - parameter dateTimeFormatter: Date formatter for time string.
    /// - parameter isFirstSession: If the session first in the list.
    /// - parameter isLastSession: If the session last in the list.
    /// - parameter delegate: Delegate. Responds to SessionCellDelegate.
    ///
    func configure(withSession session: CourseSessionModel, dateMonthFormatter: DateFormatter, dateNumberFormatter: DateFormatter, dateTimeFormatter: DateFormatter, isFirstSession: Bool, isLastSession: Bool, delegate: SessionCellDelegate?) {
        self.isFirstSession = isFirstSession
        self.isLastSession = isLastSession
        
        self.configure(withSession: session, dateMonthFormatter: dateMonthFormatter, dateNumberFormatter: dateNumberFormatter, dateTimeFormatter: dateTimeFormatter, delegate: delegate)
    }
    
    /// Configures cell with passed properties.
    ///
    /// - parameter session: Course session model.
    /// - parameter dateMonthFormatter: Date formatter for month string.
    /// - parameter dateNumberFormatter: Date formatter for number string.
    /// - parameter dateTimeFormatter: Date formatter for time string.
    /// - parameter delegate: Delegate. Responds to SessionCellDelegate.
    ///
    func configure(withSession session: CourseSessionModel, dateMonthFormatter: DateFormatter, dateNumberFormatter: DateFormatter, dateTimeFormatter: DateFormatter, delegate: SessionCellDelegate?) {
        self.delegate = delegate
        self.sessionModel = session
        self.sessionID = session.id
        self.sessionIdentifier = session.identifier
        self.sessionStartTimestamp = session.startTimestamp
        self.sessionDurationInSeconds = Int64(session.duration * 60)
        self.dateMonthFormatter = dateMonthFormatter
        self.dateNumberFormatter = dateNumberFormatter
        self.dateTimeFormatter = dateTimeFormatter
        
        self.structSession()
    }
    
    // MARK: Private Methods
    
    private func structSession() {
        guard let session = self.sessionModel else {
            return
        }
        
        if let startTimeInterval = TimeInterval(exactly: session.startTimestamp), let endTimeInterval = TimeInterval(exactly: (session.startTimestamp + Int64(session.duration * 60))) {
            let sessionStartDate = Date(timeIntervalSince1970: startTimeInterval)
            let sessionEndDate = Date(timeIntervalSince1970: endTimeInterval)
            let fromTime = (self.dateTimeFormatter?.string(from: sessionStartDate) ?? "")
            let toTime =  (self.dateTimeFormatter?.string(from: sessionEndDate) ?? "")
            
            self.sessionStartDate = sessionStartDate
            self.sessionEndDate = sessionEndDate
            self.sessionMonthLabel.text = self.dateMonthFormatter?.string(from: sessionStartDate)
            self.sessionNumberLabel.text = self.dateNumberFormatter?.string(from: sessionStartDate)
            self.sessionTimeLabel.text = (fromTime + " - " + toTime).uppercased()
            self.sessionTitleLabel.text = session.title
            self.sessionTimeLeftLabel?.text = nil
        } else {
            self.sessionStartDate = nil
            self.sessionEndDate = nil
            self.sessionMonthLabel.text = "??"
            self.sessionNumberLabel.text = "???"
            self.sessionTimeLabel.text = "??:?? - ??:??"
            self.sessionTitleLabel.text = "Unknown session"
            self.sessionTimeLeftLabel?.text = nil
        }
        
        self.dateCircleTopLine?.isHidden = self.isFirstSession
        self.dateCircleBottomLine?.isHidden = self.isLastSession
        
        self.checkDates()
        self.startTimeUpdateTimer()
    }
    
    private func startTimeUpdateTimer() {
        if self.timeUpdateTime != nil {
            return
        }
        
        self.timeUpdateTime = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] (timer) in
            DispatchQueue.main.async {
                self?.checkDates()
            }
        })
    }
    
    private func stopTimeUpdateTimer() {
        self.timeUpdateTime?.invalidate()
        self.timeUpdateTime = nil
    }
    
    private func checkDates() {
        if self.sessionModel == nil || self.sessionID == nil || self.sessionStartDate == nil || self.sessionEndDate == nil {
            return
        }
        
        let currentDate = Date()
        let currentTimestamp = Int64(currentDate.timeIntervalSince1970)
        
        let timeLeft = Int(self.sessionStartTimestamp - currentTimestamp)
        if timeLeft > 0 {
            if timeLeft >= 60 {
                let minutesLeft = Int(ceil(Double(timeLeft) / 60.0))
                self.sessionTimeLeftLabel?.text = "Starts in \(minutesLeft) min"
            } else {
                self.sessionTimeLeftLabel?.text = "Starts in \(timeLeft) sec"
            }
        } else {
            self.sessionTimeLeftLabel?.text = "Already started"
        }
        
        if self.enterButton == nil {
            if let id = self.sessionID, let sessionEnterMinutesLeft = self.delegate?.sessionCell?(cell: self, sessionEnterMinutesLeftForSessionWithID: id) {
                if (self.sessionStartTimestamp - currentTimestamp) <= (sessionEnterMinutesLeft * 60) && (self.sessionStartTimestamp + self.sessionDurationInSeconds) >= currentTimestamp  {
                    self.stopTimeUpdateTimer()
                    self.delegate?.sessionCell?(cell: self, sessionBecomeReadyForEnterWithID: id)
                    return
                }
            }
        }
        
        if self.enterButton != nil {
            if let id = self.sessionID {
                if (self.sessionStartTimestamp + self.sessionDurationInSeconds) < currentTimestamp {
                    self.stopTimeUpdateTimer()
                    self.delegate?.sessionCell?(cell: self, sessionBecomeOutdatedWithID: id)
                    return
                }
            }
        }
    }
    
    // MARK: Controls Actions
    
    @IBAction func deleteButtonAction(_ sender: UIButton) {
        self.delegate?.sessionCell?(cell: self, shouldDeleteSessionWithIdentifier: self.sessionIdentifier)
    }
    
    @IBAction func enterButtonAction(_ sender: UIButton) {
        if let id = self.sessionID {
            self.delegate?.sessionCell?(cell: self, shouldEnterSessionWithID: id)
        }
    }
    
    // MARK: Protocols Implementation
    
    // MARK: SessionModelDelegate
    
    internal func sessionChagned(session: CourseSessionModel) {
        if (session.id != nil && self.sessionModel?.id == session.id) || (session.id == nil && self.sessionModel?.identifier == session.identifier) {
            self.structSession()
        }
    }

}
