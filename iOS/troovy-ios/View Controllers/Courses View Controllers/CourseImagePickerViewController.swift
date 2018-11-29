//
//  CourseImagePickerViewController.swift
//  troovy-ios
//
//  Created by Daniil on 15.12.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit
import Photos

class CourseImagePickerViewController: UIViewController {
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var containerView: UIView!
    
    // MARK: Private Properties
    
    private var onSelection: ((_ assets: [DKAsset]) -> Void)?
    private var maxSelectableCount: Int = 0
    
    private var imagePicker: DKImagePickerController?
    
    // MARK: Init Methods & Superclass Overriders

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.imagePicker == nil && self.maxSelectableCount > 0 {
            self.createImagePicker(withSelectBlock: self.onSelection, maxSelectableCount: self.maxSelectableCount)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.imagePicker?.view.frame = self.containerView.bounds
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: Public Methods
    
    func configure(withSelectBlock didSelect: ((_ assets: [DKAsset]) -> Void)?, maxSelectableCount: Int) {
        if self.imagePicker != nil {
            return
        }
        
        if self.isViewLoaded {
            self.createImagePicker(withSelectBlock: didSelect, maxSelectableCount: maxSelectableCount)
        } else {
            self.onSelection = didSelect
            self.maxSelectableCount = maxSelectableCount
        }
    }
    
    // MARK: Private Properties
    
    private func createImagePicker(withSelectBlock didSelect: ((_ assets: [DKAsset]) -> Void)?, maxSelectableCount: Int) {
        self.imagePicker = self.imagePickerController(withSelectBlock: didSelect, maxSelectableCount: maxSelectableCount)
        
        if let imagePicker = self.imagePicker {
            self.addChildViewController(imagePicker)
            imagePicker.beginAppearanceTransition(true, animated: true)
            imagePicker.view.frame = self.containerView.bounds
            self.containerView.addSubview(imagePicker.view)
            imagePicker.endAppearanceTransition()
            imagePicker.didMove(toParentViewController: self)
        }
    }
    
    private func imagePickerController(withSelectBlock didSelect: ((_ assets: [DKAsset]) -> Void)?, maxSelectableCount: Int) -> DKImagePickerController {
        let imagePicker = DKImagePickerController()
        imagePicker.singleSelect = (maxSelectableCount == 1)
        imagePicker.autoCloseOnSingleSelect = (maxSelectableCount == 1)
        imagePicker.maxSelectableCount = maxSelectableCount
        imagePicker.showsEmptyAlbums = false
        imagePicker.assetType = .allAssets
        imagePicker.sourceType = .photo
        imagePicker.autoDownloadWhenAssetIsInCloud = true
        imagePicker.allowsLandscape = false
        imagePicker.showsCancelButton = true
        imagePicker.didSelectAssets = didSelect
        return imagePicker
    }
    
    // MARK: Controls Actions
    
    @IBAction func panGestureAction(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: self.view)
        let verticalMovement = translation.y / self.view.bounds.height
        let downwardMovement = fmaxf(Float(verticalMovement), 0.0)
        let downwardMovementPercent = fminf(downwardMovement, 1.0)
        let progress = CGFloat(downwardMovementPercent)
        
        switch sender.state {
        case .began:
            let velocity = sender.velocity(in: self.containerView)
            if velocity.x > self.containerView.frame.height / 3.0 {
                self.dismiss(animated: true, completion: nil)
                sender.isEnabled = false
            } else {
                self.customModalTransition?.beginInteractiveDismissalTransition(completion: nil)
            }
            break
        case .changed:
            self.customModalTransition?.updateInteractiveTransitionToProgress(progress: progress)
            break
        case .ended:
            if progress >= 0.3 {
                self.customModalTransition?.finishInteractiveTransition()
            } else {
                self.customModalTransition?.cancelInteractiveTransition()
            }
            break
        default:
            self.customModalTransition?.cancelInteractiveTransition()
            break
        }
    }

}
