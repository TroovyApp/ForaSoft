//
//  VideoStreamService.swift
//  troovy-ios
//
//  Created by Daniil on 11.10.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

enum VideoStreamServiceTaskResult: Error {
    case serviceDidEnterSession(serverTime: Int64?, session: [String:Any]?, stream: [String:Any]?, errorMessage: String?, sessionStarted: Bool, sessionFinished: Bool)
    case serviceWaitingForSession()
    case serviceLogoutedFromSession(error: String?)
    case serviceFinishedSession(session: [String:Any]?, stream: [String:Any]?)
    case serviceStartedSession()
    
    case serviceStartedStreaming()
    case serviceStreamPublished()
    
    case serviceDidChangeStreamState(state: RTCIceConnectionState)
    
    case serviceShouldShowCameraView(cameraView: UIView)
    
    case serviceShouldShowStreamingView(streamingView: UIView)
    case serviceShouldHideStreamingView()
    
    case serviceChangedVideoEnabled(enabled: Bool)
}

enum StreamChatServiceTaskResult: Error {
    case serviceDidReceiveMessage(message: StreamMessageModel)
    case serviceDidSendMessage(message: StreamMessageModel)
    case serviceDidFailMessage()
}

protocol VideoStreamServiceDelegate: class {
    func streamReceiverHandle(taskResult result: VideoStreamServiceTaskResult)
}

protocol StreamChatServiceDelegate: class {
    func chatReceiverHandle(taskResult result: StreamChatServiceTaskResult)
}

class VideoStreamService: TroovyService, SocketManagerDelegate, WebRTCManagerDelegate {
    
    private struct Keys {
        static let serverTime = "currentServerTime"
        static let session = "sessionInfo"
        static let status = "status"
        static let result = "result"
    }
    
    // MARK: Public Properties
    
    /// Delegate. Responds to VideoStreamServiceDelegate and processes VideoStreamServiceTaskResult.
    weak var streamReceiver: VideoStreamServiceDelegate?
    
    /// Delegate. Responds to StreamChatServiceDelegate and processes StreamChatServiceTaskResult.
    weak var chatReceiver: StreamChatServiceDelegate?

    // MARK: Private Properties
    
    private var socketManager: SocketManager?
    private var webRTCManager: WebRTCManager?
    private let networkManagar = NetworkManager.shared
    
    private var sessionDescriptionIsSet = false
    private var waitingRemoteCandidates = [[String: Any]]()
    
    // MARK: Public Methods
    
    /// Connects to the session with sockets.
    ///
    /// - parameter sessionID: Course session server id.
    /// - parameter sessionCreatorID: Course sesssion creator id.
    /// - parameter user: Authorised user model.
    ///
    func enterSession(withID sessionID: String, sessionCreatorID: String, user: AuthorisedUserModel) {
        self.streamReceiver?.streamReceiverHandle(taskResult: VideoStreamServiceTaskResult.serviceWaitingForSession())
        
        self.exitSession()
        
        self.socketManager = SocketManager(withSessionID: sessionID, userID: user.id, sessionCreatorID: sessionCreatorID, accessToken: user.networkToken, delegate: self)
        self.webRTCManager = WebRTCManager(withSessionID: sessionID, networkToken: user.networkToken, userID: user.id, delegate: self)
    }
    
    /// Disconnects from the session.
    func exitSession() {
        
        if let webRTCManager = self.webRTCManager {
            DispatchQueue.main.async {
                webRTCManager.stopStreaming()
                webRTCManager.stopWatching()
            }
        }
        
        self.webRTCManager = nil
        
        if self.socketManager != nil {
            self.socketManager?.disconnect()
            self.socketManager = nil
        }
    }
    
    /// Start the session.
    ///
    /// - parameter sessionID: Course session server ID.
    /// - parameter user: Authorised user model.
    /// - returns: Method name.
    ///
    func startSession(withID sessionID: String, user: AuthorisedUserModel) -> String {
        let method = "startSession"
        self.serviceResultChanged(withResult: ServiceActionResult.methodStarted(method: method))
        
        self.networkManagar.startSession(withNetworkToken: user.networkToken, sessionID: sessionID) { (response, errorMessage, isCancelled) -> (Void) in
            if let result = response as? [String:Any] {
                self.serviceResultChanged(withResult: ServiceActionResult.methodSucceededWithResponseDictionary(method: method, resultDictionary: result))
            } else {
                self.serviceResultChanged(withResult: ServiceActionResult.methodFailed(method: method, error: errorMessage))
            }
        }
        
        return method
    }
    
