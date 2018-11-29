//
//  RoundedImageView.swift
//  troovy-ios
//
//  Created by Daniil on 12.10.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit
import QuartzCore

class RoundedImageView: UIImageView {

    // MARK: Inspectable Properties
    
    @IBInspectable var topLeftCornersRounded: Bool = true {
        didSet {
            self.applyRoundedCorners()
        }
    }
    
    @IBInspectable var topRightCornersRounded: Bool = true {
        didSet {
            self.applyRoundedCorners()
        }
    }
    
    @IBInspectable var bottomLeftCornersRounded: Bool = true {
        didSet {
            self.applyRoundedCorners()
        }
    }
    
    @IBInspectable var bottomRightCornersRounded: Bool = true {
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
    
    // MARK: Private Properties
    
    private var isCircle = false
    
    // MARK: Init Methods & Superclass Overriders
    
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
    }
    
    // MARK: Private Methods
    
    private func roundViewIfNeeded() {
        if self.isCircle {
            self.cornerRadius = self.bounds.height / 2.0
        } else {
            self.applyRoundedCorners()
        }
    }
    
    private func applyRoundedCorners() {
        var roundedCorner: UIRectCorner?
        if self.topLeftCornersRounded && self.topRightCornersRounded && self.bottomLeftCornersRounded && self.bottomRightCornersRounded {
            roundedCorner = UIRectCorner.allCorners
        } else {
            if self.topLeftCornersRounded && self.topRightCornersRounded {
                roundedCorner = [UIRectCorner.topLeft, UIRectCorner.topRight]
            } else if self.bottomLeftCornersRounded && self.bottomRightCornersRounded {
                roundedCorner = [UIRectCorner.bottomLeft, UIRectCorner.bottomRight]
            } else if self.topLeftCornersRounded && self.bottomLeftCornersRounded {
                roundedCorner = [UIRectCorner.topLeft, UIRectCorner.bottomLeft]
            } else if self.topRightCornersRounded && self.bottomRightCornersRounded {
                roundedCorner = [UIRectCorner.topRight, UIRectCorner.bottomRight]
            }
        }
        
        if let corners = roundedCorner {
            let path = UIBezierPath.init(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: self.cornerRadius, height: self.cornerRadius))
            
            let shapeLayer = CAShapeLayer()
            shapeLayer.backgroundColor = UIColor.clear.cgColor
            shapeLayer.path = path.cgPath
            shapeLayer.frame = self.layer.bounds
            
            self.layer.masksToBounds = true
            self.layer.mask = shapeLayer
        } else {
            self.layer.masksToBounds = false
            self.layer.mask = nil
        }
    }

}
