//
//  SessionAttachmentViewController.swift
//  troovy-ios
//
//  Created by Daniil on 10.11.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit
import MessageUI
import AVKit

class SessionAttachmentViewController: TroovyViewController {

    // MARK: Interface Builder Properties
    
    @IBOutlet weak var videoContainerView: UIView!
    
    // MARK: Public Properties
    
    /// Model of the unauthorised user.
    var authorisedUserModel: AuthorisedUserModel!
    
    /// Course attachment.
    var attachmentModel: CourseAttachmentModel!
    
    // MARK: Properties Overriders
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: Private Properties
    
    private let infoPlistService = InfoPlistService()
    private var videoStreamService: VideoStreamService!
    
    private var moviePlayer: TroovyPlayerViewController?
    
    // MARK: Init Methods & Superclass Overriders
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configurePlayerView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.videoStreamService.setSoundEnabled(enabled: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.moviePlayer?.player?.pause()
        self.videoStreamService.setSoundEnabled(enabled: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func inject(propertiesWithAssembly assembly: ViewControllerAssemblyManager) {
        self.videoStreamService = assembly.videoStreamService
    }
    
    // MARK: Private Methods
    
    private func configurePlayerView() {
        let serverAddress = self.infoPlistService.serverURL()
        let attachmentAddress = URL.address(byAppendingServerAddress: serverAddress, toContentPath: self.attachmentModel.fileAddress!)
        
        let player = AVPlayer.init(url: attachmentAddress!)
        player.automaticallyWaitsToMinimizeStalling = false
        
        self.moviePlayer = TroovyPlayerViewController()
        if let moviePlayer = self.moviePlayer {
            moviePlayer.player = player
            
            self.addChildViewController(moviePlayer)
            moviePlayer.beginAppearanceTransition(true, animated: true)
            moviePlayer.view.translatesAutoresizingMaskIntoConstraints = false
            self.videoContainerView.addSubview(moviePlayer.view)
            moviePlayer.endAppearanceTransition()
            moviePlayer.didMove(toParentViewController: self)
            
            let left = moviePlayer.view.leftAnchor.constraint(equalTo: self.videoContainerView.leftAnchor)
            let right = moviePlayer.view.rightAnchor.constraint(equalTo: self.videoContainerView.rightAnchor)
            let top = moviePlayer.view.topAnchor.constraint(equalTo: self.videoContainerView.topAnchor)
            let bottom = moviePlayer.view.bottomAnchor.constraint(equalTo: self.videoContainerView.bottomAnchor)
            
            let constraints = [left, right, top, bottom]
            NSLayoutConstraint.activate(constraints)
            
            player.play()
        }
    }
    
    // MARK: Controls Actions
    
    @IBAction func shareButtonAction( _ sender: UIButton) {
        let serverAddress = self.infoPlistService.serverURL()
        let attachmentAddress = URL.address(byAppendingServerAddress: serverAddress, toContentPath: self.attachmentModel.fileAddress!)
        
        let activityViewController = UIActivityViewController(activityItems: [attachmentAddress!], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        self.present(activityViewController, animated: true, completion: nil)
    }

}