    /// Finishes the session.
    ///
    /// - parameter sessionID: Course session server ID.
    /// - parameter user: Authorised user model.
    /// - returns: Method name.
    ///
    func finishSession(withID sessionID: String, user: AuthorisedUserModel) -> String {
        let method = "finishSession"
        self.serviceResultChanged(withResult: ServiceActionResult.methodStarted(method: method))
        
        self.networkManagar.finishSession(withNetworkToken: user.networkToken, sessionID: sessionID) { (response, errorMessage, isCancelled) -> (Void) in
            if let result = response as? [String:Any] {
                self.serviceResultChanged(withResult: ServiceActionResult.methodSucceededWithResponseDictionary(method: method, resultDictionary: result))
            } else {
                self.serviceResultChanged(withResult: ServiceActionResult.methodFailed(method: method, error: errorMessage))
            }
        }
        
        return method
    }
    
    /// Loads session messages.
    ///
    /// - parameter sessionID: Course session server ID.
    /// - parameter user: Authorised user model.
    /// - returns: Method name.
    ///
    func loadSessionMessages(withID sessionID: String, user: AuthorisedUserModel) -> String {
        let method = "loadSessionMessages"
        self.serviceResultChanged(withResult: ServiceActionResult.methodStarted(method: method))
        
        self.networkManagar.loadSessionMessages(withNetworkToken: user.networkToken, sessionID: sessionID) { (response, errorMessage, isCancelled) -> (Void) in
            if let result = response as? [[String:Any]] {
                self.serviceResultChanged(withResult: ServiceActionResult.methodSucceededWithResponseArray(method: method, resultArray: result))
            } else {
                self.serviceResultChanged(withResult: ServiceActionResult.methodFailed(method: method, error: errorMessage))
            }
        }
        
        return method
    }
    
    /// Starts local media stream.
    func startCamera() {
        DispatchQueue.main.async {
            self.webRTCManager?.startCamera()
        }
    }
    
    /// Starts streaming local media stream.
    func startStreaming(withServers servers: [RTCIceServer]?) {
        DispatchQueue.main.async {
            let streaming = self.webRTCManager?.startStreaming(withServers: servers)
            if streaming == true {
                self.streamReceiver?.streamReceiverHandle(taskResult: VideoStreamServiceTaskResult.serviceStartedStreaming())
            }
        }
    }
    
    /// Stops and starts receiving remote media stream.
    ///
    /// parameter servers: webRTC ice servers from server.
    ///
    func continueWatching(withServers servers: [RTCIceServer]?) {
        let isWatching = self.webRTCManager?.isWatching() ?? false
        if !isWatching {
            DispatchQueue.main.async {
                self.webRTCManager?.startWatching(withServers: servers)
            }
            return
        }
        
        self.socketManager?.stopStream({ [weak self] (success) in
            if success {
                DispatchQueue.main.async {
                    self?.webRTCManager?.stopWatching()
                    self?.webRTCManager?.startWatching(withServers: servers)
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.continueWatching(withServers: servers)
                }
            }
        })
    }
    
    /// Starts receiving remote media stream.
    ///
    /// parameter servers: webRTC ice servers from server.
    ///
    func startWatching(withServers servers: [RTCIceServer]?) {
        let isWatching = self.webRTCManager?.isWatching() ?? false
        if isWatching {
            return
        }
        
        self.socketManager?.requestStreamInfo({ [weak self] (success, videoEnabled) in
            if success {
                DispatchQueue.main.async {
                    self?.webRTCManager?.startWatching(withServers: servers)
                }
                
                self?.streamReceiver?.streamReceiverHandle(taskResult: VideoStreamServiceTaskResult.serviceChangedVideoEnabled(enabled: videoEnabled))
            } else {
//                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
//                    self?.startWatching(withServers: servers)
//                }
            }
        })
    }
    
