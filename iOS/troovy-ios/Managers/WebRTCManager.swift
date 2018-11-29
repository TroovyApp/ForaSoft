//
//  WebRTCManager.swift
//  troovy-ios
//
//  Created by Daniil on 13.10.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import Foundation
import MetalKit

protocol WebRTCManagerDelegate: class {
    func showLocalStreamView(_ streamView: UIView)
    func showRemoteStreamView(_ streamView: UIView)
    
    func removeRemoteStreamView()
    
    func streamDidChangeState(_ state: RTCIceConnectionState)
    
    func sendSessionDescription(_ sessionDescription: String, publishing: Bool, videoEnabled: Bool, completion: ((_ success: Bool, _ response: [String:Any]?) -> ())?)
    func sendCandidate(_ candidate: [String:Any])
    func sessionDescriptionDidSetWithError(_ error: Error?)
}

class LocalMediaStream {
    
    // MARK: Public Properties
    
    private(set) var localMediaStream: RTCMediaStream?
    
    private(set) var peerConnectionFactory = RTCPeerConnectionFactory()
    
    private(set) var cameraVideoCapturer: RTCCameraVideoCapturer?
    
    private(set) var localVideoTrack: RTCVideoTrack?
    
    // MARK: Private Properties
    
    private var label: String?
    
    private var cameraPosition: AVCaptureDevice.Position = .front
    
    // MARK: Init Methods & Superclass Overriders
    
    static let shared = LocalMediaStream()
    
    // MARK: Public Methods
    
    /// Setups local media stream with label.
    ///
    /// - parameter label: Used as stream id for peer connection factory and as track id for audio and video tracks.
    ///
    func setup(withLabel label: String!) {
        if self.label != nil && self.label == label {
            self.cameraPosition = .front
            self.runCameraCapturer(withCameraPosition: self.cameraPosition)
        } else {
            if self.label != nil && self.label != label {
                self.stopCameraCapturer()
                
                self.localVideoTrack = nil
                self.localMediaStream = nil
                self.cameraVideoCapturer = nil
            }
            
            self.label = label
            
            self.localMediaStream = self.peerConnectionFactory.mediaStream(withStreamId: "\(label!)")
            
            let audioTrack = self.peerConnectionFactory.audioTrack(withTrackId: "\(label!)a0")
            self.localMediaStream?.addAudioTrack(audioTrack)
            
            let vidSource = self.peerConnectionFactory.videoSource()
            self.cameraVideoCapturer = RTCCameraVideoCapturer(delegate: vidSource)
            self.runCameraCapturer(withCameraPosition: self.cameraPosition)
            
            if let capturer = self.cameraVideoCapturer {
                NotificationCenter.default.removeObserver(capturer, name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
            }
            
            self.localVideoTrack = self.peerConnectionFactory.videoTrack(with: vidSource, trackId: "\(label!)v0")
            if let videoTrack = self.localVideoTrack  {
                self.localMediaStream?.addVideoTrack(videoTrack)
            }
        }
    }
    
    func toggleCamera() {
        guard let capturedSession = self.cameraVideoCapturer?.captureSession else {
            return
        }
        
        if capturedSession.isRunning {
            if self.cameraPosition == .front {
                self.cameraPosition = .back
            } else {
                self.cameraPosition = .front
            }
            
            self.runCameraCapturer(withCameraPosition: self.cameraPosition)
        }
    }
    
    // MARK: Private Methods
    
    private func runCameraCapturer(withCameraPosition position: AVCaptureDevice.Position) {
        guard let capturer = self.cameraVideoCapturer, let device = self.captureDevice(fromCameraVideoCapturer: capturer, position: position), let format = self.captureFormat(fromCaptureDevice: device) else {
            return
        }
        
        let framesPerSecond = self.framesPerSecond(fromCaptureFormat: format)
        capturer.startCapture(with: device, format: format, fps: framesPerSecond)
    }
    
    private func stopCameraCapturer() {
        guard let capturedSession = self.cameraVideoCapturer?.captureSession else {
            return
        }
        
        if capturedSession.isRunning {
            self.cameraVideoCapturer?.stopCapture()
        }
    }
    
    private func captureDevice(fromCameraVideoCapturer capturer: RTCCameraVideoCapturer, position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let captureDevices = RTCCameraVideoCapturer.captureDevices()
        for device in captureDevices {
            if device.position == position {
                return device
            }
        }
        
        return captureDevices.first
    }
    
    private func captureFormat(fromCaptureDevice device: AVCaptureDevice) -> AVCaptureDevice.Format? {
        var selectedFormat: AVCaptureDevice.Format?
        let targetWidth: Int32 = 1920
        let targetHeight: Int32 = 1080
        let targetAspectRatio: CGFloat = CGFloat(targetWidth) / CGFloat(targetHeight)
        var currentDiff = INT_MAX
        
        let captureDeviceFormats = RTCCameraVideoCapturer.supportedFormats(for: device)
        for format in captureDeviceFormats {
            let dimension = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            let diff = abs(targetWidth - dimension.width) + abs(targetHeight - dimension.height)
            let aspectRatio: CGFloat = CGFloat(dimension.width) / CGFloat(dimension.height)
            
            if abs(targetAspectRatio - aspectRatio) > 0.00001 { continue }
            
            if diff < currentDiff {
                selectedFormat = format
                currentDiff = diff
            }
        }
        
        return selectedFormat
    }
    
    private func framesPerSecond(fromCaptureFormat format: AVCaptureDevice.Format) -> Int {
        let maxFramerate: Float64 = 30.0
        var maxFormatFramerate: Float64 = 0.0
        var minFormatFramerate: Float64 = Float64.greatestFiniteMagnitude
        
        let supportedFrameRateRanges = format.videoSupportedFrameRateRanges
        for range in supportedFrameRateRanges {
            maxFormatFramerate = fmax(maxFormatFramerate, range.maxFrameRate)
            minFormatFramerate = fmin(minFormatFramerate, range.minFrameRate)
        }
        
        if maxFormatFramerate > maxFramerate {
            if minFormatFramerate > maxFramerate {
                return Int(minFormatFramerate)
            } else {
                return Int(maxFramerate)
            }
        } else {
            return Int(maxFormatFramerate)
        }
    }
    
}

class WebRTCManager: NSObject, RTCPeerConnectionDelegate {
    
