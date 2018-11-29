//
//  CoursesServiceModel.swift
//  troovy-ios
//
//  Created by Daniil on 31.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import Foundation

struct CoursesServiceModel {
 
    // MARK: Properties
    
    /// Type of the course list view controller which should receive this model.
    private(set) var listType: CourseListProperties.CourseListType
    
    /// Type of the course list method which began creation of model.
    private(set) var methodType: CourseListProperties.CourseListMethodType
    
}
