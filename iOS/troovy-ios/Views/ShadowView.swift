//
//  ShadowView.swift
//  troovy-ios
//
//  Created by Daniil on 24.10.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit
import QuartzCore

@IBDesignable class ShadowView: UIView {
    
    // MARK: Inspectable Properties
    
    @IBInspectable var fromColor: UIColor? = nil
    @IBInspectable var toColor: UIColor? = nil

    // MARK: Private Properties
    
    private var gradientLayer: CAGradientLayer?
    
    // MARK: Init Methods & Superclass Overriders
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if self.gradientLayer == nil {
            if self.fromColor == nil || self.toColor == nil {
                self.setupBlackGradientShadow(withStartPosition: 0.0)
            } else {
                self.setupGradientShadow(fromColor: self.fromColor!, toColor: self.toColor!)
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.gradientLayer?.frame = self.bounds
    }
    
    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        
        self.gradientLayer?.frame = self.bounds
    }
    
    // MARK: Public Methods
    
    /// Setups shadow with start position.
    ///
    /// - parameter position: Start position of the shadow. From 0.0 to 1.0.
    ///
    func setupBlackGradientShadow(withStartPosition position: Double) {
        if let gradientLayer = self.gradientLayer {
            gradientLayer.removeFromSuperlayer()
        }
        
        self.gradientLayer = CAGradientLayer()
        self.gradientLayer!.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
        self.gradientLayer!.startPoint = CGPoint(x: 0.5, y: 0.0)
        self.gradientLayer!.endPoint = CGPoint(x: 0.5, y: 1.0)
        self.gradientLayer!.frame = self.bounds
        self.gradientLayer!.anchorPoint = CGPoint.zero
        self.gradientLayer!.locations = [NSNumber(value: position), NSNumber(value: 1.0)]
        self.layer.addSublayer(self.gradientLayer!)
    }
    
    /// Setups shadow with colors.
    ///
    /// - parameter fromColor: Gradient start color.
    /// - parameter toColor: Gradient finish color.
    ///
    func setupGradientShadow(fromColor: UIColor, toColor: UIColor) {
        if let gradientLayer = self.gradientLayer {
            gradientLayer.removeFromSuperlayer()
        }
        
        self.gradientLayer = CAGradientLayer()
        self.gradientLayer!.colors = [fromColor.cgColor, toColor.cgColor]
        self.gradientLayer!.startPoint = CGPoint(x: 0.5, y: 0.0)
        self.gradientLayer!.endPoint = CGPoint(x: 0.5, y: 1.0)
        self.gradientLayer!.frame = self.bounds
        self.gradientLayer!.anchorPoint = CGPoint.zero
        self.gradientLayer!.locations = [NSNumber(value: 0.0), NSNumber(value: 1.0)]
        self.layer.addSublayer(self.gradientLayer!)
    }
    
    /// Animates shadow with colors.
    ///
    /// - parameter fromColor: Gradient start color.
    /// - parameter toColor: Gradient finish color.
    ///
    func animateGradientShadow(fromColor: UIColor, toColor: UIColor) {
        if self.gradientLayer != nil {
            self.gradientLayer!.colors = [fromColor.cgColor, toColor.cgColor]
        } else {
            self.setupGradientShadow(fromColor: fromColor, toColor: toColor)
        }
    }

}
