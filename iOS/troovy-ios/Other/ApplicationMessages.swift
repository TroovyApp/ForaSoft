//
//  ApplicationMessages.swift
//  troovy-ios
//
//  Created by Daniil on 17.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import Foundation

struct ApplicationMessages {
    
    struct SuccessMessages {
        static let report = "The complaint has been sent. Thank you for your vigilance."
        
        static func notEnoughMoney(withValueString valueString: String) -> String {
            return "You need to add more funds to your wallet. Would you like to buy workshop with your balance and additionaly pay \(valueString) from your bank card?"
        }
        
        static func successfulPurchase(withCourseName courseName: String, author: String, email: String) -> String {
            return "Thank you for ordering the \(courseName) workshop by \(author). The notification was sent to \(email)."
        }
        
        static let subscribed = "You have successfully subscribed to the workshop."
        
        static let sessionCancelled = "You have successfully cancelled the session."
        static let courseDeleted = "You have successfully deleted the workshop."
    }
    
    struct ErrorMessages {
        static let mediaPermissions = "Please grant the permission in the phone settings to complete the action."
        static let streamPermissions = "You cannot start session without media permissions."
        
        static let exportFailed = "File exporting failed"
        
        static let wrongBankCard = "bank card information is not valid"
        static let wrongWallet = "not enough money"
        static let wrongAmount = "amount of dollars to withdraw should not be empty"
        
        static let wrongPhoneNumber = "phone number should not be empty"
        static let wrongCallingCode = "country code should not be empty"
        static let wrongRegionCode = "region code should not be empty"
        
        static let wrongVerificationCode = "verification code should not be empty"
        
        static let wrongCourseTitle = "workshop title should not be empty"
        static let wrongCourseDescription = "workshop description should not be empty"
        static let wrongCourseSessionsTiming = "all sessions should be scheduled for the future"
        static let wrongCourseData = "workshop data not found"
        
        static func wrongCoursePrice(withMinCount minPrice: Int) -> String {
            return "workshop price should be greater than \(minPrice)"
        }
        
        static func wrongCourseSessionsCount(withMinCount minCount: Int) -> String {
            return "workshop should contain at least \(minCount) \(minCount == 1 ? "session" : "sessions")"
        }
        
        static let wrongSessionTiming = "Session start and end time is conflicting with other sessions in this workshop."
        static let wrongSessionTitle = "session title should not be empty"
        static let wrongSessionDescription = "session description should not be empty"
        static func wrongSessionTime(withMinTime minTime: Int) -> String {
            return "session time should be at least \(minTime) minutes later than now"
        }
        static let wrongSessionDuration = "session duration should not be empty"
        
        static let wrongUsername = "username should not be empty"
        static func wrongUsernameLength(withMinLength minLength: Int, maxLength: Int) -> String {
            return "username should contain at least \(minLength) symbols and no more than \(maxLength) symbols"
        }
        
        static let wrongEmail = "Email address is not valid"
        
        static let requestTimedOut = "Server isn't reachable. Please, try again later."
        static let internetNotReachable = "Please, check your internet connection."
        static let serverError = "Oops application error, our team is working on it. Please try again later."
        
        static let sessionFinished = "Session already finished."
        static let forceLogout = "You have been logged out from the session. Please try again."
        
        static func wrongCourseVideoSize(withMaxSize size: Int) -> String {
            return "video should not be more than \(size) MB"
        }
        static func wrongCourseVideoDuration(withMinDuration duration: Double) -> String {
            return "video should not last less than \(duration.tailingZeros()) \(duration < 2.0 ? "session" : "sessions")"
        }
        
        static let wrongReportReason = "report reason should not be empty"
        static let unableCourseCreate = "unable to publish course"
    }
    
    struct AlertTitles {
        static let finishSession = "Are you sure you want to finish this session?"
        
        static let deleteCourse = "Are you sure you want to delete this workshop?"
        static let cancelSession = "Are you sure you want to cancel this session?"
        
        static let sessionFinished = "Session completed"
        static let sessionStopped = "Session stopped"
        
        static let cameraPermissionDenied = "Camera permission denied"
        static let microphonePermissionDenied = "Microphone permission denied"
        static let cameraAndMicrophonePermissionDenied = "Camera and microphone permission denied"
        static let photosPermissionDenied = "Photos permission denied"
        
        static let error = "Error!"
        
        static let message = "An error has occurred"
        static let sessionItNotStarted = "Unable to start streaming"
        static let messages = "Please, ensure the following is correct:"
        
        static let chooseAction = "Choose the action:"
        
