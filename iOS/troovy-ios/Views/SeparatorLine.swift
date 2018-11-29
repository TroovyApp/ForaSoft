//
//  SeparatorLine.swift
//  troovy-ios
//
//  Created by Daniil on 18.09.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class SeparatorLine: UIImageView {
    
    // MARK: Init Methods & Superclass Overriders
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentMode = .scaleToFill
        self.clipsToBounds = true
        
        let image = UIImage.image(fromColor: self.backgroundColor ?? .white)
        self.image = image
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.contentMode = .scaleToFill
        self.clipsToBounds = true
        
        let image = UIImage.image(fromColor: self.backgroundColor ?? .white)
        self.image = image
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        
        self.contentMode = .scaleToFill
        self.clipsToBounds = true
        
        let image = UIImage.image(fromColor: self.backgroundColor ?? .white)
        self.image = image
    }

    // MARK: Public Methods
    
    /// Creates new image from color and uses it as background.
    ///
    /// - parameter color: New background color.
    ///
    func changeColor(_ color: UIColor) {
        let image = UIImage.image(fromColor: color)
        self.image = image
    }

}
