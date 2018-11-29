//
//  TroovyStoryboard.swift
//  troovy-ios
//
//  Created by Daniil on 11.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class TroovyStoryboard: UIStoryboard {
    
    private enum StoryboardError: Error {
        case createFailed(storyboardID: String)
    }
    
    private enum StoryboardType: String {
        case launch = "LaunchStoryboard"
        case unauthorised = "UnauthorisedStoryboard"
        case authorised = "AuthorisedStoryboard"
        case courses = "CoursesStoryboard"
        case schedule = "ScheduleStoryboard"
        case settings = "SettingsStoryboard"
    }
    
    private struct StoryboardViewControllers {
        static let launchViewControllers = ["LaunchViewController",
                                            "TutorialViewController"]
        
        static let unauthorisedViewControllers = ["UnauthorisedViewController",
                                                  "UserVerificationViewController",
                                                  "RegistrationViewController"]
        
        static let authorisedViewControllers = ["AuthorisedViewController",
                                                "OtherProfileViewController"]
        
        static let coursesViewControllers = ["CreateCourseViewController",
                                             "CreateSessionViewController",
                                             "CommonCourseViewController",
                                             "OwnCourseViewController",
                                             "CourseAttachmentsViewController",
                                             "UploadAttachmentViewController",
                                             "EditCourseViewController",
                                             "ReportCourseViewController",
                                             "CoursePaymentViewController",
                                             "CourseNotEnoughMoneyViewController",
                                             "UploadCourseIntroViewController",
                                             "CourseImagePickerViewController",
                                             "CreateSessionModelViewController"]
        
        static let scheduleViewControllers = ["SessionPageViewController",
                                              "VideoStreamViewController",
                                              "FinishedStreamViewController",
                                              "SessionAttachmentsViewController",
                                              "SessionAttachmentViewController"]
        
        static let settingsViewControllers = ["CreditsViewController",
                                              "WithdrawalCardViewController",
                                              "EditProfileViewController"]
    }
    
    // MARK: Class Methods
    
    /// Initializes storyboard. Throws error if occurs.
    ///
    /// - parameter storyboardID: Storyboard ID of the view controller.
    /// - returns: Storyboard which contains view controller with passed storyboard ID.
    ///
    class func storyboard(forStoryboardID storyboardID: String) throws -> UIStoryboard {
        if StoryboardViewControllers.launchViewControllers.index(of: storyboardID) != nil {
            return UIStoryboard(name: StoryboardType.launch.rawValue, bundle: Bundle.main)
        } else if StoryboardViewControllers.unauthorisedViewControllers.index(of: storyboardID) != nil {
            return UIStoryboard(name: StoryboardType.unauthorised.rawValue, bundle: Bundle.main)
        } else if StoryboardViewControllers.authorisedViewControllers.index(of: storyboardID) != nil {
            return UIStoryboard(name: StoryboardType.authorised.rawValue, bundle: Bundle.main)
        }  else if StoryboardViewControllers.coursesViewControllers.index(of: storyboardID) != nil {
            return UIStoryboard(name: StoryboardType.courses.rawValue, bundle: Bundle.main)
        } else if StoryboardViewControllers.scheduleViewControllers.index(of: storyboardID) != nil {
            return UIStoryboard(name: StoryboardType.schedule.rawValue, bundle: Bundle.main)
        } else if StoryboardViewControllers.settingsViewControllers.index(of: storyboardID) != nil {
            return UIStoryboard(name: StoryboardType.settings.rawValue, bundle: Bundle.main)
        }
        
        throw(StoryboardError.createFailed(storyboardID: storyboardID))
    }

}
