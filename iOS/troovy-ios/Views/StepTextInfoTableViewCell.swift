//
//  StepTextInfoTableViewCell.swift
//  StepScrollView
//
//  Created by Daniil on 04.12.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class StepTextInfoTableViewCell: StepInfoTableViewCell, UITextViewDelegate {
    
    // MARK: Properties Overriders
    
    override var frame: CGRect {
        didSet {
            self.contentTextView?.layoutSubviews()
            self.contentTextViewLight?.layoutSubviews()
        }
    }
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var contentTextView: PlaceholderTextView!
    @IBOutlet weak var contentTextViewLight: PlaceholderTextView!
    
    // MARK: Init Methods & Superclass Overriders
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func isStepFilled() -> Bool {
        return (self.stepSelected || (self.contentTextView.text != nil && !self.contentTextView.text!.isEmpty))
    }
    
    override func makeAdditionalTransforms(filled: Bool, scaled: Bool) {
        self.contentContainer.transform = (scaled ? CGAffineTransform.identity : CGAffineTransform.identity.scaledBy(x: 0.85, y: 0.85).translatedBy(x: 0.0 - self.contentContainer.bounds.width * 0.09, y: 0.0 - self.contentContainer.bounds.height * 0.01))
        
        self.contentTextView.alpha = (scaled ? 1.0 : 0.0)
        self.contentTextViewLight.alpha = (scaled ? 0.0 : 1.0)
        
        self.contentContainer.bringSubview(toFront: (scaled ? self.contentTextView : self.contentTextViewLight))
    }
    
    override func configureInterface(animated: Bool) {
        if !self.stepSelected && self.contentTextView.isFirstResponder {
            self.contentTextView.resignFirstResponder()
        }
        
        self.configureInterface()
        
        super.configureInterface(animated: animated)
    }
    
    // MARK: Private Methods
    
    private func configureInterface() {
        self.contentTextView.placeholder = self.step.placeholder
        self.contentTextView.text = self.step.text
        self.contentTextView.isScrollEnabled = true
        self.contentTextView.setContentOffset(CGPoint.zero, animated: false)
        
        self.contentTextViewLight.placeholder = self.step.placeholder
        self.contentTextViewLight.textContainer.maximumNumberOfLines = 2
        self.contentTextViewLight.textContainer.lineBreakMode = .byTruncatingTail
        self.contentTextViewLight.text = self.step.text
        self.contentTextViewLight.isScrollEnabled = false
        
        let screenSize = UIScreen.main.bounds
        if screenSize.width == 320 && screenSize.height == 480 {
            self.contentTextView.autocorrectionType = .no
        }
    }
    
    // MARK: Protocols Implementation
    
    // MARK: UITextViewDelegate
    
    internal func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if textView == self.contentTextViewLight {
            if !self.stepSelected {
                DispatchQueue.main.async {
                    self.delegate?.cell(self, didBecomeFirstResponderWithOrder: self.stepOrder)
                }
            }

            return false
        }
        
        return true
    }
    
    internal func textViewDidBeginEditing(_ textView: UITextView) {
        self.setContentLabel(visible: true, animated: true)
        
        if !self.stepSelected {
            self.delegate?.cell(self, didBecomeFirstResponderWithOrder: self.stepOrder)
        }
    }
    
    internal func textViewDidEndEditing(_ textView: UITextView) {
        self.setContentLabel(visible: false, animated: true)
    }
    
    internal func textViewDidChange(_ textView: UITextView) {
        self.checkCellFilled(animated: true)
        
        self.step.changeText(text: textView.text)
        self.delegate?.cell(self, didChangeStep: self.step, order: self.stepOrder)
    }
    
}
