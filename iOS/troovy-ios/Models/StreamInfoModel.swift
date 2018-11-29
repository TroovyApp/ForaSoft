//
//  StreamInfoModel.swift
//  troovy-ios
//
//  Created by Daniil on 20.10.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

enum SessionStreamStatus: Int {
    case notStarted = 0
    case started = 1
    case paused = 2
    case finished = 3
}

struct StreamInfoModel {
    
    private struct Keys {
        static let status = "status"
        static let usersIdentifiers = "userList"
        static let duration = "duration"
        static let iceServers = "iceServers"
        static let stuns = "stuns"
        static let turns = "turns"
        static let credential = "credential"
        static let url = "url"
        static let username = "username"
    }
    
    // MARK: Properties
    
    /// Actual session stream status.
    var status: SessionStreamStatus!
    
    /// Array of users server identifiers.
    var usersIdentifiers: [String]!
    
    /// Real stream duration in minutes.
    var duration: Int64!
    
    /// webRTC Ice Servers
    var iceServers: [RTCIceServer] = []
    
    // MARK: Init Methods
    
    /// Initializes structure with dictionary.
    ///
    /// - parameter dictionary: Server response or saved user dictionary.
    ///
    init(withDictionary dictionary: [String:Any]) {
        if let status = dictionary[Keys.status] as? Int {
            self.status = SessionStreamStatus.init(rawValue: status)
        } else {
            self.status = SessionStreamStatus.init(rawValue: 0)
        }
        
        if let usersIdentifiers = dictionary[Keys.usersIdentifiers] as? [String] {
            self.usersIdentifiers = usersIdentifiers
        } else {
            self.usersIdentifiers = []
        }
        
        if let duration = dictionary[Keys.duration] as? Double {
            self.duration = Int64(duration / 60)
        } else {
            self.duration = 0
        }
        
        var servers: [RTCIceServer] = []
        if let iceServers = dictionary[Keys.iceServers] as? [String:Any] {
            if let stunServersDictionaries = iceServers[Keys.stuns] as? [[String:Any]] {
                for dictionary in stunServersDictionaries {
                    if let server = self.server(fromDictionary: dictionary, prefix: "stun:") {
                        servers.append(server)
                    }
                }
            }
            
            if let turnServersDictionaries = iceServers[Keys.turns] as? [[String:Any]] {
                for dictionary in turnServersDictionaries {
                    if let server = self.server(fromDictionary: dictionary, prefix: "turn:") {
                        servers.append(server)
                    }
                }
            }
        }
        self.iceServers = servers
    }
    
    // MARK: Private Methods
    
    private func server(fromDictionary dictionary:[String:Any], prefix: String) -> RTCIceServer? {
        if let url = dictionary[Keys.url] as? String {
            let address = (url.hasPrefix(prefix) ? url : (prefix + url))
            let username = dictionary[Keys.username] as? String
            let credential = dictionary[Keys.credential] as? String
            
            let server = RTCIceServer.init(urlStrings: [address], username: username, credential: credential)
            return server
        }
        
        return nil
    }

}