    private struct CandidateKeys {
        static let sessionDescriptionMid = "sdpMid"
        static let sessionDescriptionMLineIndex = "sdpMLineIndex"
        static let candidate = "candidate"
    }
    
    private struct SessionDescriptionKeys {
        static let answerDescription = "answerSdp"
        static let offerDescription = "offerSdp"
    }
    
    // MARK: Private Properties
    
    private weak var delegate: WebRTCManagerDelegate?
    
    private let infoPlistService = InfoPlistService()
    
    private var peerConnection: RTCPeerConnection?
    private var remoteMediaStream: RTCMediaStream?
    
    private var queuedLocalCandidates = NSMutableSet()
    
    private var sessionID: String!
    private var networkToken: String!
    private var userID: String!
    
    private var streaming = false
    private var watching = false
    
    private var remoteVideoView: RTCEAGLVideoView!
    
    private static let streamLabel: String = UUID().uuidString.replacingOccurrences(of: "-", with: "")
    private static let kRTCMediaConstraintsDtlsSrtpKeyAgreement = "DtlsSrtpKeyAgreement"
    
    // MARK: Init Methods & Superclass Overriders
    
    init(withSessionID sessionID: String, networkToken: String, userID: String, delegate: WebRTCManagerDelegate?) {
        self.sessionID = sessionID
        self.networkToken = networkToken
        self.userID = userID
        self.delegate = delegate
    }
    
    deinit {
        self.stopPeerConnection()
    }
    
    // MARK: Public Methods
    
