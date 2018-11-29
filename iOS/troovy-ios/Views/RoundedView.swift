//
//  RoundedView.swift
//  troovy-ios
//
//  Created by Daniil on 18.09.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit
import QuartzCore

@IBDesignable class RoundedView: UIView {
    
    // MARK: Inspectable Properties
    
    @IBInspectable var topCornersRounded: Bool = true {
        didSet {
            self.applyRoundedCorners()
        }
    }
    
    @IBInspectable var bottomCornersRounded: Bool = true {
        didSet {
            self.applyRoundedCorners()
        }
    }
    
    @IBInspectable var onlyRightCornersRounded: Bool = false {
        didSet {
            self.applyRoundedCorners()
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat = 0.0 {
        didSet {
            self.isCircle = (self.cornerRadius == -1.0)
            self.applyRoundedCorners()
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
    
    // MARK: Init Methods & Superclass Overriders
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.isCircle = (self.topCornersRounded && self.bottomCornersRounded && !self.onlyRightCornersRounded && self.cornerRadius == -1.0)
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
        
        self.isCircle = (self.topCornersRounded && self.bottomCornersRounded && !self.onlyRightCornersRounded && self.cornerRadius == -1.0)
        self.roundViewIfNeeded()
        
        if self.enableShadow {
            self.applyShadow()
        } else {
            self.unapplyShadow()
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
        if (self.topCornersRounded || self.bottomCornersRounded || self.onlyRightCornersRounded) && self.cornerRadius > 0.0 {
            var roundedCorner = UIRectCorner.allCorners
            if self.onlyRightCornersRounded {
                if self.topCornersRounded && !self.bottomCornersRounded {
                    roundedCorner = [UIRectCorner.topRight]
                } else if !self.topCornersRounded && self.bottomCornersRounded  {
                    roundedCorner = [UIRectCorner.bottomRight]
                } else {
                    roundedCorner = [UIRectCorner.topRight, UIRectCorner.bottomRight]
                }
            } else {
                if self.topCornersRounded && !self.bottomCornersRounded {
                    roundedCorner = [UIRectCorner.topLeft, UIRectCorner.topRight]
                } else if !self.topCornersRounded && self.bottomCornersRounded  {
                    roundedCorner = [UIRectCorner.bottomLeft, UIRectCorner.bottomRight]
                }
            }
            
            let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: roundedCorner, cornerRadii: CGSize(width: self.cornerRadius, height: self.cornerRadius))
            
            let maskLayer = CAShapeLayer()
            maskLayer.frame = self.bounds
            maskLayer.path = path.cgPath
            self.layer.mask = maskLayer
        } else {
            self.layer.mask = nil
        }
    }
    
}

