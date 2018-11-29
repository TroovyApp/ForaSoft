//
//  CreateCourseProtocol.swift
//  troovy-ios
//
//  Created by Daniil on 25.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

protocol CreateCourseDelegate: class {
    
    /// Asks for current unfinished course model.
    ///
    /// - returns: Model to change.
    ///
    func currentCourseModel() -> UnfinishedCourseModel
    
    /// Reports that unfinished course model changed.
    ///
    /// - parameter page: View controller which called this method.
    /// - parameter model: Model that changed.
    ///
    func coursePage(page: UIViewController, didChangeCourseModel model: UnfinishedCourseModel)
    
    /// Reports that unfinished course image changed.
    ///
    /// - parameter page: View controller which called this method.
    /// - parameter content: Array of images and/or video urls.
    /// - parameter model: Model that changed.
    /// - parameter index: Model changed media index.
    ///
    func coursePage(page: UIViewController, didChangeCourseWithContent content: [Any], forCourseModel model: UnfinishedCourseModel, mediaIndex: Int)
    
    /// Reports that next button pressed.
    ///
    /// - parameter page: View controller which called this method.
    ///
    func coursePageWantsNextPage(page: UIViewController)
    
    /// Asks for opening session for editing or creating new.
    ///
    /// - parameter page: View controller which called this method.
    /// - parameter model: Model for editing. Can be nil.
    ///
    func coursePage(page: UIViewController, shouldOpenSessionModel model: CourseSessionModel?)
    
    /// Asks for create course without publish it.
    ///
    /// - parameter page: View controller which called this method.
    ///
    func coursePageShouldCreateCourse(page: UIViewController)
    
    /// Asks for create course with publish it.
    ///
    /// - parameter page: View controller which called this method.
    ///
    func coursePageShouldPublishCourse(page: UIViewController)
    
    /// Asks if course ready for publish.
    ///
    /// - parameter page: View controller which called this method.
    /// - returns: True if course ready for publish. False otherwise.
    ///
    func coursePageReadyForPublish(page: UIViewController) -> Bool
    
    /// Asks for show UIImagePickerController.
    ///
    /// - parameter page: View controller which called this method.
    ///
    func coursePageShouldTakeCoursePreviewFromCamera(page: UIViewController)
    func coursePageShouldTakeCoursePreviewFromCameraRoll(page: UIViewController, replacingExistOne: Bool, didSelect: ((_ assets: [DKAsset]) -> Void)?)
    
    /// Asks for show/hide loading view.
    func coursePageShouldShowLoadingView()
    func coursePageShouldHideLoadingView()
    
    /// Asks for check video from library or camera.
    ///
    /// - parameter page: View controller which called this method.
    /// - parameter info: UIImagePickerController result dictionary.
    /// - returns: Error message or nil.
    ///
    func coursePage(page: UIViewController, checkVideoWithPickerInfo info: [String:Any]) -> String?
    
    /// Asks for show alert with messages.
    ///
    /// - parameter page: View controller which called this method.
    /// - parameter messages: Array of the errors messages.
    ///
    func coursePage(page: UIViewController, shouldShowAlertWithMessages messages: [String])
    
    /// Asks for show alert with messages.
    ///
    /// - parameter page: View controller which called this method.
    /// - parameter message: Errors message.
    ///
    func coursePage(page: UIViewController, shouldShowAlertWithMessage message: String)
    
    /// Asks for commission percentage.
    ///
    /// - parameter page: View controller which called this method.
    ///
    func coursePageRequestСommissionPercentage(page: UIViewController) -> Double
    
}
