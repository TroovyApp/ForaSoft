//
//  UserVerificationViewController.swift
//  troovy-ios
//
//  Created by Daniil on 18.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class UserVerificationViewController: PhoneVerificationViewController {
    
    // MARK: Init Methods & Superclass Overriders
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func verificationSucceeded(withResult result: [String : Any]) {
        if result.count > 0 {
            let authorisedUserModel = AuthorisedUserModel(withDictionary: result)
            self.authorisedUserService.rememberUser(withUserModel: authorisedUserModel)
            self.router.showAuthorisedViewController(withAuthorisedUserModel: authorisedUserModel)
        } else {
            self.router.showRegistrationViewController(withUnauthorisedUserModel: self.unauthorisedUserModel!)
        }
    }

}
