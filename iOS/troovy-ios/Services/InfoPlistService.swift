//
//  InfoPlistService.swift
//  troovy-ios
//
//  Created by Daniil on 08.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import Foundation

class InfoPlistService {
    
    private struct Keys {
        static let keysAndTokens = "TroovyConstantsDictionary"
        
        static let serverURL = "server_url"
        static let socketServerURL = "socket_server_url"
        static let stripeApiKey = "stripe_api_key"
        static let appleMerchantIdentifier = "apple_merchant_identifier"
        static let hockeyAppApplicationIdentifier = "hockeyapp_app_identifier"
        static let branchKey = "branch_key"
        static let inAppTemplate = "in_app_product_template"
        
        static let turnServerURL = "turn_server_url"
        static let turnServerUsername = "turn_server_username"
        static let turnServerCredential = "turn_server_credential"
        static let stunServerURL = "stun_server_url"
        
        static let googleAnalyticsFilename = "google_analytics_filename"
    }
    
    // MARK: Private Properties
    
    private var info: [String:Any]?
    
    // MARK: Init Methods & Superclass Overriders
    
    init() {
        self.info = Bundle.main.object(forInfoDictionaryKey: Keys.keysAndTokens) as? [String:Any]
    }
    
    // MARK: Public Methods
    
    /// Gets turn servers addresses from Info.plist for current build scheme.
    ///
    /// - returns: Array of turn servers addresses.
    ///
    func turnServersAddresses() -> [String] {
        var array: [String] = []
        if let string = self.info?[Keys.turnServerURL] as? String {
            let stringComponents = string.components(separatedBy: ",")
            for component in stringComponents {
                let clearString = component.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                if !clearString.isEmpty {
                    if clearString.hasPrefix("turn:") {
                        array.append(clearString)
                    } else {
                        array.append("turn:\(clearString)")
                    }
                }
            }
        }
        
        return array
    }
    
    /// Gets turn servers username from Info.plist for current build scheme.
    ///
    /// - returns: Turn servers username.
    ///
    func turnServersUsername() -> String? {
        if let string = self.info?[Keys.turnServerUsername] as? String {
            let clearString = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            return clearString
        }
        
        return nil
    }
    
    /// Gets turn servers credential from Info.plist for current build scheme.
    ///
    /// - returns: Turn servers credential.
    ///
    func turnServersCredential() -> String? {
        if let string = self.info?[Keys.turnServerCredential] as? String {
            let clearString = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            return clearString
        }
        
        return nil
    }
    
    /// Gets stun servers addresses from Info.plist for current build scheme.
    ///
    /// - returns: Array of stun servers addresses.
    ///
    func stunServersAddresses() -> [String] {
        var array: [String] = []
        if let string = self.info?[Keys.stunServerURL] as? String {
            let stringComponents = string.components(separatedBy: ",")
            for component in stringComponents {
                let clearString = component.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                if !clearString.isEmpty {
                    if clearString.hasPrefix("stun:") {
                        array.append(clearString)
                    } else {
                        array.append("stun:\(clearString)")
                    }
                }
            }
        }
        
        return array
    }
    
    /// Gets socket server URL value from Info.plist for current build scheme.
    ///
    /// - returns: Socket server URL as a string.
    ///
    func socketServerURL() -> String {
        if let string = self.info?[Keys.socketServerURL] as? String {
            let clearString = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            return clearString
        }
        
        return ""
    }
    
    /// Gets server URL value from Info.plist for current build scheme.
    ///
    /// - returns: Server URL as a string.
    ///
    func serverURL() -> String {
        if let string = self.info?[Keys.serverURL] as? String {
            let clearString = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            return clearString
        }
        
        return ""
    }
    
    /// Gets stripe API key value from Info.plist for current build scheme.
    ///
    /// - returns: Stripe API key as a string.
    ///
    func stripeApiKey() -> String {
        if let string = self.info?[Keys.stripeApiKey] as? String {
            let clearString = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            return clearString
        }
        
        return ""
    }
    
    /// Gets apple merchant identifier from Info.plist for current build scheme.
    ///
    /// - returns: Apple merchant identifier as a string.
    ///
    func appleMerchantIdentifier() -> String {
        if let string = self.info?[Keys.appleMerchantIdentifier] as? String {
            let clearString = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            return clearString
        }
        
        return ""
    }
    
    /// Gets HockeyApp application identifier from Info.plist for current build scheme.
    ///
    /// - returns: HockeyApp application identifier.
    ///
    func hockeyAppApplicationIdentifier() -> String {
        if let string = self.info?[Keys.hockeyAppApplicationIdentifier] as? String {
            let clearString = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            return clearString
        }
        
        return ""
    }
    
    /// Gets Branch.io key from Info.plist for current build scheme.
    ///
    /// - returns: Branch.io app key.
    ///
    func branchKey() -> String {
        if let string = self.info?[Keys.branchKey] as? String {
            let clearString = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            return clearString
        }
        
        return ""
    }
    
    /// Gets in app purchase product key from Info.plist for current build scheme.
    ///
    /// - returns: in app purchase product key
    ///
    func inAppPurchaseProductTemplate() -> String {
        if let string = self.info?[Keys.inAppTemplate] as? String {
            let clearString = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            return clearString
        }
        
        return ""
    }
    
    /// Gets Google Analytics configuration filename.
    ///
    /// - returns: Google Analytics configuration filename.
    ///
    func googleAnalyticsFilename() -> String {
        if let string = self.info?[Keys.googleAnalyticsFilename] as? String {
            let clearString = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            return clearString
        }
        
        return ""
    }
    
}
