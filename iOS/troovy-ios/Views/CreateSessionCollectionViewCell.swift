//
//  CreateSessionCollectionViewCell.swift
//  troovy-ios
//
//  Created by Daniil on 28.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class CreateSessionCollectionViewCell: UICollectionViewCell {
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var dateCircleBottomLine: UIView?
    @IBOutlet weak var createTitleLabel: UILabel!
    
    // MARK: Public Methods
    
    /// Configures cell with passed properties.
    ///
    /// - parameter title: Create label title.
    /// - parameter hasSessions: If course has created sessions.
    ///
    func configure(withTitle title: String, hasSessions: Bool) {
        self.createTitleLabel.text = title
        self.dateCircleBottomLine?.isHidden = !hasSessions
    }

}
