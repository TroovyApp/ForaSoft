//
//  HintCollectionViewCell.swift
//  troovy-ios
//
//  Created by Daniil on 05.12.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class HintCollectionViewCell: UICollectionViewCell {
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var hintLabel: UILabel!
    
    // MARK: Public Methods
    
    /// Configures cell with passed properties.
    ///
    /// - parameter text: Hint text.
    ///
    func configure(withHintText text: String) {
        self.hintLabel.text = text
    }
    
}
