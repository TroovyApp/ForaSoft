//
//  ScheduleRouter.swift
//  troovy-ios
//
//  Created by Daniil on 23.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class ScheduleRouter: TroovyRouter {
    
    /// Initialises router with parent router.
    ///
    /// - parameter parentRouter: Router which is showing this router.
    /// - parameter navigationController: Root navigation controller.
    ///
    convenience init(parentRouter: TroovyRouter, navigationController: UINavigationController) {
        self.init(parentRouter: parentRouter)
        
        self.rootNavigationController = navigationController
    }
    
}
