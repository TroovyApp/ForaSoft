//
//  RoundedTextView.swift
//  troovy-ios
//
//  Created by Daniil on 23.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit
import QuartzCore

@IBDesignable class RoundedTextView: PlaceholderTextView {
    
    // MARK: Inspectable Properties
    
    @IBInspectable var cornerRadius: CGFloat = 0.0 {
        didSet {
            self.layer.cornerRadius = self.cornerRadius
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 0.0 {
        didSet {
            self.layer.borderWidth = self.borderWidth
        }
    }
    
    @IBInspectable var borderColor: UIColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1) {
        didSet {
            self.layer.borderColor = self.borderColor.cgColor
        }
    }
    
    // MARK: Init Methods & Superclass Overriders
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        
        self.configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.configure()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        
        self.clipsToBounds = true
        
        self.layer.cornerRadius = self.cornerRadius
        self.layer.borderWidth = self.borderWidth
        self.layer.borderColor = self.borderColor.cgColor
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Private Methods
    
    private func configure() {
        self.clipsToBounds = true
        self.tintColor = self.textColor
        self.tintAdjustmentMode = .normal
    }
    
}

