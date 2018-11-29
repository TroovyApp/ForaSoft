//
//  StepInfoTableViewCell.swift
//  StepScrollView
//
//  Created by Daniil on 01.12.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit
import QuartzCore

struct StepInfo {
    
    var identificator: String!
    var title: String!
    var placeholder: String!
    var text: String?
    var media: [Any]?
    var date: Date?
    var segments: [String]?
    
    init(title: String, placeholder: String, text: String?, media: [Any]?, date: Date?, segments: [String]?) {
        self.identificator = UUID().uuidString
        self.title = title
        self.placeholder = placeholder
        self.text = text
        self.date = date
        self.segments = segments
        
        if media != nil {
            self.media = self.mediaItems(fromMedia: media!)
        } else {
            self.media = nil
        }
    }
    
    mutating func changeText(text: String?) {
        self.text = text
    }
    
    mutating func changeMedia(media: [Any]?) {
        if media != nil {
            self.media = self.mediaItems(fromMedia: media!)
        } else {
            self.media = nil
        }
    }
    
    mutating func changeDate(date: Date?) {
        self.date = date
    }
    
    private func mediaItems(fromMedia media: [Any]) -> [Any] {
        var mediaObject: [Any] = []
        for item in media {
            if let image = (item as? UIImage) {
                mediaObject.append(image)
            } else if let videoURL = (item as? URL) {
                mediaObject.append(videoURL)
            } else if let introModel = (item as? CourseIntroModel) {
                mediaObject.append(introModel)
            }
        }
        return mediaObject
    }
    
    func isStepFilled() -> Bool {
        if self.media != nil {
            return (self.media!.count > 0)
        } else if self.segments != nil {
            if let segments = self.segments, segments.count > 0 {
                let nonNumbersCharacterSet = CharacterSet(charactersIn: "0123456789").inverted
                let textWithNumbersOnly = self.text?.trimmingCharacters(in: nonNumbersCharacterSet) ?? ""
                return (self.text != nil && !self.text!.isEmpty && segments.contains(textWithNumbersOnly))
            } else {
                return false
            }
        } else if self.date != nil {
            return true
        } else {
            return (self.text != nil && !self.text!.isEmpty)
        }
    }
    
}

protocol StepInfoCellDelegate: class {
    func cell(_ cell: StepInfoTableViewCell, didBecomeFirstResponderWithOrder order: Int)
    func cell(_ cell: StepInfoTableViewCell, didResignFirstResponderWithOrder order: Int)
    func cell(_ cell: StepInfoTableViewCell, didChangeStep step: StepInfo, order: Int)
    func cell(_ cell: StepInfoTableViewCell, shouldChangeMediaForStep step: StepInfo, order: Int, mediaIndex: Int)
}

protocol StepDragCellDelegate: class {
    func cell(_ cell: StepInfoTableViewCell, beginMoveOfView view: UIView, withPoint point: CGPoint, mediaIndex: Int)
    func cell(_ cell: StepInfoTableViewCell, moveView view: UIView, withTransform transform: CGAffineTransform)
    func cell(_ cell: StepInfoTableViewCell, changeOrderFrom from: Int, to: Int)
    func cell(_ cell: StepInfoTableViewCell, endMoveOfView view: UIView)
    func cell(_ cell: StepInfoTableViewCell, cancelMoveOfView view: UIView)
}

class StepInfoTableViewCell: UITableViewCell {
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var dotView: UIView!
    @IBOutlet weak var dotLabel: UILabel!
    @IBOutlet weak var dotTopLineView: UIView!
    @IBOutlet weak var dotBottomLineView: UIView!
    
    @IBOutlet weak var contentContainer: UIView!
    @IBOutlet weak var contentLabel: UILabel!
    
    // MARK: Public Properties
    
    /// Delegate. Responds to StepInfoCellDelegate.
    weak var delegate: StepInfoCellDelegate?
    
    /// Delegate. Responds to StepDragCellDelegate.
    weak var moveDelegate: StepDragCellDelegate?
    
    // MARK: Internal Properties
    
    /// Current step.
    internal var step: StepInfo!
    
    /// Current step order. Default is 0.
    internal var stepOrder: Int = 0
    
    /// Is current step selected. Default is false.
    internal var stepSelected: Bool = false
    
    /// Full cell height. Used for transforms.
    internal var fullSizeHeight: CGFloat = 0.0
    
    // MARK: Private Properties
    
    private var previousStep: StepInfo!
    private var previousStepFilled: Bool = false
    private var previousStepSelected: Bool = false
    
    private var nextStep: StepInfo!
    private var nextStepFilled: Bool = false
    private var nextStepSelected: Bool = false
    
