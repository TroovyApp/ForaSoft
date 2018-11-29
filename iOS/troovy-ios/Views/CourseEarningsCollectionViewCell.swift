//
//  CourseEarningsCollectionViewCell.swift
//  troovy-ios
//
//  Created by Daniil on 30.10.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class CourseEarningsCollectionViewCell: CourseInfoCollectionViewCell {
    
    // MARK: Interafce Builder Properties
    
    @IBOutlet weak var earningsLabel: UILabel!
    
    // MARK: Public Methods
    
    /// Configures cell with data.
    ///
    /// - parameter earnings: Course earnings.
    /// - parameter numberFormatter: Number formatter for price.
    ///
    func configure(withEarnings earnings: NSDecimalNumber?, numberFormatter: NumberFormatter, subscribersCount: Int) {
        let earningsTitle = "Earnings "
        let earnings = (earnings != nil ? numberFormatter.string(from: earnings!) : numberFormatter.string(from: 0)) ?? " $??"
        let titleAttributes: [NSAttributedStringKey:Any] = [NSAttributedStringKey.font : self.earningsLabel.font,
                                                            NSAttributedStringKey.foregroundColor : UIColor.white]
        let earningsAttributes: [NSAttributedStringKey:Any] = [NSAttributedStringKey.font : self.earningsLabel.font,
                                                               NSAttributedStringKey.foregroundColor : UIColor.tv_purpleTextColor()]
        
        let subscribersTitle = ", Subscribers: "
        let subscribers = "\(subscribersCount)"
        
        let earningsText = earningsTitle + earnings
        let subscribersText = subscribersTitle + subscribers
        let resultTitle =  earningsText + subscribersText
        let attributedText = NSMutableAttributedString(string: resultTitle, attributes: titleAttributes)
        attributedText.addAttributes(earningsAttributes, range: NSMakeRange(earningsTitle.count, earningsText.count - earningsTitle.count))
        attributedText.addAttributes(earningsAttributes, range: NSMakeRange(earningsText.count + subscribersTitle.count, resultTitle.count - earningsText.count - subscribersTitle.count))
        
        self.earningsLabel.text = nil
        self.earningsLabel.attributedText = attributedText
    }
    
}
