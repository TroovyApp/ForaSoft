//
//  SocketManager.swift
//  troovy-ios
//
//  Created by Daniil on 11.10.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import Foundation

import SocketIO

protocol SocketManagerDelegate: class {
    func socketConnected()
    func socketDisconnected()
    
    func socketMustExitSession(withError error: String?)
    func socketJoinedSession(withResponse response: [String:Any]?, errorMessage: String?)
    func socketFinishedSession(withResponse response: [String:Any]?)
    func socketStartedSession()
    func socketStreamPublished()
    
    func socketStreamChangedVideoEnabled(_ enabled: Bool)
    
    func socketReceivedStreamCandidate(withResponse response: [String:Any]?)
    
    func socketReceivedMessage(withResponse response: [String:Any]?)
}

class SocketManager {
    
    private struct Keys {
        static let sessionID = "sessionId"
        static let userID = "userId"
        static let accessToken = "accessToken"
        static let error = "error"
        
        static let offerSessionDescription = "offerSdp"
        static let streamLabel = "label"
        static let candidate = "candidate"
        
        static let videoEnabled = "isVideoEnabled"
        
        static let message = "text"
    }
    
    private struct Events {
        struct Send {
            static let joinSession = "session:join"
            static let leaveSession = "session:leave"
            
            static let publishStream = "stream:publish"
            static let streamConnected = "stream:connected"
            static let requestStream = "stream:play"
            static let stopStream = "stream:stop"
            static let streamInfo = "stream:info"
            static let streamCandidate = "stream:candidate"
            
            static let enableStreamVideo = "stream:video:enable"
            static let disableStreamVideo = "stream:video:disable"
            
            static let sendMessage = "message:send"
        }
        
        struct Receive {
            static let forceLogout = "session:forceLogout"
            static let sessionFinished = "session:finished"
            static let sessionStarted = "session:started"
            
            static let streamCandidate = "stream:candidate"
            static let streamPublished = "stream:published"
            
            static let streamVideoEnabled = "stream:video:enabled"
            static let streamVideoDisabled = "stream:video:disabled"
            
            static let receiveMessage = "message:received"
        }
    }
    
    // MARK: Private Properties
    
    private let infoPlistService = InfoPlistService()
    
    private var socketManager: SocketIO.SocketManager!
    
    private var sessionID: String!
    private var userID: String!
    private var sessionCreatorID: String!
    private var accessToken: String!
    
    private weak var delegate: SocketManagerDelegate?
    
    // MARK: Init Methods & Superclass Overriders
    
    /// Creates socket manager and connects to the server.
    ///
    /// - parameter: Session server ID.
    ///
    init(withSessionID sessionID: String, userID: String, sessionCreatorID: String, accessToken: String, delegate: SocketManagerDelegate) {
        let socketServer = self.infoPlistService.socketServerURL()//.replacingOccurrences(of: "https://", with: "http://")
        let socketServerURL = URL(string: socketServer)!
        
        var configuration = SocketIOClientConfiguration()
        configuration.insert(SocketIOClientOption.reconnects(true))
        configuration.insert(SocketIOClientOption.reconnectAttempts(-1))
        configuration.insert(SocketIOClientOption.log(false))
        
        self.sessionID = sessionID
        self.userID = userID
        self.sessionCreatorID = sessionCreatorID
        self.accessToken = accessToken
        self.delegate = delegate
        self.socketManager = SocketIO.SocketManager(socketURL: socketServerURL, config: configuration)
        
        self.addDefaultSocketEvents()
        self.addCustomSocketEvents()
        
        self.socketManager.defaultSocket.connect()
    }
    
    // MARK: Public Methods
    
    /// Sends video track state to the server.
    ///
    /// - parameter enabled: Video track isEnabled flag.
    ///
    func setVideoTrackEnabled(_ enabled: Bool) {
        let parameters: [String:Any] = [Keys.sessionID : self.sessionID,
                                        Keys.videoEnabled : (enabled ? "1" : "0")]
        let event = (enabled ? Events.Send.enableStreamVideo : Events.Send.disableStreamVideo)
        
        self.sendEvent(withName: event, parameters: parameters) { (data) in
            // nothing to do
        }
    }
    
