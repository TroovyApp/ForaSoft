//
//  VerificationService.swift
//  troovy-ios
//
//  Created by Daniil on 11.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import Foundation
import AVFoundation

class VerificationService: TroovyService {
    
    private struct VerificationConstants {
        static let minNameLength = 2
        static let maxNameLength = 50
        
        static let verificationCodeLength = 5
        
        static let requestVerificationInterval = 60
        
        static let minCountOfSessionsInCourse = 1
        
        static let minCameraCourseVideoDuration = 1.0
        static let maximumLibraryCourseVideoSize = 350
        
        static let sessionEnterMinutesLeft = 10
        
        static let courseMinimumPrice = 0
    }
    
    // MARK: Public Methods
    
    /// Returns session enter minutes left.
    ///
    /// - returns: Session enter minutes left from constants.
    ///
    func sessionEnterMinutesLeft() -> Int {
        return VerificationConstants.sessionEnterMinutesLeft
    }
    
    /// Returns course minimum price.
    ///
    /// - returns: Course minimum price from constants.
    ///
    func courseMinimumPrice() -> Int {
        return VerificationConstants.courseMinimumPrice
    }
    
    /// Returns minimum camera course video duration.
    ///
    /// - returns: Minimum camera course video duration from constants.
    ///
    func minimumCameraCourseVideoDuration() -> Double {
        return VerificationConstants.minCameraCourseVideoDuration
    }
    
    /// Returns maximum library course video size in MB.
    ///
    /// - returns: Maximum library course video size from constants.
    ///
    func maximumLibraryCourseVideoSize() -> Int {
        return VerificationConstants.maximumLibraryCourseVideoSize
    }
    
    /// Checks video asset for minimum duration.
    ///
    /// - parameter url: Video asset url.
    /// - returns: Nil if duration isn't valid. Or url otherwise.
    ///
    func check(cameraCourseVideoURL: URL) -> URL? {
        let asset = AVAsset(url: cameraCourseVideoURL)
        let duration = CMTimeGetSeconds(asset.duration)
        if duration < VerificationConstants.minCameraCourseVideoDuration {
            return nil
        }
        
        return cameraCourseVideoURL
    }
    
    /// Checks video asset for maximum file size.
    ///
    /// - parameter url: Video asset url.
    /// - returns: Nil if duration isn't valid. Or url otherwise.
    ///
    func check(libraryCourseVideoURL: URL) -> URL? {
        var keys = Set<URLResourceKey>()
        keys.insert(.totalFileSizeKey)
        keys.insert(.fileSizeKey)
        
        let asset = AVURLAsset(url: libraryCourseVideoURL)
        do {
            var size = 0
            let resourceValues = try asset.url.resourceValues(forKeys: keys)
            if let fileSize = resourceValues.fileSize {
                size = fileSize
            } else if let fileSize = resourceValues.totalFileSize {
                size = fileSize
            }
            
            if (size / 1000 / 1000) > VerificationConstants.maximumLibraryCourseVideoSize {
                return nil
            }
            
            return libraryCourseVideoURL
        } catch {
            return nil
        }
    }
    
    /// Checks that date is later than now at least 30 minutes.
    ///
    /// - parameter time: Date with time to check.
    /// - returns: Nil if date isn't later. Or time interval since 1970 otherwise.
    ///
    func check(time: Date) -> TimeInterval? {
        let currentTime = Date()
        
        if time > currentTime {
            let currentTimeValue = currentTime.timeIntervalSince1970
            let timeValue = time.timeIntervalSince1970
            
            let minutes = ceil((timeValue - currentTimeValue) / 60)
            if minutes < Double(VerificationConstants.sessionEnterMinutesLeft) {
                return nil
            } else {
                return timeValue
            }
        } else {
            return nil
        }
    }
    
    /// Checks that date is later than now.
    ///
    /// - parameter date: Date to check.
    /// - returns: Nil if date isn't later. Or time interval since 1970 otherwise.
    ///
    func check(date: Date) -> TimeInterval? {
        let currentDate = Date()
        
        if date > currentDate {
            return date.timeIntervalSince1970
        } else {
            return nil
        }
    }
    
    /// Returns minimum count of sessions in course.
    ///
    /// - returns: Minimum count of sessions in course from constants.
    ///
    func minimumCountOfSessions() -> Int {
        return VerificationConstants.minCountOfSessionsInCourse
    }
    