        static let success = "Success"
        static let wrongEmail = "Wrong email address"
        
        static let notEnoughMoney = "Not enough money"
    }
    
    struct AlertButtonsTitles {
        static let yes = "Yes"
        static let no = "No"
        
        static let close = "Close"
        static let retry = "Retry"
        
        static let ok = "Ok"
        
        static let settings = "Settings"
        
        static let buy = "Buy"
        
        static let camera = "Take from Camera"
        static let cameraRoll = "Choose from Photos"
        
        static let play = "Play"
        static let delete = "Delete"
        
        static let editSession = "Edit session"
        static let cancelSession = "Cancel session"
        
        static let reportCourse = "Report workshop"
        static let shareCourse = "Share workshop"
        static let editCourse = "Edit workshop"
        static let deleteCourse = "Delete workshop"
    }
    
    struct ButtonsTitles {
        static let done = "DONE"
        
        static let save = "Save"
        static let actions = "Actions"
        static let close = "Cancel"
        
        static let next = "NEXT"
        static let publish = "PUBLISH"
        
        static let courseAttachments = "Workshop Attachments"
        static let courseSessions = "Workshop Sessions"
        
        static let subscribe = "SUBSCRIBE"
        static let attachments = "ATTACHMENTS"
        static let register = "REGISTRATION"
        static let getStarted = "GET STARTED"
        
        static let createSession = "Add session"
        
        static let live = "LIVE"
        static let ready = "READY"
        static let wait = "WAIT"
        
        static let payWithBalance = "Pay with balance"
        static let payWithWallet = "Pay with wallet"
        
    }
    
    struct Instructions {
        static func requestCode(withSecondsLeft seconds: String) -> String {
            return "You will be able to resend code in \(seconds) seconds"
        }
        
        static let courseSchedule = "Workshop schedule"
        static let enterEmail = "Please enter your email to confirm subscription."
        static let enterEmailPlaceholder = "Email"
        
        static let ownerSessionFinished = "Your session was finished."
        static let viewerSessionFinished = "Session was finished."
        static let courseValidation = "Saving workshop..."
        static let sendingEmailConfirmation = "Sending receipt..."
        static let loadingPriceList = "Loading price list..."
        
        static let verifyUnauthorisedPhoneNumber = "The validation code has been sent to your\nphone number"
        
        static let tutorialTitles: [String] = ["CREATE", "SHARE", "GO ONLINE", "SEARCH"]
        static let tutorialMessages: [String] = ["Use Create button to make and schedule your own workshop",
                                                 "Let your subscribers know about your workshop with automatically created landing page",
                                                 "Troovy will remind you when to go online for your first Session. You’ll get paid immediately after that",
                                                 "Explore the best and the most interesting experts from all around the world"]
        
        static func enterSessionMessage(withMinutesLeft minutesLeft: Int) -> String {
            return "You will be able to enter the session \(minutesLeft) minutes before session scheduled start time"
        }
        
        static func enterSessionUnregisteredMessage(withMinutesLeft minutesLeft: Int) -> String {
            return "After registration you will be able to enter the session \(minutesLeft) minutes before session scheduled start time."
        }
        
        static let sessionConnecting = "Connecting to the session"
        static let streamConnecting = "Connecting to the stream"
        
        static let undone = "This action cannot be undone."
        
        static let subscribedCoursesEmptyMessage = "Are you ready to explore the best experts knowledge? Switch to a Featured tab"
        static let allCoursesEmptyMessage = "No workshops were found"
        static let ownCoursesEmptyMessage = "Are you ready to share your expert knowledge? Create your first workshop in a few steps"
    }
    
    struct ScreenTitles {
        static let unauthorisedScreen = "Authorisation"
        static let verificationScreen = "Verification"
        static let registrationScreen = "Registration"
        
        static let coursesHomeScreen = "Workshops"
        static let scheduleHomeScreen = "Sessions"
        static let settingsHomeScreen = "Profile"
        
        static let editProfileScreen = "Edit Profile"
        
        static let createCourseScreen = "New Workshop"
        static let editCourseScreen = "Edit Workshop"
        static let createCourseStatusSavedUnpublished = "Saved, Not Published"
        static let courseScreen = "Workshop Info"
        static let sessionsScreen = "Sessions"
        static let attachmentsScreen = "Workshop attachments"
        
        static let createSessionScreen = "New Session"
        static let editSessionScreen = "Edit Session"
        static let sessionScreen = "Session"
        
        static let buyCourseScreen = "Buy Workshop"
        
        static let balanceScreen = "Balance"
    }
    
}
