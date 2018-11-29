//
//  TutorialPageViewController.swift
//  troovy-ios
//
//  Created by Daniil on 23.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class TutorialPageViewController: UIViewController {
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var tutorialImageView: UIImageView!
    @IBOutlet weak var tutorialTitleLabel: UILabel!
    @IBOutlet weak var tutorialMessageLabel: UILabel!
    
    // MARK: Private Properties
    
    private var tutorialTitle: String?
    private var tutorialMessage: String?
    private var tutorialImage: UIImage?
    
    private var viewAppeared = false

    // MARK: Init Methods & Superclass Overriders
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.configure()
        self.viewAppeared = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.viewAppeared = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: Public Methods
    
    /// Configures tutorial page with text and image.
    ///
    /// - parameter title: Title for this tutorial page.
    /// - parameter message: Message for this tutorial page.
    /// - parameter image: Image for this tutorial page.
    ///
    func configure(withTitle title: String?, message: String?, image: UIImage?) {
        self.tutorialTitle = title
        self.tutorialMessage = message
        self.tutorialImage = image
        
        if self.viewAppeared {
            self.configure()
        }
    }
    
    // MARK: Private Methods
    
    private func configure() {
        self.tutorialTitleLabel?.text = self.tutorialTitle
        self.tutorialMessageLabel?.text = self.tutorialMessage
        self.tutorialImageView?.image = self.tutorialImage
    }

}
