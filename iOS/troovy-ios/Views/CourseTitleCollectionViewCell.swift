//
//  CourseTitleCollectionViewCell.swift
//  troovy-ios
//
//  Created by Daniil on 18.09.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class CourseTitleCollectionViewCell: CourseInfoCollectionViewCell {
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var titleLabel: UILabel!
    
    // MARK: Init Methods & Superclass Overriders
    
    // MARK: Public Methods
    
    /// Configures cell with data.
    ///
    /// - parameter title: Course title.
    ///
    func configure(withTitle title: String) {
        self.titleLabel.attributedText = nil
        self.titleLabel.text = title
    }

}