    /// Creates local media stream.
    func startCamera() {
        LocalMediaStream.shared.setup(withLabel: WebRTCManager.streamLabel)
        
        let localStreamView = RTCCameraPreviewView(frame: UIScreen.main.bounds)
        localStreamView.translatesAutoresizingMaskIntoConstraints = false
        localStreamView.captureSession = LocalMediaStream.shared.cameraVideoCapturer?.captureSession
        if let cameraPreviewLayer = localStreamView.layer as? AVCaptureVideoPreviewLayer {
            cameraPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        }
        self.delegate?.showLocalStreamView(localStreamView)
    }
    
    /// Starts streaming peer connection.
    func startStreaming(withServers servers: [RTCIceServer]?) -> Bool {
        if self.streaming {
            return true
        }
        if self.watching {
            self.stopWatching()
        }
        
        self.queuedLocalCandidates.removeAllObjects()
        self.streaming = true
        self.watching = false
        
        self.setupAudioSession()
        self.createConnection(withServers: servers)
        
        return false
    }
    
    /// Starts watching peer connection.
    func startWatching(withServers servers: [RTCIceServer]?) {
        if self.watching {
            return
        }
        if self.streaming {
            self.stopStreaming()
        }
        
        self.queuedLocalCandidates.removeAllObjects()
        self.streaming = false
        self.watching = true
        
        self.setupAudioSession()
        self.createConnection(withServers: servers)
    }
    
    /// Determines if watching stream started.
    ///
    /// - returns: True if watching stream started. False otherwise.
    ///
    func isWatching() -> Bool {
        return self.watching
    }
    
    func isStreaming() -> Bool {
        return self.streaming
    }
    
    func isVideoEnabled() -> Bool {
        return LocalMediaStream.shared.localMediaStream?.videoTracks.first?.isEnabled ?? true
    }
    
    /// Stops streaming peer connection.
    func stopStreaming() {
        if !self.streaming {
            return
        }
        
        self.streaming = false
        self.stopPeerConnection()
    }
    
    /// Stops watching peer connection.
    func stopWatching() {
        if !self.watching {
            return
        }
        
        self.watching = false
        self.stopPeerConnection()
    }
    
    /// Turns on/off the local media stream audio tracks.
    ///
    /// - parameter enabled: Determines should be audio enabled.
    ///
    func setMicrophone(enabled: Bool) {
        guard let audioTrack = LocalMediaStream.shared.localMediaStream?.audioTracks.first else {
            return
        }
        
        audioTrack.isEnabled = enabled
    }
    
    /// Turns on/off the local media stream video tracks.
    ///
    /// - parameter enabled: Determines should be video enabled.
    ///
    func setCamera(enabled: Bool) {
        guard let videoTrack = LocalMediaStream.shared.localMediaStream?.videoTracks.first else {
            return
        }
        
        videoTrack.isEnabled = enabled
    }
    
    func setRemoteVideo(enabled: Bool) {
        if enabled {
            if let track = remoteMediaStream?.videoTracks.first {
                print("REATTACH REMOTE VIEW")
                track.remove(self.remoteVideoView)
                self.remoteVideoView = nil
                let newRemoteVideoView = RTCEAGLVideoView(frame: UIScreen.main.bounds)
                newRemoteVideoView.translatesAutoresizingMaskIntoConstraints = false
                newRemoteVideoView.transform = CGAffineTransform(scaleX: -1, y: 1)
                newRemoteVideoView.backgroundColor = .clear
                self.remoteVideoView = newRemoteVideoView
                track.add(newRemoteVideoView)
                
                self.delegate?.showRemoteStreamView(newRemoteVideoView)
            }
        }
    }
    
    /// Toggles device camera.
    func toggleCamera() {
        LocalMediaStream.shared.toggleCamera()
    }
    
    /// Turns on/off the local remote stream audio tracks.
    ///
    /// - parameter enabled: Determines should be audio enabled.
    ///
    func setSound(enabled: Bool) {
        guard let audioTrack = self.remoteMediaStream?.audioTracks.first else {
            return
        }
        
        audioTrack.isEnabled = enabled
    }
    
    /// Adds candidate to the peer connection.
    ///
    /// - parameter response: Server candidate data.
    ///
    func receiveCandidate(_ response: [String:Any]?) {
        guard let candidate = self.candidateFromDictionary(response) else {
            return
        }
        
        self.peerConnection?.add(candidate)
    }
    