    // MARK: Init Methods & Superclass Overriders

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    /// Configures cell for step.
    ///
    /// - parameters step: Current step.
    /// - parameters stepOrder: Current step order.
    /// - parameters stepSelected: Is current step selected.
    /// - parameters previousStep: Previous step.
    /// - parameters previousStepSelected: Is previous step selected.
    /// - parameters nextStep: Next step.
    /// - parameters nextStepSelected: Is next step selected.
    /// - parameters fullSizeHeight: Cell full height. Used for scale font.
    ///
    func configure(withStep step: StepInfo, stepOrder: Int, stepSelected: Bool, previousStep: StepInfo?, previousStepSelected: Bool, nextStep: StepInfo?, nextStepSelected: Bool, fullSizeHeight: CGFloat) {
        let animated = (self.step != nil && self.step!.identificator == step.identificator)
        
        self.step = step
        self.stepOrder = stepOrder
        self.stepSelected = stepSelected
        
        self.previousStep = previousStep
        self.previousStepFilled = previousStep?.isStepFilled() ?? false
        self.previousStepSelected = previousStepSelected
        
        self.nextStep = nextStep
        self.nextStepFilled = nextStep?.isStepFilled() ?? false
        self.nextStepSelected = nextStepSelected
        
        self.fullSizeHeight = fullSizeHeight
        
        self.configureInterface(animated: animated)
    }
    
    // MARK: Internal Methods
    
    /// Determines if step filled. Should be overrided.
    ///
    /// - returns: True if step should be filled. False otherwise.
    ///
    internal func isStepFilled() -> Bool {
        return self.stepSelected
    }
    
    /// Gets called in transforms animation cycle. Write down here additional changes.
    ///
    /// - parameters filled: Is step filled.
    /// - parameters scaled: Is step scaled.
    ///
    internal func makeAdditionalTransforms(filled: Bool, scaled: Bool) {
        // Nothing to do
    }
    
    /// Gets called in transform animation cycle completion block.
    internal func transformCompelted() {
        // Nothing to do
    }
    
    /// Sets content label visible state.
    ///
    /// - parameters visible: True if label should be visible. False otherwise.
    /// - parameters animated: True if changes should be animated. False otherwise.
    ///
    internal func setContentLabel(visible: Bool, animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .beginFromCurrentState, animations: {
                self.contentLabel.alpha = (visible ? 1.0 : 0.0)
            }, completion: { (success) in
                self.transformCompelted()
            })
        } else {
            self.contentLabel.alpha = (visible ? 1.0 : 0.0)
        }
    }
    
    /// Checks filled state and animate it if needed.
    ///
    /// - parameters animated: True if changes should be animated. False otherwise.
    ///
    internal func checkCellFilled(animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .beginFromCurrentState, animations: {
                self.changeViewsPositioning()
            }, completion: nil)
        } else {
            self.changeViewsPositioning()
        }
    }
    
    /// Configures interface and animate it if needed.
    ///
    /// - parameters animated: True if changes should be animated. False otherwise.
    ///
    internal func configureInterface(animated: Bool) {
        self.dotLabel.text = (self.stepSelected ? "\(self.stepOrder)" : "")
        self.contentLabel.text = self.step.title
        
        self.dotView.backgroundColor = .clear
        self.dotView.clipsToBounds = true
        self.dotView.layer.cornerRadius = 8.0
        
        self.dotTopLineView.isHidden = (self.previousStep == nil)
        self.dotTopLineView.backgroundColor = .clear
        
        self.dotBottomLineView.isHidden = (self.nextStep == nil)
        self.dotBottomLineView.backgroundColor = .clear
        
        self.checkCellFilled(animated: animated)
        self.setContentLabel(visible: self.stepSelected, animated: animated)
    }
    
    // MARK: Private Methods
    
    private func changeViewsPositioning() {
        let filled = self.isStepFilled()
        let scaled = self.stepSelected
        let highlightTopLine = (self.previousStepFilled || self.previousStepSelected)  && filled
        let highlightBottomLine = (self.nextStepFilled || self.nextStepSelected) && filled
        
        self.dotView.layer.backgroundColor = (filled ? UIColor.tv_purpleColor() : UIColor.tv_grayColor()).cgColor
        self.dotTopLineView.layer.backgroundColor = (highlightTopLine ? UIColor.tv_purpleColor() : UIColor.tv_grayColor()).cgColor
        self.dotBottomLineView.layer.backgroundColor = (highlightBottomLine ? UIColor.tv_purpleColor() : UIColor.tv_grayColor()).cgColor
        
        self.dotView.transform = (scaled ? CGAffineTransform.identity.scaledBy(x: 2.5, y: 2.5) : CGAffineTransform.identity)
        self.dotLabel.transform = (scaled ? CGAffineTransform.identity.scaledBy(x: 1.0, y: 1.0) : CGAffineTransform.identity.scaledBy(x: 0.0, y: 0.0))
        
        self.makeAdditionalTransforms(filled: filled, scaled: scaled)
    }

}
