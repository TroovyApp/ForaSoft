//
//  StreamSessionInfoViewController.swift
//  troovy-ios
//
//  Created by Daniil on 20.10.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class StreamSessionInfoViewController: TroovyViewController {

    // MARK: Interface Builder Properties
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var sessionTitleLabel: UILabel!
    @IBOutlet weak var sessionDescriptionLabel: UILabel!
    @IBOutlet weak var sessionStartTimeLabel: UILabel!
    @IBOutlet weak var sessionEndTimeLabel: UILabel!
    @IBOutlet weak var sessionStartDateLabel: UILabel!
    @IBOutlet weak var sessionEndDateLabel: UILabel!
    
    // MARK: Public Properties
    
    /// Course session model.
    var sessionModel: CourseSessionModel!
    
    // MARK: Properties Overriders
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: Private Properties
    
    private var dateFormatter: DateFormatter!
    private var timeFormatter: DateFormatter!
    
    // MARK: Init Methods & Superclass Overriders
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupDateFormatters()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.structSessionInfo()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: Private Methods
    
    private func setupDateFormatters() {
        self.dateFormatter = DateFormatter()
        self.dateFormatter.locale = Locale(identifier: "en_US")
        self.dateFormatter.dateFormat = "d MMM yyyy"
        
        self.timeFormatter = DateFormatter()
        self.timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        self.timeFormatter.dateFormat = "h:mm a"
    }
    
    private func structSessionInfo() {
        self.sessionTitleLabel.text = self.sessionModel.title
        self.sessionDescriptionLabel.text = self.sessionModel.specification
        
        let startDate = Date(timeIntervalSince1970: TimeInterval(self.sessionModel.startTimestamp))
        self.sessionStartTimeLabel.text = self.timeFormatter.string(from: startDate)
        self.sessionStartDateLabel.text = self.dateFormatter.string(from: startDate)
        
        let endDate = Date(timeIntervalSince1970: TimeInterval(self.sessionModel.startTimestamp + Int64(self.sessionModel.duration * 60)))
        self.sessionEndTimeLabel.text = self.timeFormatter.string(from: endDate)
        self.sessionEndDateLabel.text = self.dateFormatter.string(from: endDate)
    }
    
}
