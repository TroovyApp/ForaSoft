//
//  TextFieldWithoutActions.swift
//  troovy-ios
//
//  Created by Daniil on 17.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

@IBDesignable class TextFieldWithoutActions: RoundedTextField {

    // MARK: Init Methods & Superclass Overriders
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false
    }
    
    override func addGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer is UILongPressGestureRecognizer {
            gestureRecognizer.isEnabled = false
        }
        
        super.addGestureRecognizer(gestureRecognizer)
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UITapGestureRecognizer {
            if self.isFirstResponder {
                return false
            }
        }
        
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }

}
