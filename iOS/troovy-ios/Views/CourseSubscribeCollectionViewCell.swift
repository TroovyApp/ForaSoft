//
//  CourseSubscribeCollectionViewCell.swift
//  troovy-ios
//
//  Created by Daniil on 24.10.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

protocol CourseSubscribeCellDelegate: class {
    func courseSubscribeButtonClicked(_ cell: CourseSubscribeCollectionViewCell)
}

class CourseSubscribeCollectionViewCell: CourseInfoCollectionViewCell {
    
    // MARK: Interafce Builder Properties
    
    @IBOutlet weak var subscribeButton: UIButton!
    
    // MARK: Private Properties
    
    private weak var delegate: CourseSubscribeCellDelegate?
    
    // MARK: Public Methods
    
    /// Configures cell with data.
    ///
    /// - parameter title: Subscribe button title.
    /// - parameter price: Course price.
    /// - parameter numberFormatter: Number formatter for price.
    /// - parameter delegate: Delegate. Responds to CourseSubscribeCellDelegate protocol.
    ///
    func configure(withTitle title: String, price: NSDecimalNumber?, numberFormatter: NumberFormatter, delegate: CourseSubscribeCellDelegate?) {
        let font = self.subscribeButton.titleLabel?.font ?? UIFont.systemFont(ofSize: 14.0)
        let textColor = self.subscribeButton.titleLabel?.textColor ?? UIColor.white
        let titleAttributes = [NSAttributedStringKey.font : font,
                               NSAttributedStringKey.foregroundColor : textColor]
        let priceAttributes = [NSAttributedStringKey.font : font,
                               NSAttributedStringKey.foregroundColor : textColor.withAlphaComponent(0.7)]
        
        if let priceValue = price, let priceString = numberFormatter.string(from: priceValue) {
            let string = title + " " + priceString
            let attributedTitle = NSMutableAttributedString(string: string, attributes: titleAttributes)
            attributedTitle.addAttributes(priceAttributes, range: NSMakeRange(string.count - priceString.count, priceString.count))
            
            self.subscribeButton.setAttributedTitle(attributedTitle, for: .normal)
        } else {
            let attributedTitle = NSAttributedString(string: title, attributes: titleAttributes)
            
            self.subscribeButton.setAttributedTitle(attributedTitle, for: .normal)
        }
        
        self.delegate = delegate
    }
    
    // MARK: Controls Actions
    
    @IBAction func subscribeButtonAction(_ sender: UIButton) {
        self.delegate?.courseSubscribeButtonClicked(self)
    }
    
}
