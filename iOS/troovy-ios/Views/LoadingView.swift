//
//  RoundedLabel.swift
//  troovy-ios
//
//  Created by Daniil on 18.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class LoadingView: UIView {
    
    // MARK: Private Properties
    
    private var activityIndicatorContainer: UIView!
    private var activityIndicator: UIActivityIndicatorView!

    // MARK: Init Methods & Superclass Overriders
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setupActivityIndicator()
        self.backgroundColor = UIColor.init(white: 0.0, alpha: 0.4)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Private Methods
    
    private func setupActivityIndicator() {
        var layoutConstraints: [NSLayoutConstraint] = []
        
        self.activityIndicatorContainer = UIView.init(frame: CGRect(x: self.bounds.width / 2.0 - 35.0, y: self.bounds.height / 2.0 - 35.0, width: 70.0, height: 70.0))
        self.activityIndicatorContainer.translatesAutoresizingMaskIntoConstraints = false
        self.activityIndicatorContainer.backgroundColor = UIColor.clear
        self.addSubview(self.activityIndicatorContainer)
        
        self.activityIndicator = UIActivityIndicatorView.init(activityIndicatorStyle: .whiteLarge)
        self.activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.activityIndicator.color = UIColor.white
        self.activityIndicator.startAnimating()
        self.addSubview(self.activityIndicator)
        
        layoutConstraints.append(NSLayoutConstraint.init(item: self.activityIndicator, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0.0))
        layoutConstraints.append(NSLayoutConstraint.init(item: self.activityIndicator, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0.0))
        
        layoutConstraints.append(NSLayoutConstraint.init(item: self.activityIndicatorContainer, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0.0))
        layoutConstraints.append(NSLayoutConstraint.init(item: self.activityIndicatorContainer, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0.0))
        layoutConstraints.append(NSLayoutConstraint.init(item: self.activityIndicatorContainer, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 70.0))
        layoutConstraints.append(NSLayoutConstraint.init(item: self.activityIndicatorContainer, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 70.0))
        
        NSLayoutConstraint.activate(layoutConstraints)
        
        self.updateConstraints()
        self.layoutIfNeeded()
    }

}
