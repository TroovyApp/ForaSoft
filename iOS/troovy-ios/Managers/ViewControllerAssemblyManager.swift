//
//  ViewControllerAssemblyManager.swift
//  troovy-ios
//
//  Created by Daniil on 17.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import Foundation
import UIKit

class ViewControllerAssemblyManager {
    
    // MARK: Private Methods
    
    lazy var authorisedUserService = AuthorisedUserService()
    
    lazy var countryListDataService = CountryListDataService()
    
    lazy var verificationService = VerificationService()
    
    lazy var unauthorisedUserService = UnauthorisedUserService()
    
    lazy var createCoursesService = CreateCoursesService()
    
    lazy var coursesService = CoursesService()
    
    lazy var paymentService = PaymentService()
    
    lazy var videoStreamService = VideoStreamService()
    
    lazy var applicationService = ApplicationService()

    // MARK: Public Methods
    
    /// Injects services in passed view controller.
    ///
    /// - parameter viewController: View controller to inject services.
    ///
    func configure(viewController: UIViewController) {
        if viewController is TroovyViewController {
            let troovyViewController = viewController as! TroovyViewController
            troovyViewController.inject(propertiesWithAssembly: self)
        }
    }
    
}
