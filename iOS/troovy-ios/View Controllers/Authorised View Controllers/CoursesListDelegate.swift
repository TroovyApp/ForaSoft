//
//  CoursesListDelegate.swift
//  troovy-ios
//
//  Created by Daniil on 31.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import Foundation
import UIKit

protocol CoursesListDelegate: class {
    
    /// Asks for fetching last courses from core data and reloading course after that.
    ///
    /// - parameter list: View controller which called this method.
    /// - parameter type: Courses list type.
    ///
    func coursesList(list: UIViewController, initiateFetchingLastCoursesWithListType type: CourseListProperties.CourseListType)
    
    /// Asks for loading more courses.
    ///
    /// - parameter list: View controller which called this method.
    /// - parameter type: Courses list type.
    ///
    func coursesList(list: UIViewController, initiateLoadingMoreCoursesWithListType type: CourseListProperties.CourseListType)
    
    /// Asks for reloading courses.
    ///
    /// - parameter list: View controller which called this method.
    /// - parameter type: Courses list type.
    ///
    func coursesList(list: UIViewController, initiateReloadingCoursesWithListType type: CourseListProperties.CourseListType)
    
    /// Asks for showing error.
    ///
    /// - parameter list: View controller which called this method.
    /// - parameter error: Error message.
    /// - parameter type: Courses list type.
    ///
    func coursesList(list: UIViewController, initiateShowingError error: String?, withListType type: CourseListProperties.CourseListType)
    
    /// Asks for showing error.
    ///
    /// - parameter list: View controller which called this method.
    /// - parameter course: Course model.
    /// - parameter type: Courses list type.
    ///
    func coursesList(list: UIViewController, initiateShowingCourse course: CourseModel, withListType type: CourseListProperties.CourseListType)
    
    /// Says that collection view did scroll.
    ///
    /// - parameter list: View controller which called this method.
    /// - parameter collectionView: Scrolled collection view.
    /// - parameter type: Courses list type.
    ///
    func coursesList(list: UIViewController, didScrollCollectionView collectionView: UICollectionView, withListType type: CourseListProperties.CourseListType)
    
    /// Says that new course button was pressed
    ///
    /// - parameter list: View controller which called this method.
    ///
    func coursesListInitiateCreatingNewCourse(list: UIViewController)
    
    /// Says that type of course should be changed
    ///
    /// - parameter list: View controller which called this method.
    /// - parameter type: Courses list type.
    ///
    func coursesList(list: UIViewController, initiateSwitchingToListType type: CourseListProperties.CourseListType)
    
}

// Optional methods
extension CoursesListDelegate {
    
    func coursesListInitiateCreatingNewCourse(list: UIViewController) {}
    
    func coursesList(list: UIViewController, initiateSwitchingToListType type: CourseListProperties.CourseListType) {}
}
