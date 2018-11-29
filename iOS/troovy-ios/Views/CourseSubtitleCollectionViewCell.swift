//
//  CourseSubtitleCollectionViewCell.swift
//  troovy-ios
//
//  Created by Daniil on 09.10.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class CourseSubtitleCollectionViewCell: CourseInfoCollectionViewCell {
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var subtitleLabel: UILabel!
    
    // MARK: Init Methods & Superclass Overriders
    
    // MARK: Public Methods
    
    /// Configures cell with data.
    ///
    /// - parameter username: Course creator's username.
    ///
    func configure(withUsername username: String?) {
        let name = username ?? "Unknown"
        let subtitleAttributes: [NSAttributedStringKey:Any] = [NSAttributedStringKey.font : self.subtitleLabel.font,
                                                               NSAttributedStringKey.foregroundColor : UIColor.white]
        let usernameAttributes: [NSAttributedStringKey:Any] = [NSAttributedStringKey.font : self.subtitleLabel.font,
                                                               NSAttributedStringKey.foregroundColor : UIColor.tv_purpleTextColor()]
        
        let subtitle = "By "
        let subtitleUsername = subtitle + name
        let attributedText = NSMutableAttributedString(string: subtitleUsername, attributes: subtitleAttributes)
        attributedText.addAttributes(usernameAttributes, range: NSMakeRange(subtitle.count, subtitleUsername.count - subtitle.count))
        
        self.subtitleLabel.text = nil
        self.subtitleLabel.attributedText = attributedText
    }
    
}
