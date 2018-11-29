//
//  CourseInfoCollectionViewCell.swift
//  troovy-ios
//
//  Created by Daniil on 28.09.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class CourseInfoCollectionViewCell: UICollectionViewCell {
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var containerView: UIView!
    
    override var bounds: CGRect {
        didSet {
            self.changeLabelsPreferredMaxLayoutWidth()
        }
    }
    
    override var frame: CGRect {
        didSet {
            self.changeLabelsPreferredMaxLayoutWidth()
        }
    }
    
    // MARK: Public Methods
    
    /// Counts content height.
    ///
    /// - returns: Content height.
    ///
    func contentHeight() -> CGFloat {
        self.containerView.updateConstraints()
        self.containerView.layoutIfNeeded()
        
        return self.containerView.frame.height
    }
    
    // MARK: Private Methods
    
    private func changeLabelsPreferredMaxLayoutWidth() {
        if let container = self.containerView?.subviews {
            for view in container {
                if let label = view as? UILabel {
                    label.preferredMaxLayoutWidth = self.frame.width - label.frame.minX * 2.0
                }
            }
        }
    }
    
}
