//
//  StepTextInfoTableViewCell.swift
//  StepScrollView
//
//  Created by Daniil on 04.12.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit
import QuartzCore

import Kingfisher

class StepImagesInfoTableViewCell: StepInfoTableViewCell {
    
    // MARK: Properties Overriders
    
    override var frame: CGRect {
        didSet {
            self.contentTextViewLight?.layoutSubviews()
        }
    }
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var contentTextViewLight: PlaceholderTextView!
    
    @IBOutlet weak var firstImageViewButton: UIButton!
    @IBOutlet weak var secondImageViewButton: UIButton!
    @IBOutlet weak var thirdImageViewButton: UIButton!
    
    @IBOutlet weak var firstImageView: UIImageView!
    @IBOutlet weak var secondImageView: UIImageView!
    @IBOutlet weak var thirdImageView: UIImageView!
    
    // MARK: Private Properties
    
    private let infoPlistService = InfoPlistService()
    
    private var firstDeleteGestureRecognizer: UIPanGestureRecognizer!
    private var secondDeleteGestureRecognizer: UIPanGestureRecognizer!
    private var thirdDeleteGestureRecognizer: UIPanGestureRecognizer!
    
    private var firstMediaExists = false
    private var secondMediaExists = false
    private var thirdMediaExists = false
    
    private var movedView: UIView?
    
    // MARK: Init Methods & Superclass Overriders
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.configureGesturesAndImageViews()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func isStepFilled() -> Bool {
        return (self.stepSelected || self.firstMediaExists)
    }
    
    override func makeAdditionalTransforms(filled: Bool, scaled: Bool) {
        self.contentTextViewLight.transform = (scaled ? CGAffineTransform.identity : CGAffineTransform.identity.scaledBy(x: 0.85, y: 0.85).translatedBy(x: 0.0 - self.contentTextViewLight.bounds.width * 0.09, y: 0.0 - self.fullSizeHeight * 0.01))
        self.contentTextViewLight.alpha = (self.firstMediaExists || self.stepSelected ? 0.0 : 1.0)
        
        self.firstImageViewButton.transform = (scaled ? CGAffineTransform.identity : CGAffineTransform.identity.translatedBy(x: 0.0, y: 0.0))
        self.firstImageViewButton.alpha = (!self.firstMediaExists && !self.stepSelected ? 0.0 : 1.0)
        
        self.secondImageViewButton.transform = (scaled ? CGAffineTransform.identity : CGAffineTransform.identity.translatedBy(x: 0.0, y: 0.0))
        self.secondImageViewButton.alpha = (!self.secondMediaExists && !self.firstMediaExists && !self.stepSelected ? 0.0 : (self.firstMediaExists ? 1.0 : 0.0))
        
        self.thirdImageViewButton.transform = (scaled ? CGAffineTransform.identity : CGAffineTransform.identity.translatedBy(x: 0.0, y: 0.0))
        self.thirdImageViewButton.alpha = (!self.thirdMediaExists && !self.secondMediaExists && !self.firstMediaExists && !self.stepSelected ? 0.0 : (self.firstMediaExists && self.secondMediaExists ? 1.0 : 0.0))
    }
    
    override func configureInterface(animated: Bool) {
        self.configureInterface()
        
        super.configureInterface(animated: animated)
    }
    
    // MARK: Private Methods
    
