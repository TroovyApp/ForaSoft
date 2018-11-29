//
//  CoursesIdentifiersModel.swift
//  troovy-ios
//
//  Created by Daniil on 31.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import Foundation

struct CoursesIdentifiersModel {
    
    // MARK: Properties
    
    /// Courses identifiers to load.
    private(set) var identifiersToLoad: [String]!
    
    /// Courses identifiers to fetch.
    private(set) var identifiersToFetch: [String]!
    
    /// Determines should or should not load next page.
    private(set) var shouldLoadNextPage: Bool
    
    /// Service model with listType and methodType.
    private(set) var coursesServiceModel: CoursesServiceModel!

    // MARK: Methods
    
    /// Initializes structure with properties.
    ///
    /// - parameter dictionary: Saved course dictionary.
    ///
    init(withIdentifiersToLoad identifiersToLoad:[String], identifiersToFetch: [String], shouldLoadNextPage: Bool, coursesServiceModel: CoursesServiceModel) {
        self.identifiersToLoad = identifiersToLoad
        self.identifiersToFetch = identifiersToFetch
        self.shouldLoadNextPage = shouldLoadNextPage
        self.coursesServiceModel = coursesServiceModel
    }
    
}