    /// Returns username minimum length.
    ///
    /// - returns: Username minimum length from constants.
    ///
    func usernameMinimumLength() -> Int {
        return VerificationConstants.minNameLength
    }
    
    /// Returns username maximum length.
    ///
    /// - returns: Username maximum length from constants.
    ///
    func usernameMaximumLength() -> Int {
        return VerificationConstants.maxNameLength
    }
    
    /// Returns verification request interval.
    ///
    /// - returns: Verification request interval from constants.
    ///
    func requestVerificationCodeInterval() -> Int {
        return VerificationConstants.requestVerificationInterval
    }
    
    /// Cheks that string contains numbers.
    ///
    /// - parameter numbers: String with numbers.
    /// - returns: Nil if no numbers were found or number otherwise.
    ///
    func check(numbers: String?) -> String? {
        if self.isStringEmpty(string: numbers) {
            return nil
        }
        
        let numbersWithoutWhitespaces = numbers?.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        if self.isStringEmpty(string: numbersWithoutWhitespaces) {
            return nil
        }
        
        let numbersCharacterSet = CharacterSet(charactersIn: "0123456789").inverted
        let numbersOnly = numbersWithoutWhitespaces!.components(separatedBy: numbersCharacterSet).joined(separator: "")
        
        if self.isStringEmpty(string: numbersOnly) {
            return nil
        } else {
            return numbersOnly
        }
    }
    
    /// Cheks that string is number.
    ///
    /// - parameter number: String with number.
    /// - returns: Nil if string isn't number. Or string otherwise.
    ///
    func check(number: String?) -> String? {
        if self.isStringEmpty(string: number) {
            return nil
        }
        
        if number == "0" || number == "1" || number == "2" || number == "3" || number == "4" || number == "5" || number == "6" || number == "7" || number == "8" || number == "9" {
            return number
        }
        
        return nil
    }
    
    /// Returns verification code length.
    ///
    /// - returns: Verification code length from constants.
    ///
    func verificationCodeRequiredLength() -> Int {
        return VerificationConstants.verificationCodeLength
    }
    
    /// Checks verification code for length.
    ///
    /// - parameter verificationCodeSymbols: Array of verification code symbols.
    /// - returns: Nil if code isn't valid. Or code string otherwise.
    ///
    func check(verificationCodeSymbols: [String]) -> String? {
        if verificationCodeSymbols.count == VerificationConstants.verificationCodeLength {
            for symbol in verificationCodeSymbols {
                let checkedSymbol = self.check(number: symbol)
                if checkedSymbol == nil {
                    return nil
                }
            }
            
            return verificationCodeSymbols.joined()
        }
        
        return nil
    }
    
    /// Checks username for exist.
    ///
    /// - parameter username: String with name.
    /// - returns: Nil if username isn't valid. Or username without whitespaces and newlines otherwise.
    ///
    func check(username: String?) -> String? {
        if self.isStringEmpty(string: username) {
            return nil
        }
        
        let usernameWithoutWhitespaces = username?.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        if self.isStringEmpty(string: usernameWithoutWhitespaces) {
            return nil
        }
        
        return usernameWithoutWhitespaces
    }
    
    /// Checks username for min and max length.
    ///
    /// - parameter username: String with name.
    /// - returns: Nil if username isn't valid. Or username without whitespaces and newlines otherwise.
    ///
    func check(usernameLength username: String?) -> String? {
        if self.isStringEmpty(string: username) {
            return nil
        }
        
        let usernameWithoutWhitespaces = username?.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        if self.isStringEmpty(string: usernameWithoutWhitespaces) {
            return nil
        }
        
        if usernameWithoutWhitespaces!.count < VerificationConstants.minNameLength || usernameWithoutWhitespaces!.count > VerificationConstants.maxNameLength {
            return nil
        }
        
        return usernameWithoutWhitespaces
    }
    