    /// Turns on/off the local media stream camera.
    ///
    /// - parameter enabled: Determines should be camera enabled.
    ///
    func setCameraEnabled(enabled: Bool) {
        DispatchQueue.main.async {
            self.webRTCManager?.setCamera(enabled: enabled)
        }
        
        self.socketManager?.setVideoTrackEnabled(enabled)
    }
    
    func setRemoteVideo(enabled: Bool) {
        print("setRemoteVideo called: ", enabled)
        DispatchQueue.main.async {
            self.webRTCManager?.setRemoteVideo(enabled: enabled)
        }
    }
    
    /// Toggles device camera.
    func toggleCamera() {
        DispatchQueue.main.async {
            self.webRTCManager?.toggleCamera()
        }
    }
    
    /// Turns on/off the local media stream microphone.
    ///
    /// - parameter enabled: Determines should be microphone enabled.
    ///
    func setMicrophoneEnabled(enabled: Bool) {
        DispatchQueue.main.async {
            self.webRTCManager?.setMicrophone(enabled: enabled)
        }
    }
    
    /// Turns on/off the remote media stream sounds.
    ///
    /// - parameter enabled: Determines should be sounds enabled.
    ///
    func setSoundEnabled(enabled: Bool) {
        DispatchQueue.main.async {
            self.webRTCManager?.setSound(enabled: enabled)
        }
    }
    
    /// Sends text message to the server.
    ///
    /// - parameters text: Message text.
    ///
    func sendMessage(text: String) {
        self.socketManager?.sendMessage(text, completion: { [weak self] (success, response) in
            if let responseDictionary = response, let message = responseDictionary[Keys.result] as? [String:Any] {
                let messageModel = StreamMessageModel(withDictionary: message)
                self?.chatReceiver?.chatReceiverHandle(taskResult: StreamChatServiceTaskResult.serviceDidSendMessage(message: messageModel))
            } else {
                self?.chatReceiver?.chatReceiverHandle(taskResult: StreamChatServiceTaskResult.serviceDidFailMessage())
            }
        })
    }
    
    // MARK: Protocols Implementation
    
    // MARK: WebRTCManagerDelegate
    
    internal func showLocalStreamView(_ streamView: UIView) {
        self.streamReceiver?.streamReceiverHandle(taskResult: VideoStreamServiceTaskResult.serviceShouldShowCameraView(cameraView: streamView))
    }
    
    internal func showRemoteStreamView(_ streamView: UIView) {
        self.streamReceiver?.streamReceiverHandle(taskResult: VideoStreamServiceTaskResult.serviceShouldShowStreamingView(streamingView: streamView))
    }
    
    internal func removeRemoteStreamView() {
        self.streamReceiver?.streamReceiverHandle(taskResult: VideoStreamServiceTaskResult.serviceShouldHideStreamingView())
    }
    
    internal func sendSessionDescription(_ sessionDescription: String, publishing: Bool, videoEnabled: Bool, completion: ((Bool, [String : Any]?) -> ())?) {
        self.socketManager?.passStreamSessionDiscription(sessionDescription, publishing: publishing, videoEnabled: videoEnabled, completion: { (success, response) in
            
            if success {
                self.streamReceiver?.streamReceiverHandle(taskResult: VideoStreamServiceTaskResult.serviceStartedStreaming())
            }
            
            completion?(success, response)
        })
    }
    
    private func drainRemoteCandidates() {
        print("SENDING WAITING CANDIDATES: " + String(waitingRemoteCandidates.count))
        for candidate in waitingRemoteCandidates {
            self.socketManager?.passStreamCandidate(candidate)
        }
        
        waitingRemoteCandidates.removeAll()
    }
    
    internal func sessionDescriptionDidSetWithError(_ error: Error?) {
        if error == nil, let videoEnabled = webRTCManager?.isVideoEnabled() {
            let isStreaming = self.webRTCManager?.isStreaming()
            sessionDescriptionIsSet = true
            if isStreaming == true {
                drainRemoteCandidates()
                self.socketManager?.streamConnected(videoEnabled: videoEnabled, { (success) in
                    print ("sessionDescriptionDidSetWithError called " + success.description)
                })
            }
        }
    }
    
    internal func sendCandidate(_ candidate: [String:Any]) {
        if sessionDescriptionIsSet {
            print("CANDIDATE PASSED")
            self.socketManager?.passStreamCandidate(candidate)
        } else {
            print ("CANDIDATE ADDED TO QUEUE")
            waitingRemoteCandidates.append(candidate)
        }
    }
    
