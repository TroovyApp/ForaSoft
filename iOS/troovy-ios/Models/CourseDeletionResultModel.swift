//
//  CourseDeletionResultModel.swift
//  troovy-ios
//
//  Created by Daniil on 19.10.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import Foundation

struct CourseDeletionResultModel {
    
    private struct Keys {
        static let error  = "error"
        static let message = "message"
    }
    
    // Properties
    
    var requireUserAction = false
    var message: String?
    
    // MARK: Init Methods & Superclass Overriders
    
    init(withDictionary dictionary: [String:Any]?) {
        if let error = dictionary?[Keys.error] as? [String:Any] {
            self.requireUserAction = true
            self.message = error[Keys.message] as? String
        } else {
            self.requireUserAction = false
            self.message = nil
        }
    }
    
}
