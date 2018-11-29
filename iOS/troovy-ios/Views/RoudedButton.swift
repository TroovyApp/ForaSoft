//
//  RoundedButton.swift
//  troovy-ios
//
//  Created by Daniil on 28.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit
import QuartzCore

@IBDesignable class RoundedButton: UIButton {

    // MARK: Inspectable Properties
    
    @IBInspectable var cornerRadius: CGFloat = 0.0 {
        didSet {
            self.isCircle = (self.cornerRadius == -1.0)
            self.applyRoundedCorners()
        }
    }
    
    @IBInspectable var kernValue: CGFloat = 0.0 {
        didSet {
            self.setTitle(self.originalTitleText, for: .normal)
        }
    }
    
    @IBInspectable var enableShadow: Bool = false {
        didSet {
            if self.enableShadow {
                self.applyShadow()
            } else {
                self.unapplyShadow()
            }
        }
    }
    
    @IBInspectable var shadowRadius: CGFloat = 0.0 {
        didSet {
            self.layer.shadowRadius = self.shadowRadius
        }
    }
    
    @IBInspectable var shadowXOffset: CGFloat = 0.0 {
        didSet {
            self.layer.shadowOffset = CGSize(width: self.shadowXOffset, height: self.shadowYOffset)
        }
    }
    
    @IBInspectable var shadowYOffset: CGFloat = 0.0 {
        didSet {
            self.layer.shadowOffset = CGSize(width: self.shadowXOffset, height: self.shadowYOffset)
        }
    }
    
    @IBInspectable var shadowColor: UIColor = #colorLiteral(red: 0.2431372549, green: 0.2431372549, blue: 0.2823529412, alpha: 1) {
        didSet {
            self.layer.shadowColor = self.shadowColor.cgColor
        }
    }
    
    // MARK: Private Properties
    
    private var isCircle = false
    
    private var originalTitleText: String?
    
    // MARK: Init Methods & Superclass Overriders
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setTitle(self.titleLabel?.text ?? nil, for: .normal)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setTitle(self.titleLabel?.text ?? nil, for: .normal)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.isCircle = (self.cornerRadius == -1.0)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.roundViewIfNeeded()
    }
    
    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        
        self.roundViewIfNeeded()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        
        self.isCircle = (self.cornerRadius == -1.0)
        self.roundViewIfNeeded()
        
        if self.enableShadow {
            self.applyShadow()
        } else {
            self.unapplyShadow()
        }
    }
    
    override func setTitle(_ title: String?, for state: UIControlState) {
        self.originalTitleText = title
        
        if self.kernValue == 0.0 {
            UIView.performWithoutAnimation {
                self.setAttributedTitle(nil, for: state)
                super.setTitle(title, for: state)
                self.layoutIfNeeded()
            }
        } else {
            if let titleString = title {
                let attributes: [NSAttributedStringKey:Any] = [NSAttributedStringKey.font : (self.titleLabel?.font ?? UIFont.systemFont(ofSize: 14)),
                                                               NSAttributedStringKey.foregroundColor : self.titleColor(for: state) ?? UIColor.black,
                                                               NSAttributedStringKey.kern : self.kernValue]
                let attributedTitle = NSAttributedString(string: titleString, attributes: attributes)
                
                UIView.performWithoutAnimation {
                    self.setAttributedTitle(attributedTitle, for: state)
                    self.layoutIfNeeded()
                }
            } else {
                UIView.performWithoutAnimation {
                    super.setTitle(nil, for: state)
                    self.setAttributedTitle(nil, for: state)
                    self.layoutIfNeeded()
                }
            }
        }
    }
    
    override func setTitleColor(_ color: UIColor?, for state: UIControlState) {
        super.setTitleColor(color, for: state)
        
        if let text = self.originalTitleText {
            self.setTitle(text, for: state)
        }
    }

    // MARK: Private Methods
    
    private func roundViewIfNeeded() {
        if self.isCircle {
            self.cornerRadius = self.bounds.height / 2.0
        } else {
            self.applyRoundedCorners()
        }
    }
    
    private func applyShadow() {
        self.layer.shadowColor = self.shadowColor.cgColor
        self.layer.shadowOffset = CGSize(width: self.shadowXOffset, height: self.shadowYOffset)
        self.layer.shadowRadius = self.shadowRadius
        self.layer.shadowOpacity = 1.0
        self.clipsToBounds = false
    }
    
    private func unapplyShadow() {
        self.layer.shadowOffset = CGSize.zero
        self.layer.shadowRadius = 0.0
        self.layer.shadowOpacity = 0.0
    }
    
    private func applyRoundedCorners() {
        if self.cornerRadius > 0.0 {
            let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: [.topLeft, .topRight, .bottomLeft, .bottomRight], cornerRadii: CGSize(width: self.cornerRadius, height: self.cornerRadius))
            
            let maskLayer = CAShapeLayer()
            maskLayer.frame = self.bounds
            maskLayer.path = path.cgPath
            self.layer.mask = maskLayer
        } else {
            self.layer.mask = nil
        }
    }
    
}
