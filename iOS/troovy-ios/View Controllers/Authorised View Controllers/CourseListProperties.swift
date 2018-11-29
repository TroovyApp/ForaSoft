//
//  CourseListProperties.swift
//  troovy-ios
//
//  Created by Daniil on 30.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import Foundation

struct CourseListProperties {
    
    let countOfCoursesIdentifiersPerPage = 1000
    let countOfCoursesPerPage = 30
    
    enum CourseListType: Int {
        case subscribed = 0
        case all
        case own
        case other
    }
    
    enum CourseListMethodType: Int {
        case fetchLastCourses = 0
        case reloadCourses
        case loadMoreCourses
        case addNewCourses
        case deleteCourse
    }
    
}
