//
//  LoadingFooterCollectionReusableView.swift
//  troovy-ios
//
//  Created by Daniil on 30.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class LoadingFooterCollectionReusableView: UICollectionReusableView {
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var footerLabel: UILabel!
    
    // MARK: Public Methods
    
    /// Determines if should be content visible.
    ///
    /// - parameter visible: True for showing content or false otherwise.
    ///
    func setVisible(visible: Bool) {
        self.footerLabel.isHidden = !visible
    }
    
}
