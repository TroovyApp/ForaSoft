//
//  CourseImageViewController.swift
//  troovy-ios
//
//  Created by Daniil on 10.10.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class CourseImageViewController: TroovyViewController {
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var imageView: UIImageView!
    
    // MARK: Public Properties
    
    var image: UIImage? {
        didSet {
            self.apply(self.image)
        }
    }
    
    // MARK: Init Methods & Superclass Overriders

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.apply(self.image)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: Private Methods
    
    private func apply(_ image: UIImage?) {
        if image == nil {
            self.imageView?.image = nil
        } else {
            if self.viewAppeared {
                self.imageView?.image = image
            }
        }
    }

}
