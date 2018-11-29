//
//  CourseBackgroundView.swift
//  troovy-ios
//
//  Created by Daniil on 24.10.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit
import AVKit

import Kingfisher

class CourseBackgroundView: UIView {
    
    // MARK: Private Properties
    
    private let infoPlistService = InfoPlistService()
    
    private var imageView = UIImageView()
    private var videoView = UIView()
    
    private var players: [URL:AVPlayer] = [:]
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    
    private var introTimer: Timer?
    private var introTimeLeft = 0.0
    
    private var intros: [CourseIntroModel] = []
    private var introIndex: Int = 0
    
    private var introPaused = false
    private var playerMuted = true
    private var playerItemActive = false
    
    private weak var pageControl: UIPageControl?
    
    // MARK: Init Methods & Superclass Overriders
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive(_:)), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(_:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
        self.setupContainers()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.playerLayer?.frame = self.videoView.bounds
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Notifications & Observers
    
    @objc private func playerItemDidReachEnd(_ notification: Notification) {
        self.introIndex += 1
        self.showIntro()
    }
    
    @objc private func applicationWillResignActive(_ notification: Notification) {
        self.player?.pause()
        
        self.introTimer?.invalidate()
        self.introTimer = nil
    }
    
    @objc private func applicationDidBecomeActive(_ notification: Notification) {
        if !self.introPaused {
            if self.playerItemActive {
                self.player?.play()
            } else {
                self.runIntroTimer()
            }
        }
    }
    
    // MARK: Public Methods
    
    /// Setups background with intros.
    ///
    /// - parameter intros: Course intro models.
    ///
    func setup(withIntros intros: [CourseIntroModel]?, pageControl: UIPageControl?) {
        self.pageControl = pageControl
        
        if let models = intros, models.count > 0 {
            self.intros = models
            self.introIndex = 0
        } else {
            self.intros = []
            self.introIndex = 0
        }
        
        self.showIntro()
    }
    
    /// Changes intro muted state.
    func changeIntroMuted() {
        self.playerMuted = !(self.player?.isMuted ?? true)
        
        if !self.playerMuted {
            try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: [])
        }
        
        self.player?.isMuted = self.playerMuted
    }
    
    /// Shows next intro.
    func showNextIntro() {
        self.introIndex += 1
        self.showIntro()
    }
    
    /// Shows previous intro.
    func showPreviousIntro() {
        self.introIndex -= 1
        self.showIntro()
    }
    
    /// Plays or pauses intros.
    ///
    /// - parameter paused: Pauses intros if true. Plays it otherwise.
    ///
    func setIntrosPaused(_ paused: Bool) {
        self.introPaused = paused
        
        if paused {
            self.player?.pause()
            
            self.introTimer?.invalidate()
            self.introTimer = nil
        } else {
            if self.playerItemActive {
                self.player?.play()
            } else {
                self.runIntroTimer()
            }
        }
    }
    
    // MARK: Private Methods
    
    private func setupContainers() {
        self.imageView.frame = self.bounds
        self.imageView.translatesAutoresizingMaskIntoConstraints = false
        self.imageView.contentMode = .scaleAspectFill
        self.imageView.clipsToBounds = true
        self.addSubview(self.imageView)
        
        self.videoView.frame = self.bounds
        self.videoView.translatesAutoresizingMaskIntoConstraints = false
        self.videoView.clipsToBounds = true
        self.addSubview(self.videoView)
        
        var constraints: [NSLayoutConstraint] = []
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[imageView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["imageView" : self.imageView])
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[imageView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["imageView" : self.imageView])
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[videoView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["videoView" : self.videoView])
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[videoView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["videoView" : self.videoView])
        NSLayoutConstraint.activate(constraints)
    }
    
    // MARK: Show Intros
    
    private func runIntroTimer() {
        if self.introTimer != nil {
            return
        }
        
        self.introTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { [weak self] (timer) in
            DispatchQueue.main.async {
                self?.introTimeLeft -= 0.1
                
                if self?.introTimeLeft ?? 0.0 <= 0.0 {
                    self?.stopIntroTimerAndShowNextIntro()
                }
            }
        })
    }
    
    private func stopIntroTimerAndShowNextIntro() {
        self.introIndex += 1
        self.showIntro()
    }
    
    private func showIntro() {
        self.removeImage()
        self.removePlayer()
        
        if self.introIndex >= self.intros.count {
            self.introIndex = 0
        } else if self.introIndex < 0 {
            self.introIndex = 0
        }
        
        self.pageControl?.numberOfPages = self.intros.count
        self.pageControl?.currentPage = self.introIndex
        
        if self.introIndex < self.intros.count {
            let serverAddress = self.infoPlistService.serverURL()
            let intro = self.intros[self.introIndex]
            let videoURL = URL.address(byAppendingServerAddress: serverAddress, toContentPath: (intro.type == .video ? intro.fileAddress : nil))
            let imageURL = URL.address(byAppendingServerAddress: serverAddress, toContentPath: (intro.type == .video ? intro.thumbnailAddress : intro.fileAddress))
            
            if let url = imageURL {
                let imageResource = ImageResource(downloadURL: url)
                
                if videoURL != nil {
                    self.imageView.kf.setImage(with: imageResource)
                } else {
                    self.imageView.kf.setImage(with: imageResource, placeholder: nil, options: nil, progressBlock: nil) { [weak self] (loadedImage, error, cacheType, url) in
                        self?.runIntroTimer()
                    }
                }
            }
            
            if let url = videoURL {
                if let savedPlayer = self.players[url] {
                    self.player = savedPlayer
                } else {
                    let player = AVPlayer(url: url)
                    self.players[url] = player
                    self.player = player
                }
                
                self.player?.isMuted = self.playerMuted
                
                if let item = self.player?.currentItem {
                    NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: item)
                }
                
                self.playerLayer = AVPlayerLayer(player: self.player)
                self.playerLayer?.videoGravity = .resizeAspectFill
                self.playerLayer?.frame = self.videoView.bounds
                if let playerLayer = self.playerLayer {
                    self.videoView.layer.addSublayer(playerLayer)
                }
                
                self.player?.play()
                self.playerItemActive = true
            }
        } else {
            self.imageView.image = UIImage.tv_courseBacgroundPlaceholder()
        }
    }
    
    private func removePlayer() {
        if let item = self.player?.currentItem {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: item)
        }
        
        self.playerLayer?.removeFromSuperlayer()
        self.playerLayer = nil
        
        self.player?.pause()
        self.player?.currentItem?.seek(to: kCMTimeZero)
        self.playerItemActive = false
    }
    
    private func removeImage() {
        self.imageView.kf.cancelDownloadTask()
        self.imageView.image = nil
        
        self.introTimer?.invalidate()
        self.introTimer = nil
        
        self.introTimeLeft = 2.0
    }

}
