//
//  CoursesModel.swift
//  troovy-ios
//
//  Created by Daniil on 31.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import Foundation

struct CoursesModel {
    
    // MARK: Properties
    
    /// Courses to show.
    private(set) var courses: [CourseModel]!
    
    /// Service model with listType and methodType.
    private(set) var coursesServiceModel: CoursesServiceModel!
    
    // MARK: Methods
    
    /// Initializes structure with properties.
    ///
    /// - parameter dictionary: Saved course dictionary.
    ///
    init(withCourses courses:[CourseModel], coursesServiceModel: CoursesServiceModel) {
        self.courses = courses
        self.coursesServiceModel = coursesServiceModel
    }
    
}
