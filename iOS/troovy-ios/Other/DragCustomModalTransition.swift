//
//  DragCustomModalTransition.swift
//  troovy-ios
//
//  Created by Daniil on 15.12.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

final class DragCustomModalTransition: CustomModalTransition {
    
    // MARK: Private Properties
    
    private let animationDuration: TimeInterval = 0.3
    
    // MARK: Init Methods & Superclass Overriders
    
    override init() {
        super.init(duration: animationDuration)
    }
    
    // MARK: Private Methods
    
    private func performTransition(interactive: Bool) {
        let isPresenting = self.isPresenting
        let offscreenFrame = CGRect(x: 0.0, y: self.fromViewController.view.bounds.height, width: self.fromViewController.view.bounds.width, height: self.fromViewController.view.bounds.height)
        let onscreenFrame = CGRect(x: 0.0, y: 0.0, width: self.fromViewController.view.bounds.width, height: self.fromViewController.view.bounds.height)
        
        self.transitionContainerView.bringSubview(toFront: self.toViewController.view)
        
        if isPresenting {
            self.toViewController.view.frame = offscreenFrame
        } else {
            self.fromViewController.view.frame = onscreenFrame
        }
        
        UIView.animate(withDuration: self.duration, delay: 0.0, options: [UIViewAnimationOptions.curveEaseOut], animations: {
            if isPresenting {
                self.toViewController.view.frame = onscreenFrame
            } else {
                self.toViewController.view.frame = offscreenFrame
            }
        }) { (success) in
            self.finishAnimation(completion: nil)
        }
    }
    
    private func performDismissingTransition(interactive: Bool) {
        let offscreenFrame = CGRect(x: 0.0, y: self.fromViewController.view.bounds.height, width: self.fromViewController.view.bounds.width, height: self.fromViewController.view.bounds.height)
        
        self.transitionContainerView.sendSubview(toBack: self.toViewController.view)
        
        UIView.animate(withDuration: self.duration, delay: 0.0, options: [], animations: {
            self.fromViewController.view.frame = offscreenFrame
        }) { (success) in
            self.finishAnimation(completion: nil)
        }
    }

}