    /// Disconnects sockets.
    func disconnect() {
        //self.delegate = nil
        self.leaveSession()
        self.socketManager.defaultSocket.disconnect()
    }
    
    /// Sends text message to the server.
    ///
    /// - parameters text: Message text.
    /// - parameters completion: Completion block, returns success flag and session info.
    ///
    func sendMessage(_ text: String, completion: ((_ success: Bool, _ response: [String:Any]?) -> ())?) {
        let parameters: [String:Any] = [Keys.sessionID : self.sessionID,
                                        Keys.userID : self.userID,
                                        Keys.accessToken : self.accessToken,
                                        Keys.message : text]
        let event = Events.Send.sendMessage

        self.sendEvent(withName: event, parameters: parameters) { [weak self] (data) in
            var success = false
            var response: [String:Any]? = nil
            if let status = data[0] as? String, status == SocketAckStatus.noAck.rawValue {
                success = false
            } else {
                let error: [String:Any]? = (data.count >= 1 ? data[0] as? [String:Any] : nil)
                response = (data.count >= 2 ? data[1] as? [String:Any] : nil)

                if let _ = self?.errorMessage(fromResponse: error) {
                    success = false
                } else {
                    success = true
                }
            }

            completion?(success, response)
        }
    }
    
    /// Sends webRTC offer to the server.
    ///
    /// - parameters sessionDescription: webRTC offer
    /// - parameters publishing: True if we are streamer, false if we are viewer.
    /// - parameters videoEnabled: True if we are streamer and video track is enabled, or if we are not streamer. False if we are streamter and video track is disabled.
    /// - parameters completion: Completion block, returns success flag and session info.
    ///
    func passStreamSessionDiscription(_ sessionDescription: String, publishing: Bool, videoEnabled: Bool, completion: ((_ success: Bool, _ response: [String:Any]?) -> ())?) {
        let parameters: [String:Any] = [Keys.sessionID : self.sessionID,
                                        Keys.userID : self.userID,
                                        Keys.accessToken : self.accessToken,
                                        Keys.streamLabel : self.sessionCreatorID,
                                        Keys.offerSessionDescription: sessionDescription,
                                        Keys.videoEnabled : (videoEnabled ? "1" : "0")]
        let event = (publishing ? Events.Send.publishStream : Events.Send.requestStream)
            
        self.sendEvent(withName: event, parameters: parameters) { [weak self] (data) in
            var success = false
            var response: [String:Any]? = nil
            if let status = data[0] as? String, status == SocketAckStatus.noAck.rawValue {
                success = false
            } else {
                let error: [String:Any]? = (data.count >= 1 ? data[0] as? [String:Any] : nil)
                response = (data.count >= 2 ? data[1] as? [String:Any] : nil)
                
                if let _ = self?.errorMessage(fromResponse: error) {
                    success = false
                } else {
                    success = true
                }
            }
            
            completion?(success, response)
        }
    }
    
    /// Stops stream.
    ///
    /// - parameters completion: Completion block, returns success flag.
    ///
    func stopStream(_ completion: ((_ success: Bool) -> ())?) {
        let parameters: [String:Any] = [Keys.sessionID : self.sessionID]
        
        self.sendEvent(withName: Events.Send.stopStream, parameters: parameters) { [weak self] (data) in
            var success = false
            if let status = data[0] as? String, status == SocketAckStatus.noAck.rawValue {
                success = false
            } else {
                let error: [String:Any]? = (data.count >= 1 ? data[0] as? [String:Any] : nil)
                
                if let _ = self?.errorMessage(fromResponse: error) {
                    success = false
                } else {
                    success = true
                }
            }
            
            completion?(success)
        }
    }
    
    /// Sends stream connected state to server
    ///
    /// - parameters completion: Completion block, returns success flag.
    ///
    func streamConnected(videoEnabled: Bool, _ completion: ((_ success: Bool) -> ())?) {
        let parameters: [String:Any] = [Keys.sessionID : self.sessionID,
                                        Keys.streamLabel : self.sessionCreatorID,
                                        Keys.videoEnabled : (videoEnabled ? "1" : "0")]
        
        self.sendEvent(withName: Events.Send.streamConnected, parameters: parameters) { (data) in
            
            print(data)
            completion?(true)
        }
    }
    
