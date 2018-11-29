//
//  CourseDescriptionCollectionViewCell.swift
//  troovy-ios
//
//  Created by Daniil on 18.09.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class CourseDescriptionCollectionViewCell: CourseInfoCollectionViewCell {

    // MARK: Interface Builder Properties
    
    @IBOutlet weak var descriptionLabel: UILabel!
    
    // MARK: Public Methods
    
    /// Configures cell with data.
    ///
    /// - parameter description: Course description.
    ///
    func configure(withDescription description: String) {
        self.descriptionLabel.text = description
    }
    
    /// Sets alpha for description label.
    ///
    /// - properties alpha: Alpha value.
    ///
    func setDescriptionAlpha(_ alpha: CGFloat) {
        self.descriptionLabel.alpha = alpha
    }

}
