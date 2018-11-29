//
//  ButtonWithOriginalImage.swift
//  troovy-ios
//
//  Created by Daniil on 18.09.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class ButtonWithOriginalImage: RoundedButton {

    // MARK: Init Methods & Superclass Overriders
    
    override func setImage(_ image: UIImage?, for state: UIControlState) {
        if let originalImage = image?.withRenderingMode(.alwaysOriginal) {
            super.setImage(originalImage, for: state)
        } else {
            super.setImage(image, for: state)
        }
    }

}
