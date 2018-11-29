//
//  CourseScheduleCollectionViewCell.swift
//  troovy-ios
//
//  Created by Daniil on 24.10.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class CourseScheduleCollectionViewCell: CourseInfoCollectionViewCell {
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var scheduleTitleLabel: UILabel!
    
    // MARK: Public Methods
    
    /// Configures cell with data.
    ///
    /// - parameter title: Schedule title label.
    ///
    func configure(withScheduleTitle title: String) {
        self.scheduleTitleLabel.text = title
    }
    
}
