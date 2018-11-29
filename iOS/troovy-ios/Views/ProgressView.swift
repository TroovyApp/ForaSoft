//
//  ProgressView.swift
//  troovy-ios
//
//  Created by Daniil on 25.09.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

@IBDesignable  class ProgressView: UIView {
    
    // MARK: Inspectable Properties
    
    @IBInspectable var progressColor: UIColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
    
    // MARK: Private Properties
    
    private let progressView = UIView()
    
    // MARK: Public Properties
    
    var progress: CGFloat = 0.0 {
        didSet {
            if self.progress < 0 {
                self.progress = 0.0
            } else if self.progress > 1 {
                self.progress = 1.0
            }
            
            self.animateProgress()
        }
    }
    
    // MARK: Init Methods & Superclass Overriders
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.progressView.frame = CGRect(x: 0.0, y: 0.0, width: self.bounds.width * self.progress, height: self.bounds.height)
        self.progressView.backgroundColor = .clear
        self.progressView.clipsToBounds = true
        self.progressView.layer.cornerRadius = (self.bounds.height / 2.0)
        self.progressView.layer.backgroundColor = self.progressColor.cgColor
        self.addSubview(self.progressView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.progressView.frame = CGRect(x: 0.0, y: 0.0, width: self.bounds.width * self.progress, height: self.bounds.height)
        self.progressView.layer.cornerRadius = (self.bounds.height / 2.0)
    }
    
    // MARK: Private Methods
    
    private func animateProgress() {
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .beginFromCurrentState, animations: {
            self.progressView.frame = CGRect(x: 0.0, y: 0.0, width: self.bounds.width * self.progress, height: self.bounds.height)
            self.progressView.layer.backgroundColor = self.progressColor.cgColor
        }, completion: nil)
    }

}
