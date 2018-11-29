//
//  TicketView.swift
//  troovy-ios
//
//  Created by Daniil on 23.11.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

@IBDesignable class TicketView: UIView {
    
    // MARK: Properties Overriders
    
    override var backgroundColor: UIColor? {
        didSet {
            self.setNeedsDisplay()
        }
    }

    // MARK: Init Methods & Superclass Overriders
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.contentMode = .redraw
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        
        self.setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        UIColor.white.setFill()
        UIRectFill(rect)
        
        let radius: CGFloat = (rect.height / 2.0)
        let dashedLineWidth: CGFloat = rect.width - ((radius + 1.0) * 2.0)
        let numberOfDashes: CGFloat = CGFloat(Int(dashedLineWidth / 7.0))
        let uncoloredDashWidth = (dashedLineWidth - (numberOfDashes * 5.0)) / (numberOfDashes - 1.0)
        
        let context = UIGraphicsGetCurrentContext()
        context?.setBlendMode(.destinationOut)
        context?.setLineWidth(1.0)
        context?.setLineDash(phase: 0, lengths: [5.0, uncoloredDashWidth])
        
        context?.move(to: CGPoint(x: 0.0, y: radius))
        context?.addArc(center: CGPoint(x: 0.0, y: radius), radius: radius, startAngle: CGFloat(Double.pi / 2.0), endAngle: CGFloat(Double.pi), clockwise: true)
        context?.move(to: CGPoint(x: rect.width, y: radius))
        context?.addArc(center: CGPoint(x: rect.width, y: radius), radius: radius, startAngle: CGFloat(Double.pi / 2.0 * 3.0), endAngle: CGFloat(Double.pi * 2.0), clockwise: true)
        context?.fillPath()
        
        context?.move(to: CGPoint(x: (radius + 1.0), y: radius))
        context?.addLine(to: CGPoint(x: (rect.width - radius - 1.0), y: radius))
        context?.strokePath()
        
        context?.setBlendMode(.normal)
    }

}