    // MARK: Private Methods
    
    // MARK: Streams
    
    private func createConnection(withServers servers: [RTCIceServer]?) {
        let peerConnectionConstraints = self.peerConnectionConstraints(withAudio: self.watching, withVideo: self.watching)
        
        let configuration = RTCConfiguration()
        if let iceServers = servers, iceServers.count > 0 {
            configuration.iceServers = iceServers
        } else {
            configuration.iceServers = self.defaultIceServers()
        }
        
        self.peerConnection = LocalMediaStream.shared.peerConnectionFactory.peerConnection(with: configuration, constraints: peerConnectionConstraints, delegate: self)
        
        if self.streaming {
            if let localStream = LocalMediaStream.shared.localMediaStream {
                self.peerConnection?.add(localStream)
            }
        }
        
        self.sendOffer()
    }
    
    // MARK: Peer Connection
    
    private func peerConnection(didCreateSessionDescription sessionDescription: RTCSessionDescription?, withError peerConnectionError: Error?) {
        if let errorMessage = peerConnectionError?.localizedDescription {
            print("peerConnection error didCreateSessionDescription \(errorMessage)")
        }
        
        if let description = sessionDescription {
            //let adoptedSessionDescription = self.adoptedSessionDescription(description, adoptAudio: false)
            self.peerConnection?.setLocalDescription(description, completionHandler: { [weak self] (error) in
                DispatchQueue.main.async {
                    self?.peerConnection(didSetSessionDescriptionWithError: error)
                    self?.sendSessionDescription(description)
                }
            })
        }
    }
    
    private func peerConnection(didSetSessionDescriptionWithError peerConnectionError: Error?) {
        if let errorMessage = peerConnectionError?.localizedDescription {
            print("peerConnection didSetSessionDescriptionWithError \(errorMessage)")
        } else {
            print("peerConnection didSetSessionDescription success!")
        }
        
        if self.peerConnection?.remoteDescription != nil {
            self.delegate?.sessionDescriptionDidSetWithError(peerConnectionError)
            self.drainLocalCandidates()
        }
    }
    
    private func peerConnection(didAddStream stream: RTCMediaStream?) {
        if self.streaming {
            return
        }
        
        self.remoteMediaStream = stream
        
        var videoView: (UIView & RTCVideoRenderer)!
        #if (RTC_SUPPORTS_METAL)
            videoView = RTCMTLVideoView(frame: UIScreen.main.bounds)
            for subview in videoView.subviews {
                if let metalView = subview as? MTKView {
                    metalView.contentMode = .scaleAspectFill
                    metalView.backgroundColor = .clear
                }
            }
        #else
            videoView = RTCEAGLVideoView(frame: UIScreen.main.bounds)
            videoView.translatesAutoresizingMaskIntoConstraints = false
        
        #endif
        
        videoView.backgroundColor = .clear
        if let track = stream?.videoTracks.first {
            track.add(videoView)
        }
        self.delegate?.showRemoteStreamView(videoView)

        self.setupAudioSession()
    }
    
    private func peerConnection(didRemoveStream stream: RTCMediaStream?) {
        if self.streaming {
            return
        }
        
        self.delegate?.removeRemoteStreamView()
    }
    
    private func peerConnection(didAddCandidate candidate: RTCIceCandidate) {
        if self.peerConnection?.remoteDescription != nil {
            self.sendCandidate(candidate)
        } else {
            self.queuedLocalCandidates.add(candidate)
        }
    }
    
    private func peerConnection(didChangeState state: RTCIceConnectionState) {
        self.delegate?.streamDidChangeState(state)
    }
    
    // MARK: Ice Candidates
    
    private func drainLocalCandidates() {
        for remoteCandidates in self.queuedLocalCandidates {
            if let candidate = remoteCandidates as? RTCIceCandidate {
                self.sendCandidate(candidate)
            }
        }
        
        self.queuedLocalCandidates.removeAllObjects()
    }
    
