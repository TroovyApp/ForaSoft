//
//  TroovyPlayerViewController.swift
//  troovy-ios
//
//  Created by Daniil on 10.10.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit
import AVKit

class TroovyPlayerViewController: AVPlayerViewController {
    
    // MARK: Properties Overriders
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: Public Properties
    
    var image: UIImage? {
        didSet {
            self.apply(self.image)
        }
    }
    
    // MARK: Private Properties
    
    private var observeToken: NSKeyValueObservation?
    
    private var imageView: UIImageView?
    
    private var viewAppeared = false
    
    // MARK: Init Methods & Superclass Overriders

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.allowsPictureInPicturePlayback = false
        self.updatesNowPlayingInfoCenter = false
        
        self.setupImageView()
        self.setupSwipeToDismiss()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.viewAppeared = true
        
        if self.observeToken == nil {
            self.observeToken = self.observe(\.isReadyForDisplay, options: [.new]) { [weak self] (controller, change) in
                if let newValue = change.newValue {
                    let imageViewHidden = (controller.imageView?.isHidden ?? false)
                    self?.showsPlaybackControls = (newValue && imageViewHidden)
                }
            }
        }
        
        self.apply(self.image)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.viewAppeared = false
        
        self.player?.pause()
        if self.observeToken != nil {
            self.observeToken?.invalidate()
        }

        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if self.view.bounds == self.contentOverlayView?.bounds && self.viewAppeared == false {
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    deinit {
        self.player?.pause()
        //self.player = nil
    }
    
    // MARK: Public Methods
    
    /// Check if view controller visible.
    ///
    /// - returns: True if visible. False otherwise.
    ///
    func viewControllerVisible() -> Bool {
        return self.viewAppeared
    }
    
    // MARK: Private Methods
    
    private func setupImageView() {
        let imageView = UIImageView.init(frame: self.view.frame)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = .clear
        imageView.isHidden = true
        self.view.addSubview(imageView)
        
        var constraints: [NSLayoutConstraint] = []
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[imageView]-0-|", options: NSLayoutFormatOptions.init(rawValue: 0), metrics: nil, views: ["imageView" : imageView])
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[imageView]-0-|", options: NSLayoutFormatOptions.init(rawValue: 0), metrics: nil, views: ["imageView" : imageView])
        NSLayoutConstraint.activate(constraints)
        
        self.imageView = imageView
    }
    
    private func setupSwipeToDismiss() {
        let dismissSwipe = UISwipeGestureRecognizer(target: self, action: #selector(dismissSwipeAction(_:)))
        dismissSwipe.direction = [UISwipeGestureRecognizerDirection.up, UISwipeGestureRecognizerDirection.down]
        self.view.addGestureRecognizer(dismissSwipe)
    }
    
    private func apply(_ image: UIImage?) {
        if image == nil {
            self.showsPlaybackControls = self.isReadyForDisplay
            self.imageView?.image = nil
            self.imageView?.isHidden = true
        } else {
            if self.viewAppeared {
                self.showsPlaybackControls = false
                self.imageView?.image = image
                self.imageView?.isHidden = false
            }
        }
    }
    
    // MARK: Controls Actions
    
    @objc private func dismissSwipeAction(_ sender: UISwipeGestureRecognizer) {
        self.dismiss(animated: true, completion: nil)
    }

}
