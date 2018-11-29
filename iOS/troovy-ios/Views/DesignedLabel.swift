//
//  DesignedLabel.swift
//  troovy-ios
//
//  Created by Daniil on 12.10.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

@IBDesignable class DesignedLabel: UILabel {
    
    // MARK: Inspectable Properties

    @IBInspectable var kernValue: CGFloat = 0.0 {
        didSet {
            self.setTitle(self.originalTitleText)
        }
    }
    
    @IBInspectable var lineHeightMultipleValue: CGFloat = 0.0 {
        didSet {
            self.setTitle(self.originalTitleText)
        }
    }
    
    // MARK: Properties Overriders
    
    override public var text: String? {
        didSet {
            self.setTitle(self.text)
        }
    }
    
    // MARK: Private Properties
    
    private var originalTitleText: String?
    
    // MARK: Init Methods & Superclass Overriders
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setTitle(self.text ?? nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setTitle(self.text ?? nil)
    }
    
    // MARK: Private Methods
    
    private func setTitle(_ title: String?) {
        self.originalTitleText = title
        
        if self.lineHeightMultipleValue == 0.0 && self.kernValue == 0.0 {
            super.attributedText = nil
            super.text = title
        } else {
            if let titleString = title {
                var attributes: [NSAttributedStringKey:Any] = [NSAttributedStringKey.font : (self.font ?? UIFont.systemFont(ofSize: 14)),
                                                               NSAttributedStringKey.foregroundColor : self.textColor ?? UIColor.black,
                                                               NSAttributedStringKey.kern : self.kernValue]
                
                if self.lineHeightMultipleValue != 0.0 {
                    let paragraphStyle = NSMutableParagraphStyle()
                    paragraphStyle.alignment = self.textAlignment
                    paragraphStyle.lineHeightMultiple = self.lineHeightMultipleValue
                    paragraphStyle.lineBreakMode = self.lineBreakMode
                    
                    attributes[NSAttributedStringKey.paragraphStyle] = paragraphStyle
                }
                
                super.attributedText = NSAttributedString(string: titleString, attributes: attributes)
            } else {
                super.attributedText = nil
                super.text = nil
            }
        }
    }

}