    // MARK: Offers & Answers
    
    private func sendOffer() {
        let mediaConstraints = self.mediaConstraints(withAudio: self.watching, withVideo: self.watching)
        
        self.peerConnection?.offer(for: mediaConstraints, completionHandler: { [weak self] (sessionDescription, error) in
            DispatchQueue.main.async {
                self?.peerConnection(didCreateSessionDescription: sessionDescription, withError: error)
            }
        })
    }
    
    private func receiveAnswer(_ response: String) {
        guard let sessionDescription = self.sessionDescriptionFromString(response, type: RTCSdpType.answer) else {
            return
        }
        
        //let adoptedSessionDescription = self.adoptedSessionDescription(sessionDescription, adoptAudio: true)
        self.peerConnection?.setRemoteDescription(sessionDescription, completionHandler: { [weak self] (error) in
            DispatchQueue.main.async {
                self?.peerConnection(didSetSessionDescriptionWithError: error)
            }
        })
    }
    
    // MARK: Send SDP & Candidates
    
    private func sendSessionDescription(_ sessionDescription: RTCSessionDescription?) {
        guard let description = self.sessionDescriptionToString(sessionDescription) else {
            return
        }
        
        let videoEnabled = LocalMediaStream.shared.localMediaStream?.videoTracks.first?.isEnabled ?? true
        self.delegate?.sendSessionDescription(description, publishing: self.streaming, videoEnabled: videoEnabled, completion: { [weak self] (success, response) in
            if !success {
                self?.sendSessionDescription(sessionDescription)
            } else {
                if let answerSDP = response?[SessionDescriptionKeys.answerDescription] as? String {
                    DispatchQueue.main.async {
                        self?.receiveAnswer(answerSDP)
                    }
                }
            }
        })
    }
    
    private func sendCandidate(_ candidate: RTCIceCandidate?) {
        guard let candidateDictionary = self.candidateToDictionary(candidate) else {
            return
        }
        
        self.delegate?.sendCandidate(candidateDictionary)
    }
    
    // MARK: WebRTC Constraints
    
    private func peerConnectionConstraints(withAudio: Bool, withVideo: Bool) -> RTCMediaConstraints {
        let optionalConstraintes = [WebRTCManager.kRTCMediaConstraintsDtlsSrtpKeyAgreement: kRTCMediaConstraintsValueTrue]
        
        let peerConnectionConstraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: optionalConstraintes)
        return peerConnectionConstraints
    }
    
    private func mediaConstraints(withAudio: Bool, withVideo: Bool) -> RTCMediaConstraints {
        let mandatoryConstraints = [kRTCMediaConstraintsOfferToReceiveAudio: (withAudio ? kRTCMediaConstraintsValueTrue : kRTCMediaConstraintsValueFalse),
                                    kRTCMediaConstraintsOfferToReceiveVideo : (withVideo ? kRTCMediaConstraintsValueTrue : kRTCMediaConstraintsValueFalse)]
        
        let mediaConstraints = RTCMediaConstraints(mandatoryConstraints: mandatoryConstraints, optionalConstraints: nil)
        return mediaConstraints
    }
    
    // MARK: Support Methods
    
    private func setupAudioSession() {
        if self.watching {
            RTCDispatcher.dispatchAsync(on: RTCDispatcherQueueType.typeAudioSession) {
                let session = RTCAudioSession.sharedInstance()
                session.lockForConfiguration()
                try? session.setCategory(AVAudioSessionCategoryPlayAndRecord, with: [AVAudioSessionCategoryOptions.defaultToSpeaker, AVAudioSessionCategoryOptions.allowBluetooth, AVAudioSessionCategoryOptions.allowBluetoothA2DP, AVAudioSessionCategoryOptions.allowAirPlay, AVAudioSessionCategoryOptions.mixWithOthers])
                try? session.setMode(AVAudioSessionModeVideoChat)
                try? session.setActive(true)
                session.unlockForConfiguration()
            }
        } else if self.streaming {
            RTCDispatcher.dispatchAsync(on: RTCDispatcherQueueType.typeAudioSession) {
                let session = RTCAudioSession.sharedInstance()
                session.lockForConfiguration()
                try? session.setCategory(AVAudioSessionCategoryRecord, with: [AVAudioSessionCategoryOptions.allowBluetooth])
                try? session.setMode(AVAudioSessionModeVideoRecording)
                try? session.setActive(true)
                session.unlockForConfiguration()
            }
        }
    }
    
