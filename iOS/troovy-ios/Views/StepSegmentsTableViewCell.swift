//
//  StepSegmentsTableViewCell.swift
//  troovy-ios
//
//  Created by Daniil on 19.12.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class StepSegmentsTableViewCell: StepInfoTableViewCell {
    
    // MARK: Properties Overriders
    
    override var frame: CGRect {
        didSet {
            self.contentTextViewLight?.layoutSubviews()
            self.layoutButtons()
        }
    }
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var contentTextViewLight: PlaceholderTextView!
    
    @IBOutlet weak var firstSegmentViewButton: UIButton!
    @IBOutlet weak var secondSegmentViewButton: UIButton!
    @IBOutlet weak var thirdSegmentViewButton: UIButton!
    
    @IBOutlet weak var firstSegmentViewButtonWidth: NSLayoutConstraint!
    @IBOutlet weak var secondSegmentViewButtonWidth: NSLayoutConstraint!
    @IBOutlet weak var thirdSegmentViewButtonWidth: NSLayoutConstraint!
    
    // MARK: Private Properties
    
    private let nonNumbersCharacterSet = CharacterSet(charactersIn: "0123456789").inverted
    
    // MARK: Init Methods & Superclass Overriders
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func isStepFilled() -> Bool {
        let firstSelected = self.isFirstSelected()
        let secondSelected = self.isSecondSelected()
        let thirdSelected = self.isThirdSelected()
        
        return (self.stepSelected || (self.step.text != nil && !self.step.text!.isEmpty && (firstSelected || secondSelected || thirdSelected)))
    }
    
    override func makeAdditionalTransforms(filled: Bool, scaled: Bool) {
        self.contentTextViewLight.transform = (scaled ? CGAffineTransform.identity : CGAffineTransform.identity.scaledBy(x: 0.85, y: 0.85).translatedBy(x: 0.0 - self.contentTextViewLight.bounds.width * 0.09, y: 0.0 - self.fullSizeHeight * 0.04))
        self.contentTextViewLight.alpha = (self.stepSelected ? 0.0 : 1.0)
        
        self.firstSegmentViewButton.transform = (scaled ? CGAffineTransform.identity : CGAffineTransform.identity.translatedBy(x: 0.0, y: 0.0))
        self.firstSegmentViewButton.alpha = (!self.stepSelected ? 0.0 : 1.0)
        
        self.secondSegmentViewButton.transform = (scaled ? CGAffineTransform.identity : CGAffineTransform.identity.translatedBy(x: 0.0, y: 0.0))
        self.secondSegmentViewButton.alpha = (!self.stepSelected ? 0.0 : 1.0)
        
        self.thirdSegmentViewButton.transform = (scaled ? CGAffineTransform.identity : CGAffineTransform.identity.translatedBy(x: 0.0, y: 0.0))
        self.thirdSegmentViewButton.alpha = (!self.stepSelected ? 0.0 : 1.0)
    }
    
    override func configureInterface(animated: Bool) {
        self.configureInterface()
        
        super.configureInterface(animated: animated)
    }
    
    // MARK: Private Methods
    
    private func configureInterface() {
        let textWithNumbersOnly = self.step.text?.trimmingCharacters(in: self.nonNumbersCharacterSet) ?? ""
        
        self.contentTextViewLight.placeholder = self.step.placeholder
        self.contentTextViewLight.textContainer.maximumNumberOfLines = 2
        self.contentTextViewLight.textContainer.lineBreakMode = .byTruncatingTail
        self.contentTextViewLight.text = (textWithNumbersOnly.isEmpty ? nil : textWithNumbersOnly + " min")
        self.contentTextViewLight.isScrollEnabled = false
        
        let firstSelected = self.isFirstSelected()
        let secondSelected = self.isSecondSelected()
        let thirdSelected = self.isThirdSelected()
        
        self.configureButtons(firstSelected: firstSelected, secondSelected: secondSelected, thirdSelected: thirdSelected)
    }
    
    private func configureButtons(firstSelected: Bool, secondSelected: Bool, thirdSelected: Bool) {
        self.configureButton(self.firstSegmentViewButton, index: 0, enabled: firstSelected)
        self.configureButton(self.secondSegmentViewButton, index: 1, enabled: secondSelected)
        self.configureButton(self.thirdSegmentViewButton, index: 2, enabled: thirdSelected)
        
        self.changeButton(self.firstSegmentViewButton, enabled: firstSelected)
        self.changeButton(self.secondSegmentViewButton, enabled: secondSelected)
        self.changeButton(self.thirdSegmentViewButton, enabled: thirdSelected)
        
        self.layoutButtons()
    }
    
    private func isFirstSelected() -> Bool {
        let textWithNumbersOnly = self.step.text?.trimmingCharacters(in: self.nonNumbersCharacterSet)
        let buttonTitleWithNumbersOnly = self.firstSegmentViewButton.titleLabel?.text?.trimmingCharacters(in: self.nonNumbersCharacterSet)
        
        return (textWithNumbersOnly != nil && textWithNumbersOnly == buttonTitleWithNumbersOnly)
    }
    
    private func isSecondSelected() -> Bool {
        let textWithNumbersOnly = self.step.text?.trimmingCharacters(in: self.nonNumbersCharacterSet)
        let buttonTitleWithNumbersOnly = self.secondSegmentViewButton.titleLabel?.text?.trimmingCharacters(in: self.nonNumbersCharacterSet)
        
        return (textWithNumbersOnly != nil && textWithNumbersOnly == buttonTitleWithNumbersOnly)
    }
    
    private func isThirdSelected() -> Bool {
        let textWithNumbersOnly = self.step.text?.trimmingCharacters(in: self.nonNumbersCharacterSet)
        let buttonTitleWithNumbersOnly = self.thirdSegmentViewButton.titleLabel?.text?.trimmingCharacters(in: self.nonNumbersCharacterSet)
        
        return (textWithNumbersOnly != nil && textWithNumbersOnly == buttonTitleWithNumbersOnly)
    }
    
    private func configureButton(_ button: UIButton, index: Int, enabled: Bool) {
        if let segments = self.step.segments, segments.count > index {
            button.clipsToBounds = true
            button.layer.cornerRadius = 23.0
            
            UIView.performWithoutAnimation {
                if enabled {
                    button.setTitle(segments[index] + " min", for: .normal)
                } else {
                    button.setTitle(segments[index], for: .normal)
                }
                button.layoutIfNeeded()
            }
        }
    }
    
    private func changeButton(_ button: UIButton, enabled: Bool) {
        if enabled {
            button.backgroundColor = UIColor.tv_purpleColor()
        } else {
            button.backgroundColor = UIColor.tv_graySemiDarkColor()
        }
    }
    
    private func layoutButtons() {
        if self.firstSegmentViewButton != nil && self.firstSegmentViewButtonWidth != nil && self.secondSegmentViewButton != nil && self.secondSegmentViewButtonWidth != nil && self.thirdSegmentViewButton != nil && self.thirdSegmentViewButtonWidth != nil && self.step != nil {
            let width = self.contentContainer.bounds.width
            let firstSelected = self.isFirstSelected()
            let secondSelected = self.isSecondSelected()
            let thirdSelected = self.isThirdSelected()
            
            var shouldLayout = false
            if firstSelected || secondSelected || thirdSelected {
                let selectedButtonWidth = ((width - 8.0) / 3.0) * 1.2
                let buttonWidth = ((width - selectedButtonWidth - 8.0) / 2.0)
                shouldLayout = (self.firstSegmentViewButtonWidth.constant != (firstSelected ? selectedButtonWidth : buttonWidth) || self.secondSegmentViewButtonWidth.constant != (secondSelected ? selectedButtonWidth : buttonWidth) || self.thirdSegmentViewButtonWidth.constant != (thirdSelected ? selectedButtonWidth : buttonWidth))
                
                if shouldLayout {
                    self.firstSegmentViewButtonWidth.constant = (firstSelected ? selectedButtonWidth : buttonWidth)
                    self.secondSegmentViewButtonWidth.constant = (secondSelected ? selectedButtonWidth : buttonWidth)
                    self.thirdSegmentViewButtonWidth.constant = (thirdSelected ? selectedButtonWidth : buttonWidth)
                }
            } else {
                let buttonWidth = ((width - 8.0) / 3.0)
                shouldLayout = (self.firstSegmentViewButtonWidth.constant != buttonWidth || self.secondSegmentViewButtonWidth.constant != buttonWidth || self.thirdSegmentViewButtonWidth.constant != buttonWidth)
                
                if shouldLayout {
                    self.firstSegmentViewButtonWidth.constant = buttonWidth
                    self.secondSegmentViewButtonWidth.constant = buttonWidth
                    self.thirdSegmentViewButtonWidth.constant = buttonWidth
                }
            }
            
            if shouldLayout {
                self.contentView.layoutIfNeeded()
            }
        }
    }
    
    // MARK: Controls Actions
    
    @IBAction func segmentButtonAction(_ sender: UIButton) {
        var text: String? = nil
        if sender == self.firstSegmentViewButton {
            text = self.firstSegmentViewButton.titleLabel?.text
        } else if sender == self.secondSegmentViewButton {
            text = self.secondSegmentViewButton.titleLabel?.text
        } else if sender == self.thirdSegmentViewButton {
            text = self.thirdSegmentViewButton.titleLabel?.text
        }
        
        if text != nil {
            let minutesString = text! + " min"
            self.step.changeText(text: minutesString)
            self.delegate?.cell(self, didChangeStep: self.step, order: self.stepOrder)
            
            let firstSelected = self.isFirstSelected()
            let secondSelected = self.isSecondSelected()
            let thirdSelected = self.isThirdSelected()
            
            UIView.animate(withDuration: 0.25) {
                self.configureButtons(firstSelected: firstSelected, secondSelected: secondSelected, thirdSelected: thirdSelected)
            }
        }
    }
    
}
