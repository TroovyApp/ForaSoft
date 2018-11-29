//
//  PlaceholderTextView.swift
//  StepScrollView
//
//  Created by Daniil on 01.12.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

@IBDesignable class PlaceholderTextView: UITextView {
    
    // MARK: Inspectable Properties
    
    @IBInspectable var placeholder: String? = nil {
        didSet {
            self.configurePlaceholder()
        }
    }
    
    @IBInspectable var placeholderColor: UIColor? = nil {
        didSet {
            self.configurePlaceholder()
        }
    }
    
    @IBInspectable var leftRightTextInset: CGFloat = 0.0 {
        didSet {
            self.textContainerInset = UIEdgeInsetsMake(self.textContainerInset.top, self.leftRightTextInset - 4.0, self.textContainerInset.bottom, self.leftRightTextInset - 4.0)
            
            self.setNeedsLayout()
        }
    }
    
    @IBInspectable var topBottomTextInset: CGFloat = 0.0 {
        didSet {
            self.textContainerInset = UIEdgeInsetsMake(self.topBottomTextInset, self.textContainerInset.left, self.topBottomTextInset, self.textContainerInset.right)
            
            self.setNeedsLayout()
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
    
    override var text: String! {
        didSet {
            self.placeholderLabel?.isHidden = !self.text.isEmpty
        }
    }
    
    // MARK: Private Properties
    
    private var placeholderLabel: UILabel?
    
    // MARK: Init Methods & Superclass Overriders
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        
        self.configure()
        self.configureNotifications()
        self.configurePlaceholder()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.configure()
        self.configureNotifications()
        self.configurePlaceholder()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.placeholderLabel?.frame = CGRect(x: self.leftRightTextInset, y: self.topBottomTextInset, width: self.bounds.width - self.leftRightTextInset, height: self.placeholderLabel?.frame.size.height ?? 0.0)
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()

        self.textContainerInset = UIEdgeInsetsMake(self.topBottomTextInset, self.leftRightTextInset, self.topBottomTextInset, self.leftRightTextInset)
        
        self.configurePlaceholder()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Notifications & Observers
    
    @objc private func textView(didChangeWithNotification notification: Notification) {
        guard let object = notification.object as? RoundedTextView else {
            return
        }
        
        if object == self {
            self.placeholderLabel?.isHidden = !self.text.isEmpty
        }
    }
    
    // MARK: Private Methods
    
    private func configure() {
        self.clipsToBounds = true
        self.tintColor = self.textColor
        self.tintAdjustmentMode = .normal
    }
    
    private func configureNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(textView(didChangeWithNotification:)), name: NSNotification.Name.UITextViewTextDidChange, object: self)
    }
    
    private func configurePlaceholder() {
        if let placeholder = self.placeholder, let font = self.font, let textColor = self.textColor {
            if self.placeholderLabel == nil {
                self.placeholderLabel = UILabel(frame: CGRect(x: self.leftRightTextInset, y: self.topBottomTextInset, width: self.bounds.width - self.leftRightTextInset, height: 0.0))
            }
            
            self.placeholderLabel?.isUserInteractionEnabled = false
            self.placeholderLabel!.numberOfLines = 0
            self.placeholderLabel!.isHidden = !self.text.isEmpty
            self.placeholderLabel!.font = font
            self.placeholderLabel!.textColor = (self.placeholderColor ?? textColor.withAlphaComponent(0.4))
            self.placeholderLabel!.text = placeholder
            self.placeholderLabel!.sizeToFit()
            self.addSubview(self.placeholderLabel!)
        } else {
            self.placeholderLabel?.removeFromSuperview()
            self.placeholderLabel = nil
        }
    }
    
}