    private func stopPeerConnection() {
        if let localMediaStream = LocalMediaStream.shared.localMediaStream {
            self.peerConnection?.remove(localMediaStream)
        }
        
        if let peerConnection = self.peerConnection {
            if peerConnection.iceConnectionState != RTCIceConnectionState.closed {
                peerConnection.close()
            }
            
            self.peerConnection = nil
        }
        
        self.remoteMediaStream = nil
    }
    
    private func defaultIceServers() -> [RTCIceServer] {
        let turnServersAddresses = self.infoPlistService.turnServersAddresses()
        let turnServersUsername = self.infoPlistService.turnServersUsername()
        let turnServersCredential = self.infoPlistService.turnServersCredential()
        let turnServer = RTCIceServer(urlStrings: turnServersAddresses, username: turnServersUsername, credential: turnServersCredential)
        
        let stunServersAddresses = self.infoPlistService.stunServersAddresses()
        let stunServer = RTCIceServer.init(urlStrings: stunServersAddresses)
        
        return [turnServer, stunServer]
    }
    
    private func signalingStateToString(_ signalingState: RTCSignalingState) -> String {
        switch signalingState {
        case .stable:
            return "stable"
        case .haveLocalOffer:
            return "have local offer"
        case .haveRemoteOffer:
            return "have remote offer"
        case .haveLocalPrAnswer:
            return "have local answer"
        case .haveRemotePrAnswer:
            return "have remote answer"
        case .closed:
            return "closed"
        }
    }
    
    private func iceConnectionStateToString(_ iceConnectionState: RTCIceConnectionState) -> String {
        switch iceConnectionState {
        case .new:
            return "new"
        case .checking:
            return "checking"
        case .completed:
            return "completed"
        case .connected:
            return "connected"
        case .disconnected:
            return "disconnected"
        case .failed:
            return "failed"
        case .count:
            return "count"
        case .closed:
            return "closed"
        }
    }
    
    private func iceGatheringStateToString(_ iceGatheringState: RTCIceGatheringState) -> String {
        switch iceGatheringState {
        case .new:
            return "new"
        case .gathering:
            return "gathering"
        case .complete:
            return "complete"
        }
    }
    
    private func candidateToDictionary(_ candidate: RTCIceCandidate?) -> [String:Any]? {
        guard let description = candidate?.sdp, let sdpMLineIndex = candidate?.sdpMLineIndex, let sessionDescriptionMid = candidate?.sdpMid else {
            return nil
        }
        
        let candidateDictionary: [String:Any] = [CandidateKeys.candidate : description,
                                                 CandidateKeys.sessionDescriptionMLineIndex : sdpMLineIndex,
                                                 CandidateKeys.sessionDescriptionMid : sessionDescriptionMid]
        return candidateDictionary
    }
    
    private func candidateFromDictionary(_ dictionary: [String:Any]?) -> RTCIceCandidate? {
        guard let candidateDictionary = dictionary?[CandidateKeys.candidate] as? [String:Any], let description = candidateDictionary[CandidateKeys.candidate] as? String, let sessionDescriptionMLineIndex = candidateDictionary[CandidateKeys.sessionDescriptionMLineIndex] as? Int32, let sdpMid = candidateDictionary[CandidateKeys.sessionDescriptionMid] as? String else {
            return nil
        }
        
        let candidate = RTCIceCandidate(sdp: description, sdpMLineIndex: sessionDescriptionMLineIndex, sdpMid: sdpMid)
        return candidate
    }
    
    private func sessionDescriptionToString(_ sessionDescription: RTCSessionDescription?) -> String? {
        guard let description = sessionDescription?.sdp else {
            return nil
        }
        
        return description
    }
    