    internal func streamDidChangeState(_ state: RTCIceConnectionState) {
        self.streamReceiver?.streamReceiverHandle(taskResult: VideoStreamServiceTaskResult.serviceDidChangeStreamState(state: state))
    }
    
    // MARK: SocketManagerDelegate
    
    internal func socketConnected() {
        self.streamReceiver?.streamReceiverHandle(taskResult: VideoStreamServiceTaskResult.serviceWaitingForSession())
    }
    
    internal func socketDisconnected() {
        sessionDescriptionIsSet = false
        waitingRemoteCandidates.removeAll()
        //self.streamReceiver?.streamReceiverHandle(taskResult: VideoStreamServiceTaskResult.serviceLogoutedFromSession(error: nil))
    }
    
    internal func socketReceivedStreamCandidate(withResponse response: [String : Any]?) {
        self.webRTCManager?.receiveCandidate(response)
    }
    
    internal func socketJoinedSession(withResponse response: [String : Any]?, errorMessage: String?) {
        if let data = response, errorMessage == nil {
            if let serverTime = data[Keys.serverTime] as? Int64, let sessionInfo = data[Keys.session] as? [String:Any], let status = data[Keys.status] as? Int {
                let sessionStarted = (status != SessionStreamStatus.notStarted.rawValue)
                let sessionFinished = (status == SessionStreamStatus.finished.rawValue)
                
                if sessionFinished {
                    let error = ApplicationMessages.ErrorMessages.sessionFinished
                    self.streamReceiver?.streamReceiverHandle(taskResult: VideoStreamServiceTaskResult.serviceDidEnterSession(serverTime: nil, session: nil, stream: nil, errorMessage: error, sessionStarted: sessionStarted, sessionFinished: sessionFinished))
                    return
                } else {
                    self.streamReceiver?.streamReceiverHandle(taskResult: VideoStreamServiceTaskResult.serviceDidEnterSession(serverTime: serverTime, session: sessionInfo, stream: data, errorMessage: nil, sessionStarted: sessionStarted, sessionFinished: sessionFinished))
                    return
                }
            }
        }
        
        if let error = errorMessage {
            self.streamReceiver?.streamReceiverHandle(taskResult: VideoStreamServiceTaskResult.serviceDidEnterSession(serverTime: nil, session: nil, stream: nil, errorMessage: error, sessionStarted: false, sessionFinished: false))
        } else {
            let error = ApplicationMessages.ErrorMessages.serverError
            self.streamReceiver?.streamReceiverHandle(taskResult: VideoStreamServiceTaskResult.serviceDidEnterSession(serverTime: nil, session: nil, stream: nil, errorMessage: error, sessionStarted: false, sessionFinished: false))
        }
    }
    
    internal func socketMustExitSession(withError error: String?) {
        self.streamReceiver?.streamReceiverHandle(taskResult: VideoStreamServiceTaskResult.serviceLogoutedFromSession(error: error))
    }
    
    internal func socketFinishedSession(withResponse response: [String : Any]?) {
        let sessionInfo = response?[Keys.session] as? [String:Any]
        self.streamReceiver?.streamReceiverHandle(taskResult: VideoStreamServiceTaskResult.serviceFinishedSession(session: sessionInfo, stream: response))
    }
    
    internal func socketStartedSession() {
        self.streamReceiver?.streamReceiverHandle(taskResult: VideoStreamServiceTaskResult.serviceStartedSession())
    }
    
    internal func socketStreamPublished() {
        self.streamReceiver?.streamReceiverHandle(taskResult: VideoStreamServiceTaskResult.serviceStreamPublished())
    }
    
    internal func socketStreamChangedVideoEnabled(_ enabled: Bool) {
        self.streamReceiver?.streamReceiverHandle(taskResult: VideoStreamServiceTaskResult.serviceChangedVideoEnabled(enabled: enabled))
    }
    
    internal func socketReceivedMessage(withResponse response: [String : Any]?) {
        if let message = response {
            let messageModel = StreamMessageModel(withDictionary: message)
            self.chatReceiver?.chatReceiverHandle(taskResult: StreamChatServiceTaskResult.serviceDidReceiveMessage(message: messageModel))
        }
    }
    
}
