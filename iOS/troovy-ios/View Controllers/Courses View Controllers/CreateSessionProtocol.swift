//
//  CreateSessionProtocol.swift
//  troovy-ios
//
//  Created by Daniil on 28.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import Foundation
import UIKit

protocol CreateSessionDelegate: class {
    
    /// Reports that course session changed.
    ///
    /// - parameter view: View controller which called this method.
    /// - parameter model: Model that changed.
    ///
    func sessionView(view: UIViewController, didChangeCourseSessionModel model: CourseSessionModel)
    
    /// Reports that course session created.
    ///
    /// - parameter view: View controller which called this method.
    /// - parameter model: Model that created.
    ///
    func sessionView(view: UIViewController, didCreateCourseSessionModel model: CourseSessionModel)
    
    /// Asks for checking that new session doesn't conflict with others.
    ///
    /// - parameter view: View controller which called this method.
    /// - parameter model: Model that created.
    ///
    func sessionView(view: UIViewController, checkNewSessionModelDoesNotConflictWithOthers model: CourseSessionModel) -> Bool
    
    /// Asks for current course ID.
    ///
    /// - parameter view: View controller which called this method.
    /// - returns: Course server ID if exists.
    ///
    func sessionViewSelectedCourseID(view: UIViewController) -> String?
    
}