    /// Sends webRTC offer to the server.
    ///
    /// - parameters completion: Completion block, returns success flag.
    ///
    func requestStreamInfo(_ completion: ((_ success: Bool, _ isVideoEnabled: Bool) -> ())?) {
        let parameters: [String:Any] = [Keys.sessionID : self.sessionID]
        
        self.sendEvent(withName: Events.Send.streamInfo, parameters: parameters) { [weak self] (data) in
            var success = false
            var videoEnabled = false
            if let status = data[0] as? String, status == SocketAckStatus.noAck.rawValue {
                success = false
                videoEnabled = false
            } else {
                let error: [String:Any]? = (data.count >= 1 ? data[0] as? [String:Any] : nil)
                let response = (data.count >= 2 ? data[1] as? [String:Any] : nil)
                
                if let videoEnabledValue = response?[Keys.videoEnabled] {
                    if let videoEnabledInt = videoEnabledValue as? Int {
                        videoEnabled = (videoEnabledInt == 1)
                    } else if let videoEnabledString = videoEnabledValue as? String {
                        videoEnabled = (videoEnabledString == "1")
                    } else {
                        videoEnabled = (videoEnabledValue as? Bool) ?? false
                    }
                }
                
                if let _ = self?.errorMessage(fromResponse: error) {
                    success = false
                } else {
                    if let _ = response?[Keys.streamLabel] as? String {
                        success = true
                    } else {
                        success = false
                    }
                }
            }
            
            completion?(success, videoEnabled)
        }
    }
    
    /// Sends webRTC candidate to the server.
    ///
    /// - parameters candidate: webRTC candidate.
    ///
    func passStreamCandidate(_ candidate: [String:Any]) {
        let parameters: [String:Any] = [Keys.sessionID : self.sessionID,
                                        Keys.userID : self.userID,
                                        Keys.accessToken : self.accessToken,
                                        Keys.streamLabel : self.sessionCreatorID,
                                        Keys.candidate: candidate]
        
        self.sendEvent(withName: Events.Send.streamCandidate, parameters: parameters) { (data) in
            // nothing to do
        }
    }
    
    // MARK: Private Methods
    
    // MARK: Add Socket Events
    
    private func addDefaultSocketEvents() {
        self.socketManager.defaultSocket.on(clientEvent: .connect) { [weak self] (data, ack) in
            self?.delegate?.socketConnected()
            self?.joinSession()
        }
        
        self.socketManager.defaultSocket.on(clientEvent: .reconnect) { [weak self] (data, ack) in
            self?.delegate?.socketDisconnected()
        }
        
        self.socketManager.defaultSocket.on(clientEvent: .disconnect) { [weak self] (data, ack) in
            self?.delegate?.socketDisconnected()
        }
    }
    