    private func configureGesturesAndImageViews() {
        self.firstDeleteGestureRecognizer = UIPanGestureRecognizer.init(target: self, action: #selector(deleteGestureAction(_:)))
        self.firstDeleteGestureRecognizer.cancelsTouchesInView = true
        self.firstDeleteGestureRecognizer.delegate = self
        self.firstImageViewButton.addGestureRecognizer(self.firstDeleteGestureRecognizer)
        self.firstImageView.alpha = 0.0
        
        self.secondDeleteGestureRecognizer = UIPanGestureRecognizer.init(target: self, action: #selector(deleteGestureAction(_:)))
        self.secondDeleteGestureRecognizer.cancelsTouchesInView = true
        self.secondDeleteGestureRecognizer.delegate = self
        self.secondImageViewButton.addGestureRecognizer(self.secondDeleteGestureRecognizer)
        self.secondImageView.alpha = 0.0
        
        self.thirdDeleteGestureRecognizer = UIPanGestureRecognizer.init(target: self, action: #selector(deleteGestureAction(_:)))
        self.thirdDeleteGestureRecognizer.cancelsTouchesInView = true
        self.thirdDeleteGestureRecognizer.delegate = self
        self.thirdImageViewButton.addGestureRecognizer(self.thirdDeleteGestureRecognizer)
        self.thirdImageView.alpha = 0.0
        
        self.firstImageViewButton.imageView?.contentMode = .scaleAspectFill
        self.secondImageViewButton.imageView?.contentMode = .scaleAspectFill
        self.thirdImageViewButton.imageView?.contentMode = .scaleAspectFill
    }
    
    private func configureInterface() {
        self.contentTextViewLight.placeholder = self.step.placeholder
        self.contentTextViewLight.textContainer.maximumNumberOfLines = 2
        self.contentTextViewLight.textContainer.lineBreakMode = .byTruncatingTail
        self.contentTextViewLight.text = nil
        self.contentTextViewLight.isScrollEnabled = false
        
        self.firstImageViewButton.setImage(nil, for: .normal)
        let firstButtonImage = self.image(fromMedia: self.step.media, atIndex: 0, button: self.firstImageViewButton)
        self.firstMediaExists = (firstButtonImage != nil)
        if self.firstImageViewButton.image(for: .normal) == nil {
            self.firstImageViewButton.setImage((firstButtonImage ?? UIImage.tv_plusWithBorderPlacehilder()), for: .normal)
        }
        self.firstImageViewButton.isUserInteractionEnabled = self.stepSelected
        
        self.secondImageViewButton.setImage(nil, for: .normal)
        let secondButtonImage = self.image(fromMedia: self.step.media, atIndex: 1, button: self.secondImageViewButton)
        self.secondMediaExists = (secondButtonImage != nil)
        if self.secondImageViewButton.image(for: .normal) == nil {
            self.secondImageViewButton.setImage((secondButtonImage ?? UIImage.tv_plusWithBorderPlacehilder()), for: .normal)
        }
        self.secondImageViewButton.alpha = (self.firstMediaExists ? 1.0 : 0.0)
        self.secondImageViewButton.isUserInteractionEnabled = self.stepSelected
        
        self.thirdImageViewButton.setImage(nil, for: .normal)
        let thirdButtonImage = self.image(fromMedia: self.step.media, atIndex: 2, button: self.thirdImageViewButton)
        self.thirdMediaExists = (thirdButtonImage != nil)
        if self.thirdImageViewButton.image(for: .normal) == nil {
            self.thirdImageViewButton.setImage((thirdButtonImage ?? UIImage.tv_plusWithBorderPlacehilder()), for: .normal)
        }
        self.thirdImageViewButton.alpha = (self.firstMediaExists && self.secondMediaExists ? 1.0 : 0.0)
        self.thirdImageViewButton.isUserInteractionEnabled = self.stepSelected
    }
    
    private func image(fromMedia media: [Any]?, atIndex index: Int, button: UIButton) -> UIImage? {
        button.kf.cancelImageDownloadTask()
        
        var stepImage: UIImage?
        if media != nil && media!.count > index {
            if let image = media![index] as? UIImage {
                stepImage = image
            } else if let videoURL = media![index] as? URL {
                stepImage = self.image(withVideoURL: videoURL)
            } else if let introModel = media![index] as? CourseIntroModel {
                stepImage = UIImage()
                
                var imageResourse: ImageResource?
                let serverAddress = self.infoPlistService.serverURL()
                if let thumbnailAddress = introModel.thumbnailAddress, let thumbnailImageURL = URL.address(byAppendingServerAddress: serverAddress, toContentPath: thumbnailAddress) {
                    imageResourse = ImageResource(downloadURL: thumbnailImageURL)
                } else if let fileAddress = introModel.fileAddress, let fileImageURL = URL.address(byAppendingServerAddress: serverAddress, toContentPath: fileAddress) {
                    imageResourse = ImageResource(downloadURL: fileImageURL)
                }
                
                if let resource = imageResourse {
                    button.kf.setImage(with: resource, for: .normal, placeholder: UIImage.tv_plusWithBorderPlacehilder(), options: nil, progressBlock: nil, completionHandler: nil)
                }
            }
        }
        
        return stepImage
    }
    
    private func image(withVideoURL url: URL) -> UIImage? {
        var image: UIImage?
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        if let imageRef = try? imageGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil) {
            image = UIImage(cgImage: imageRef)
        }
        
        return image
    }
    
    // MARK: Drag Images
    
    private func restoreOrder(removeAnimations: Bool) {
        if removeAnimations {
            self.firstImageView.layer.removeAnimation(forKey: "transform")
            self.firstImageViewButton.layer.removeAnimation(forKey: "transform")
            
            self.secondImageView.layer.removeAnimation(forKey: "transform")
            self.secondImageViewButton.layer.removeAnimation(forKey: "transform")
            
            self.thirdImageView.layer.removeAnimation(forKey: "transform")
            self.thirdImageViewButton.layer.removeAnimation(forKey: "transform")
        }
        
        self.firstImageView.transform = CGAffineTransform.identity
        self.firstImageViewButton.transform = CGAffineTransform.identity
        
        self.secondImageView.transform = CGAffineTransform.identity
        self.secondImageViewButton.transform = CGAffineTransform.identity
        
        self.thirdImageView.transform = CGAffineTransform.identity
        self.thirdImageViewButton.transform = CGAffineTransform.identity
    }
    
    private func checkOrderChanged(withTransform transform: CGAffineTransform?, senderView: UIView?, cancelled: Bool) {
        if let movedView = senderView, let moveTransform = transform, !cancelled {
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .beginFromCurrentState, animations: {
                let movedFrame = movedView.frame.applying(moveTransform)
                let movedFrameCenter = CGPoint(x: movedFrame.origin.x + movedFrame.size.width / 2.0, y: movedFrame.origin.y + movedFrame.size.height / 2.0)
                
                if senderView == self.firstImageViewButton {
                    if self.secondImageView.frame.contains(movedFrameCenter) && self.secondMediaExists {
                        self.firstImageView.transform = CGAffineTransform.identity.translatedBy(x: self.secondImageView.frame.origin.x - self.firstImageViewButton.frame.origin.x, y: 0.0)
                        self.secondImageViewButton.transform = CGAffineTransform.identity.translatedBy(x: 0.0 - (self.secondImageView.frame.origin.x - self.firstImageViewButton.frame.origin.x), y: 0.0)
                        self.thirdImageViewButton.transform = CGAffineTransform.identity
                        return
                    } else if self.thirdImageView.frame.contains(movedFrameCenter) && self.thirdMediaExists {
                        self.firstImageView.transform = CGAffineTransform.identity.translatedBy(x: self.thirdImageView.frame.origin.x - self.firstImageViewButton.frame.origin.x, y: 0.0)
                        self.secondImageViewButton.transform = CGAffineTransform.identity
                        self.thirdImageViewButton.transform = CGAffineTransform.identity.translatedBy(x: 0.0 - (self.thirdImageView.frame.origin.x - self.firstImageViewButton.frame.origin.x), y: 0.0)
                        return
                    }
                } else if senderView == self.secondImageViewButton {
                    if self.firstImageView.frame.contains(movedFrameCenter) && self.firstMediaExists {
                        self.secondImageView.transform = CGAffineTransform.identity.translatedBy(x: self.firstImageView.frame.origin.x - self.secondImageViewButton.frame.origin.x, y: 0.0)
                        self.firstImageViewButton.transform = CGAffineTransform.identity.translatedBy(x: 0.0 - (self.firstImageView.frame.origin.x - self.secondImageViewButton.frame.origin.x), y: 0.0)
                        self.thirdImageViewButton.transform = CGAffineTransform.identity
                        return
                    } else if self.thirdImageView.frame.contains(movedFrameCenter) && self.thirdMediaExists {
                        self.secondImageView.transform = CGAffineTransform.identity.translatedBy(x: self.thirdImageView.frame.origin.x - self.secondImageViewButton.frame.origin.x, y: 0.0)
                        self.firstImageViewButton.transform = CGAffineTransform.identity
                        self.thirdImageViewButton.transform = CGAffineTransform.identity.translatedBy(x: 0.0 - (self.thirdImageView.frame.origin.x - self.secondImageViewButton.frame.origin.x), y: 0.0)
                        return
                    }
                } else if senderView == self.thirdImageViewButton {
                    if self.firstImageView.frame.contains(movedFrameCenter) && self.firstMediaExists {
                        self.thirdImageView.transform = CGAffineTransform.identity.translatedBy(x: self.firstImageView.frame.origin.x - self.thirdImageViewButton.frame.origin.x, y: 0.0)
                        self.firstImageViewButton.transform = CGAffineTransform.identity.translatedBy(x: 0.0 - (self.firstImageView.frame.origin.x - self.thirdImageViewButton.frame.origin.x), y: 0.0)
                        self.secondImageViewButton.transform = CGAffineTransform.identity
                        return
                    } else if self.secondImageView.frame.contains(movedFrameCenter) && self.secondMediaExists {
                        self.thirdImageView.transform = CGAffineTransform.identity.translatedBy(x: self.secondImageView.frame.origin.x - self.thirdImageViewButton.frame.origin.x, y: 0.0)
                        self.firstImageViewButton.transform = CGAffineTransform.identity
                        self.secondImageViewButton.transform = CGAffineTransform.identity.translatedBy(x: 0.0 - (self.secondImageView.frame.origin.x - self.thirdImageViewButton.frame.origin.x), y: 0.0)
                        return
                    }
                }
                
                self.restoreOrder(removeAnimations: false)
            }, completion: nil)
        } else {
            if !cancelled {
                if senderView == self.firstImageViewButton {
                    let movedFrameCenter = CGPoint(x: self.firstImageView.frame.origin.x + self.firstImageView.frame.size.width / 2.0, y: self.firstImageView.frame.origin.y + self.firstImageView.frame.size.height / 2.0)
                    if self.secondImageView.frame.contains(movedFrameCenter) {
                        self.restoreOrder(removeAnimations: true)
                        self.replaceButtonImages(fromButton: self.firstImageViewButton, andButton: self.secondImageViewButton)
                        self.moveDelegate?.cell(self, changeOrderFrom: 0, to: 1)
                        return
                    } else if self.thirdImageView.frame.contains(movedFrameCenter) {
                        self.restoreOrder(removeAnimations: true)
                        self.replaceButtonImages(fromButton: self.firstImageViewButton, andButton: self.thirdImageViewButton)
                        self.moveDelegate?.cell(self, changeOrderFrom: 0, to: 2)
                        return
                    }
                } else if senderView == self.secondImageViewButton {
                    let movedFrameCenter = CGPoint(x: self.secondImageView.frame.origin.x + self.secondImageView.frame.size.width / 2.0, y: self.secondImageView.frame.origin.y + self.secondImageView.frame.size.height / 2.0)
                    if self.firstImageView.frame.contains(movedFrameCenter) {
                        self.restoreOrder(removeAnimations: true)
                        self.replaceButtonImages(fromButton: self.secondImageViewButton, andButton: self.firstImageViewButton)
                        self.moveDelegate?.cell(self, changeOrderFrom: 1, to: 0)
                        return
                    } else if self.thirdImageView.frame.contains(movedFrameCenter) {
                        self.restoreOrder(removeAnimations: true)
                        self.replaceButtonImages(fromButton: self.secondImageViewButton, andButton: self.thirdImageViewButton)
                        self.moveDelegate?.cell(self, changeOrderFrom: 1, to: 2)
                        return
                    }
                } else if senderView == self.thirdImageViewButton {
                    let movedFrameCenter = CGPoint(x: self.thirdImageView.frame.origin.x + self.thirdImageView.frame.size.width / 2.0, y: self.thirdImageView.frame.origin.y + self.thirdImageView.frame.size.height / 2.0)
                    if self.firstImageView.frame.contains(movedFrameCenter) {
                        self.restoreOrder(removeAnimations: true)
                        self.replaceButtonImages(fromButton: self.thirdImageViewButton, andButton: self.firstImageViewButton)
                        self.moveDelegate?.cell(self, changeOrderFrom: 2, to: 0)
                        return
                    } else if self.secondImageView.frame.contains(movedFrameCenter) {
                        self.restoreOrder(removeAnimations: true)
                        self.replaceButtonImages(fromButton: self.thirdImageViewButton, andButton: self.secondImageViewButton)
                        self.moveDelegate?.cell(self, changeOrderFrom: 2, to: 1)
                        return
                    }
                }
            }
            
            self.restoreOrder(removeAnimations: false)
        }
    }
    
    private func replaceButtonImages(fromButton first: UIButton, andButton second: UIButton) {
        first.layer.removeAllAnimations()
        second.layer.removeAllAnimations()
        
        let firstImage = first.imageView?.image
        let secondImage = second.imageView?.image
        
        first.setImage(secondImage, for: .normal)
        second.setImage(firstImage, for: .normal)
        
        first.alpha = 1.0
        second.alpha = 1.0
    }
    
    private func configureButtons(withDragging dragging: Bool, senderView: UIView?) {
        self.firstImageViewButton.alpha = ((dragging && (senderView == self.firstImageViewButton || !self.firstMediaExists)) ? 0.0 : 1.0)
        self.firstImageView.alpha = ((dragging && senderView == self.firstImageViewButton) ? 1.0 : 0.0)
        
        self.secondImageViewButton.alpha = ((dragging && (senderView == self.secondImageViewButton || !self.secondMediaExists)) ? 0.0 : (self.firstMediaExists ? 1.0 : 0.0))
        self.secondImageView.alpha = ((dragging && senderView == self.secondImageViewButton) ? 1.0 : 0.0)
        
        self.thirdImageViewButton.alpha = ((dragging && (senderView == self.thirdImageViewButton || !self.thirdMediaExists)) ? 0.0 : (self.firstMediaExists && self.secondMediaExists ? 1.0 : 0.0))
        self.thirdImageView.alpha = ((dragging && senderView == self.thirdImageViewButton) ? 1.0 : 0.0)
    }
    
    private func removeSnapshotView(animated: Bool, sender: UIPanGestureRecognizer) {
        if animated {
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .beginFromCurrentState, animations: {
                self.configureButtons(withDragging: false, senderView: sender.view)
                self.movedView?.alpha = 0.0
            }, completion: { (success) in
                self.movedView?.removeFromSuperview()
                self.movedView = nil
            })
        } else {
            self.configureButtons(withDragging: false, senderView: sender.view)
            
            self.movedView?.removeFromSuperview()
            self.movedView = nil
        }
    }
    