    private func sessionDescriptionFromString(_ string: String?, type: RTCSdpType) -> RTCSessionDescription? {
        guard let description = string else {
            return nil
        }
        
        let sessionDescription = RTCSessionDescription(type: type, sdp: description)
        return sessionDescription
    }
    
    private func firstMatch(withExpression expression: NSRegularExpression?, inString string: String) -> String? {
        let range = NSMakeRange(0, string.count)
        if let result = expression?.firstMatch(in: string, options: NSRegularExpression.MatchingOptions.init(rawValue: 0), range: range) {
            if result.numberOfRanges > 1 {
                let resultRange = result.range(at: 1)
                let match = (string as NSString).substring(with: resultRange)
                return match
            }
        }
        
        return nil
    }
    
    private func adoptedSessionDescription(_ sessionDescription: RTCSessionDescription, adoptAudio: Bool) -> RTCSessionDescription {
        var adoptedSessionDescriptionString = sessionDescription.sdp.replacingOccurrences(of: "UDP/TLS/RTP/SAVPF", with: "RTP/SAVPF")
        let lines = adoptedSessionDescriptionString.components(separatedBy: "\r\n")
        
        if adoptAudio {
            var audioMLineIndex: Int?
            var audioMatch: String?
            let audioRegularExpression = try? NSRegularExpression.init(pattern: "^a=rtpmap:(\\d+) ISAC/16000[\r]?$", options: NSRegularExpression.Options.init(rawValue: 0))
            for index in 0..<lines.count {
                if audioMLineIndex != nil && audioMatch != nil {
                    break
                }
                
                let line = lines[index]
                if line.hasPrefix("m=audio ") {
                    audioMLineIndex = index
                    continue
                }
                
                audioMatch = self.firstMatch(withExpression: audioRegularExpression, inString: line)
            }
            
            if let mLineIndex = audioMLineIndex, let match = audioMatch {
                let lineParts = lines[mLineIndex].components(separatedBy: " ")
                var newMLine: [String] = []
                
                newMLine.append(lineParts[0])
                newMLine.append(lineParts[1])
                newMLine.append(lineParts[2])
                newMLine.append(match)
                
                for index in 4..<lineParts.count {
                    let line = lineParts[index]
                    if match != line {
                        newMLine.append(line)
                    }
                }
                
                var newLines: [String] = []
                newLines += lines
                newLines[mLineIndex] = newMLine.joined(separator: " ")
                
                adoptedSessionDescriptionString = newLines.joined(separator: "\r\n")
            }
        }
        
        let adoptedSessionDescription = RTCSessionDescription.init(type: sessionDescription.type, sdp: adoptedSessionDescriptionString)
        return adoptedSessionDescription
    }
    
    // MARK: Protocols Implementation
    
    // MARK: RTCPeerConnectionDelegate
    
    internal func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        #if DEBUG
            print("peer сonnection did change signaling state - \(self.signalingStateToString(stateChanged))")
        #endif
    }
    
    internal func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        #if DEBUG
            print("peer сonnection did change connection state - \(self.iceConnectionStateToString(newState))")
        #endif
        
        DispatchQueue.main.async {
            self.peerConnection(didChangeState: newState)
        }
    }
    
    internal func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        #if DEBUG
            print("peer сonnection did change gathering state - \(self.iceGatheringStateToString(newState))")
        #endif
    }
    
    internal func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        #if DEBUG
            print("peer сonnection did remove \(candidates.count) candidates")
        #endif
    }
    
    internal func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        DispatchQueue.main.async {
            self.peerConnection(didAddCandidate: candidate)
        }
    }
    
    internal func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        #if DEBUG
            print("peer сonnection did open data channel")
        #endif
    }
    
    internal func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        DispatchQueue.main.async {
            self.peerConnection(didRemoveStream: stream)
        }
    }
    
    internal func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        DispatchQueue.main.async {
            self.peerConnection(didAddStream: stream)
        }
    }
    
    internal func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        #if DEBUG
            print("peer сonnection should negotiate")
        #endif
    }
    
}
