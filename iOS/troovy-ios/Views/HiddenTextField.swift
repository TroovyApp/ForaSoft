//
//  HiddenTextField.swift
//  troovy-ios
//
//  Created by Daniil on 18.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

@IBDesignable class HiddenTextField: TextFieldWithoutActions {

    // MARK: Init Methods & Superclass Overriders
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
        self.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
        self.tintAdjustmentMode = .normal
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
        self.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
        self.tintAdjustmentMode = .normal
    }

}