    private func addCustomSocketEvents() {
        self.socketManager.defaultSocket.on(Events.Receive.forceLogout) { [weak self] (data, ack) in
            let error: [String:Any]? = (data.count >= 1 ? data[0] as? [String:Any] : nil)
            let errorMessage = self?.errorMessage(fromResponse: error)
            self?.delegate?.socketMustExitSession(withError: errorMessage)
        }
        
        self.socketManager.defaultSocket.on(Events.Receive.streamCandidate) { [weak self] (data, ack) in
            let response: [String:Any]? = (data.count >= 1 ? data[0] as? [String:Any] : nil)
            self?.delegate?.socketReceivedStreamCandidate(withResponse: response)
        }
        
        self.socketManager.defaultSocket.on(Events.Receive.sessionFinished) { [weak self] (data, ack) in
            let response: [String:Any]? = (data.count >= 1 ? data[0] as? [String:Any] : nil)
            self?.delegate?.socketFinishedSession(withResponse: response)
        }
        
        self.socketManager.defaultSocket.on(Events.Receive.sessionStarted) { [weak self] (data, ack) in
            self?.delegate?.socketStartedSession()
        }
        
        self.socketManager.defaultSocket.on(Events.Receive.streamPublished) { [weak self] (data, ack) in
            self?.delegate?.socketStreamPublished()
            
            let response: [String:Any]? = (data.count >= 1 ? data[0] as? [String:Any] : nil)
            if let videoEnabledValue = response?[Keys.videoEnabled] {
                var videoEnabled = false
                if let videoEnabledInt = videoEnabledValue as? Int {
                    videoEnabled = (videoEnabledInt == 1)
                } else if let videoEnabledString = videoEnabledValue as? String {
                    videoEnabled = (videoEnabledString == "1")
                } else {
                    videoEnabled = (videoEnabledValue as? Bool) ?? false
                }
                self?.delegate?.socketStreamChangedVideoEnabled(videoEnabled)
            }
        }
        
        self.socketManager.defaultSocket.on(Events.Receive.streamVideoEnabled) { [weak self] (data, ack) in
            self?.delegate?.socketStreamChangedVideoEnabled(true)
        }
        
        self.socketManager.defaultSocket.on(Events.Receive.streamVideoDisabled) { [weak self] (data, ack) in
            self?.delegate?.socketStreamChangedVideoEnabled(false)
        }
        
        self.socketManager.defaultSocket.on(Events.Receive.receiveMessage) { [weak self] (data, ack) in
            let response: [String:Any]? = (data.count >= 1 ? data[0] as? [String:Any] : nil)
            self?.delegate?.socketReceivedMessage(withResponse: response)
        }
        
        self.socketManager.defaultSocket.onAny { (event) in
            #if DEBUG
                print("\(Date()) socket RECEIVE \(event.event) with \(event.items ?? [])")
            #endif
        }
    }
    
    // MARK: Send Event Methods
    
    private func leaveSession() {
        let parameters: [String:Any] = [Keys.sessionID : self.sessionID,
                                        Keys.userID : self.userID,
                                        Keys.accessToken : self.accessToken]
        
        self.sendEvent(withName: Events.Send.leaveSession, parameters: parameters) { (data) in
            print(data)
        }
    }
    
    private func joinSession() {
        let parameters: [String:Any] = [Keys.sessionID : self.sessionID,
                                        Keys.userID : self.userID,
                                        Keys.accessToken : self.accessToken]
        
        self.sendEvent(withName: Events.Send.joinSession, parameters: parameters) { [weak self] (data) in
            if let status = data[0] as? String, status == SocketAckStatus.noAck.rawValue {
                self?.joinSession()
            } else {
                let error: [String:Any]? = (data.count >= 1 ? data[0] as? [String:Any] : nil)
                let response: [String:Any]? = (data.count >= 2 ? data[1] as? [String:Any] : nil)
                
                if let errorMessage = self?.errorMessage(fromResponse: error) {
                    self?.delegate?.socketJoinedSession(withResponse: nil, errorMessage: errorMessage)
                } else {
                    self?.delegate?.socketJoinedSession(withResponse: response, errorMessage: nil)
                }
            }
        }
    }
    
    // MARK: Support Methods
    
    private func sendEvent(withName name: String, parameters: [String:Any]) {
        self.sendEvent(withName: name, parameters: parameters, completion: nil)
    }
    
    private func sendEvent(withName name: String, parameters: [String:Any], completion: AckCallback?) {
        #if DEBUG
            print("\(Date()) socket EMIT \(name) with \(parameters)")
        #endif
        
        if let callback = completion {
            self.socketManager.defaultSocket.emitWithAck(name, parameters).timingOut(after: 30.0, callback: { (data) in
                #if DEBUG
                    print("\(Date()) socket CALLBACK \(name) with \(data)")
                #endif
                
                callback(data)
            })
        } else {
            self.socketManager.defaultSocket.emit(name, parameters)
        }
    }
    
    private func errorMessage(fromResponse response: [String:Any]?) -> String? {
        var errorMessage: String?
        
        if let data = response {
            if let error = data[Keys.error] as? String {
                errorMessage = error
            } else {
                errorMessage = ApplicationMessages.ErrorMessages.serverError
            }
        }
        
        return errorMessage
    }
    
}