    private func createSnapshotView(from viewToSnap: UIView?) {
        guard let view = viewToSnap else {
            return
        }
        
        let imageView = RoundedImageView.init(frame: view.frame)
        imageView.contentMode = .scaleAspectFill
        imageView.cornerRadius = 8.0
        
        if view == self.firstImageViewButton {
            imageView.image = self.firstImageViewButton.imageView?.image
        } else if view == self.secondImageViewButton {
            imageView.image = self.secondImageViewButton.imageView?.image
        } else if view == self.thirdImageViewButton {
            imageView.image = self.thirdImageViewButton.imageView?.image
        }
        
        self.movedView?.removeFromSuperview()
        self.movedView = imageView
    }
    
    // MARK: Controls Actions
    
    @IBAction func imageButtonAction(_ sender: UIButton) {
        let mediaIndex = (sender == self.firstImageViewButton ? 0 : (sender == self.secondImageViewButton ? 1 : 2))
        if self.stepSelected {
            self.delegate?.cell(self, shouldChangeMediaForStep: self.step, order: self.stepOrder, mediaIndex: mediaIndex)
        } else {
            self.delegate?.cell(self, didBecomeFirstResponderWithOrder: self.stepOrder)
        }
    }
    
    @objc private func deleteGestureAction(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            self.createSnapshotView(from: sender.view)
            if let movedView = self.movedView, let senderView = sender.view {
                let mediaIndex = (senderView == self.firstImageViewButton ? 0 : (senderView == self.secondImageViewButton ? 1 : 2))
                self.moveDelegate?.cell(self, beginMoveOfView: movedView, withPoint: senderView.center, mediaIndex: mediaIndex)
                
                self.configureButtons(withDragging: true, senderView: sender.view)
            }
            break
        case .changed:
            if let movedView = self.movedView {
                let translation = sender.translation(in: self.contentContainer)
                let transform = CGAffineTransform.identity.translatedBy(x: translation.x, y: translation.y)
                self.moveDelegate?.cell(self, moveView: movedView, withTransform: transform)
                
                self.checkOrderChanged(withTransform: transform, senderView: sender.view, cancelled: false)
            }
            break
        case .ended:
            if let movedView = self.movedView {
                self.moveDelegate?.cell(self, endMoveOfView: movedView)
            }
            
            self.removeSnapshotView(animated: true, sender: sender)
            self.checkOrderChanged(withTransform: nil, senderView: sender.view, cancelled: false)
            break
        default:
            if let movedView = self.movedView {
                self.moveDelegate?.cell(self, cancelMoveOfView: movedView)
            }
            
            self.removeSnapshotView(animated: false, sender: sender)
            self.checkOrderChanged(withTransform: nil, senderView: sender.view, cancelled: true)
        }
    }
    
    // MARK: Protocols Implementation
    
    // MARK: UIGestureRecognizerDelegate
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == self.firstDeleteGestureRecognizer {
            return self.firstMediaExists && self.stepSelected
        } else if gestureRecognizer == self.secondDeleteGestureRecognizer {
            return self.secondMediaExists && self.stepSelected
        } else if gestureRecognizer == self.thirdDeleteGestureRecognizer {
            return self.thirdMediaExists && self.stepSelected
        }
        
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }
    
}
