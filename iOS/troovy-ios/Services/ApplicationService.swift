//
//  ApplicationService.swift
//  troovy-ios
//
//  Created by Daniil on 31.10.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class ApplicationService: TroovyService {

    private struct UserDefaultsKeys {
        static let authorisedApplicationModel = "troovy_applicationModel"
    }
    
    // MARK: Private Proeprties
    
    private var applicationModel: ApplicationModel?
    
    private var courseToOpen: (CourseModel?, String)?
    
    // MARK: Init Methods & Superclass Overriders
    
    override init() {
        super.init()
        
        self.applicationModel = self.loadApplicationModel()
    }
    
    // MARK: Public Methods
    
    /// Returns application model.
    ///
    /// - returns: Saved application model or nil.
    ///
    func savedApplicationModel() -> ApplicationModel? {
        if let model = self.applicationModel {
            return model
        }
        
        return nil
    }
    
    /// Saves application model.
    ///
    /// - parameter dictionary: Application server dictionary.
    ///
    func updateAndSaveApplicationModel(withDictionary dictionary: [String:Any]) {
        self.applicationModel?.update(withDictionary: dictionary)
        
        if let model = self.applicationModel {
            self.saveApplicationModel(model)
        } else {
            let model = ApplicationModel(withDictionary: dictionary)
            self.applicationModel = model
            self.saveApplicationModel(model)
        }
    }
    
    /// Remembers course model and course server id.
    ///
    /// - parameter courseModel: Course model.
    /// - parameter courseID: Course server id.
    ///
    func rememberCourseToOpen(courseModel: CourseModel?, courseID: String) {
        self.courseToOpen = (courseModel, courseID)
    }
    
    /// Restores course model and course server id.
    ///
    /// - return: Tuple with course model and course server.
    ///
    func restoreCourseToOpen() -> (CourseModel?, courseID: String)? {
        guard let courseToOpen = self.courseToOpen else {
            return nil
        }
        
        let courseModel = courseToOpen.0
        let courseID = courseToOpen.1
        self.courseToOpen = nil
        return (courseModel, courseID)
    }
    
    // MARK: Private Methods
    
    private func loadApplicationModel() -> ApplicationModel? {
        if let dictionary = UserDefaults.standard.object(forKey: UserDefaultsKeys.authorisedApplicationModel) as? [String:Any] {
            let applicationModel = ApplicationModel(withDictionary: dictionary)
            return applicationModel
        } else {
            return nil
        }
    }
    
    private func saveApplicationModel(_ model: ApplicationModel) {
        let dictionary = model.modelAsDictionary()
        UserDefaults.standard.setValue(dictionary, forKey: UserDefaultsKeys.authorisedApplicationModel)
        UserDefaults.standard.synchronize()
    }
    
}
