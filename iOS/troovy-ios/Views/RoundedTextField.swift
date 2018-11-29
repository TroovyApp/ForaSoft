//
//  RoundedTextField.swift
//  troovy-ios
//
//  Created by Daniil on 18.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

@IBDesignable class RoundedTextField: UITextField {
    
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
    
    @IBInspectable var leftTextInset: CGFloat = 0.0 {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    @IBInspectable var leftViewInset: CGFloat = 0.0 {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    @IBInspectable var borderColor: UIColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1) {
        didSet {
            self.layer.borderColor = self.borderColor.cgColor
        }
    }
    
    // MARK: Properties Overriders
    
    override var textColor: UIColor? {
        didSet {
            self.tintColor = self.textColor
            
            self.configurePlaceholder()
        }
    }
    
    override var font: UIFont? {
        didSet {
            self.configurePlaceholder()
        }
    }
    
    // MARK: Init Methods & Superclass Overriders
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.configure()
        self.configurePlaceholder()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.configure()
        self.configurePlaceholder()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        
        self.clipsToBounds = true
        
        self.layer.cornerRadius = self.cornerRadius
        self.layer.borderWidth = self.borderWidth
        self.layer.borderColor = self.borderColor.cgColor
        
        self.configurePlaceholder()
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        var rect = super.textRect(forBounds: bounds)
        rect.origin.x += self.leftTextInset
        rect.size.width -= (self.leftTextInset + self.leftViewInset)
        return rect
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        var rect = super.editingRect(forBounds: bounds)
        rect.origin.x += self.leftTextInset
        rect.size.width -= (self.leftTextInset + self.leftViewInset)
        return rect
    }
    
    override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        var rect = super.leftViewRect(forBounds: bounds)
        rect.size.width = self.leftViewInset
        rect.origin.x = 0.0
        return rect
    }
    
    override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        var rect = super.rightViewRect(forBounds: bounds)
        rect.size.width = 0.0
        rect.origin.x = 0.0
        return rect
    }
    
    // MARK: Private Methods
    
    private func configure() {
        self.clipsToBounds = true
        self.tintColor = self.textColor
        self.tintAdjustmentMode = .normal
    }
    
    private func configurePlaceholder() {
        if let placeholder = self.placeholder, let font = self.font, let textColor = self.textColor {
            let attributes = [NSAttributedStringKey.font : font,
                              NSAttributedStringKey.foregroundColor : textColor.withAlphaComponent(0.4)]
            
            self.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: attributes)
        } else {
            self.attributedPlaceholder = nil
        }
    }

}