    /// Checks email for exist and content of the "@" and "." characters and at least 2 more characters after.
    ///
    /// - parameter email: String with email.
    /// - returns: Nil if email isn't valid. Or email without whitespaces and newlines otherwise.
    ///
    func check(email: String?) -> String? {
        if self.isStringEmpty(string: email) {
            return nil
        }
        
        let emailWithoutWhitespaces = email?.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        if self.isStringEmpty(string: emailWithoutWhitespaces) {
            return nil
        }
        
        let regularExpressionPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,10}"
        let regularExpression = try? NSRegularExpression.init(pattern: regularExpressionPattern, options: .caseInsensitive)
        let regularExpressionMatches = regularExpression?.numberOfMatches(in: emailWithoutWhitespaces!, options: .reportCompletion, range: NSMakeRange(0, emailWithoutWhitespaces!.count)) ?? 0
        
        if regularExpressionMatches == 0 {
            return nil
        } else {
            return emailWithoutWhitespaces
        }
    }
    
    /// Checks domain for exist and content of the "." character and at least 2 more characters after.
    ///
    /// - parameter domain: String with domain.
    /// - returns: Nil if domain isn't valid. Or domain without whitespaces and newlines otherwise.
    ///
    func check(domain: String?) -> String? {
        if self.isStringEmpty(string: domain) {
            return nil
        }
        
        let domainWithoutWhitespaces = domain?.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        if self.isStringEmpty(string: domainWithoutWhitespaces) {
            return nil
        }
        
        let regularExpressionPattern = "[A-Z0-9a-z._%+-/:]+\\.[A-Za-z]{2,10}"
        let regularExpression = try? NSRegularExpression.init(pattern: regularExpressionPattern, options: .caseInsensitive)
        let regularExpressionMatches = regularExpression?.numberOfMatches(in: domainWithoutWhitespaces!, options: .reportCompletion, range: NSMakeRange(0, domainWithoutWhitespaces!.count)) ?? 0
        
        if regularExpressionMatches == 0 {
            return nil
        } else {
            return domainWithoutWhitespaces
        }
    }
    
    /// Checks phone number for exist. Valid characters are "+0123456789".
    ///
    /// - parameter phoneNumber: String with phoneNumber.
    /// - returns: Nil if phone number isn't valid. Or phone number without whitespaces and newlines otherwise.
    ///
    func check(phoneNumber: String?) -> String? {
        if self.isStringEmpty(string: phoneNumber) {
            return nil
        }
        
        let phoneNumberWithoutWhitespaces = phoneNumber?.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        if self.isStringEmpty(string: phoneNumberWithoutWhitespaces) {
            return nil
        }
        
        let phoneNumberCharacterSet = CharacterSet(charactersIn: "+0123456789").inverted
        let phoneNumberWithNumbersOnly = phoneNumberWithoutWhitespaces!.components(separatedBy: phoneNumberCharacterSet).joined(separator: "")
        
        if self.isStringEmpty(string: phoneNumberWithNumbersOnly) {
            return nil
        } else {
            return phoneNumberWithNumbersOnly
        }
    }
    
    /// Checks string for exist and not empty.
    ///
    /// - parameter string: String.
    /// - returns: Nil if string isn't valid. Or string without whitespaces and newlines otherwise.
    ///
    func check(string: String?) -> String? {
        if self.isStringEmpty(string: string) {
            return nil
        }
        
        let stringWithoutWhitespaces = string?.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        if self.isStringEmpty(string: stringWithoutWhitespaces) {
            return nil
        }
        
        return stringWithoutWhitespaces
    }
    
    /// Checks string for exist and not empty.
    ///
    /// - parameter price: Course price decimal number.
    /// - returns: Nil if price isn't valid. Or price string without whitespaces and newlines otherwise.
    ///
    func check(price: NSDecimalNumber?) -> String? {
        let string = price?.stringValue
        if self.isStringEmpty(string: string) {
            return nil
        }
        
        if let coursePrice = price {
            if coursePrice == NSDecimalNumber.notANumber || coursePrice.doubleValue <= Double(VerificationConstants.courseMinimumPrice) {
                return nil
            }
        } else {
            return nil
        }
        
        let stringWithoutWhitespaces = string?.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        if self.isStringEmpty(string: stringWithoutWhitespaces) {
            return nil
        }
        
        return stringWithoutWhitespaces
    }
    
    // MARK: Private Methods
    
    private func isStringEmpty(string: String?) -> Bool {
        if string == nil || string!.isEmpty {
            return true
        }
        
        return false
    }
    
}
