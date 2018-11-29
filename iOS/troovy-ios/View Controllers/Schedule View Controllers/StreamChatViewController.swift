//
//  StreamChatViewController.swift
//  troovy-ios
//
//  Created by Daniil on 13.11.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

import RSKGrowingTextView
import ReverseExtension

class StreamChatViewController: TroovyViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate {
    
    private var messagessQueue: DispatchQueue! = DispatchQueue(label: "StreamMessagesQueue")
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var tableContainerView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextView: RSKGrowingTextView!
    
    // MARK: Public Properties
    
    /// Model of the unauthorised user.
    var authorisedUserModel: AuthorisedUserModel!
    
    var sessionID: String!
    
    var streamerID: String!
    
    /// Model of the unauthorised user.
    var readyForSending = false {
        didSet {
            self.configureTextView()
            self.loadMessages()
        }
    }
    
    // MARK: Properties Overriders
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: Private Properties
    
    private let infoPlistService = InfoPlistService()
    private var verificationService: VerificationService!
    private var videoStreamService: VideoStreamService!
    
    private var gradient = CAGradientLayer()
    
    private var messages = OrderedSet<StreamMessageModel>()
    private var messagesLoaded = false
    private var messagesLoading = false
    
    private var loadMessagesMethod: String?
    
    // MARK: Init Methods & Superclass Overriders

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupTableView()
        self.setupTextView()
        self.configureTextView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.setNeedsStatusBarAppearanceUpdate()
        
        if !self.messagesLoaded && self.readyForSending {
            self.loadMessages()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.gradient.frame = self.tableContainerView.bounds
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func inject(propertiesWithAssembly assembly: ViewControllerAssemblyManager) {
        self.videoStreamService = assembly.videoStreamService
        self.verificationService = assembly.verificationService
    }
    
    override func configureServices()                            {
        self.videoStreamService.delegate = self
        //self.videoStreamService.chatReceiver = self
    }
    
    override func serviceMethodSucceeded(withMethod method: String, resultDictionary: [String : Any]?, resultArray: [[String : Any]]?, resultString: String?) {
        if method == self.loadMessagesMethod {
            if let messagesDictionaries = resultArray {
                self.messagesLoaded = true
                
                var messages: [StreamMessageModel] = []
                for dictionary in messagesDictionaries {
                    let message = StreamMessageModel(withDictionary: dictionary)
                    messages.append(message)
                }
                
                if messages.count > 0 {
                    self.appendMessages(messages)
                }
            }
            
            self.messagesLoading = false
        }
    }
    
    override func showLoadingView(withMethod method: String) {
        if method == self.loadMessagesMethod {
            return
        }
    }
    
    override func serviceMethodFailed(withMethod method: String) {
        if method == self.loadMessagesMethod {
            self.messagesLoaded = false
            self.messagesLoading = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.loadMessages()
            }
            
            return
        }
    }
    
    override func shouldShowAlert(forMethod method: String) -> Bool {
        return false
    }
    
    // MARK: Private Methods
    
    private func setupTableView() {
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 48.0
        self.tableView.re.delegate = self
        
        self.gradient.colors = [UIColor.clear.cgColor, UIColor.white.cgColor, UIColor.white.cgColor]
        self.gradient.frame = self.tableContainerView.bounds
        self.gradient.locations = [NSNumber(value: 0.0), NSNumber(value: 0.7), NSNumber(value: 1.0)]
        self.tableContainerView.layer.mask = self.gradient
    }
    
    private func setupTextView() {
        self.messageTextView.tintColor = .white
    }
    
    private func loadMessages() {
        if !self.readyForSending {
            self.messagesLoaded = false
            return
        }
        
        if self.messagesLoading {
            return
        }
        
        self.messagesLoading = true
        self.loadMessagesMethod = self.videoStreamService.loadSessionMessages(withID: self.sessionID, user: self.authorisedUserModel)
    }
    
    private func configureTextView() {
        if self.readyForSending {
            
        } else {
            
        }
    }
    
    private func setInterfaceSending(_ sending: Bool) {
        if sending {
            
        } else {
            
        }
    }
    
    private func appendMessage(_ message: StreamMessageModel) {
        self.messagessQueue.async {
            self.messages.insert(item: message)
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    private func appendMessages(_ messages: [StreamMessageModel]) {
        self.messagessQueue.async {
            for message in messages {
                self.messages.insert(item: message)
            }
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: Protocols Implementation
    
    // MARK: UITextViewDelegate
    
    internal func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            if let messageText = self.verificationService.check(string: self.messageTextView.text) {
                textView.text = nil
                self.setInterfaceSending(true)
                self.videoStreamService.sendMessage(text: messageText)
                
                return false
            }
        }
        
        return true
    }
    
    // MARK: UITableViewDelegate & UITableViewDataSource
    
    internal func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    internal func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.messages.count
    }
    
    internal func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = self.messages[indexPath.row]
        let serverAddress = self.infoPlistService.serverURL()
        
        let isStreamer = (message.senderID == self.streamerID)
        let isCurrentUser = (message.senderID == self.authorisedUserModel.id)
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "StreamChatMessageTableViewCell", for: indexPath) as! StreamChatMessageTableViewCell
        cell.configure(withUsername: message.senderName, message: message.text, serverAddress: serverAddress, avatarImageURL: message.senderProfilePictureURL, isStreamer: isStreamer, isCurrentUser: isCurrentUser)
        return cell
    }
    
    internal func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    internal func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    internal func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return tableView.bounds.height / 3.0 * 2.0
    }
    
    // TODO: Fix this to list of delegates / notifications
    // MARK: StreamChatServiceDelegate (forwarded by VideoStreamViewController)
    
    public func chatReceiverHandle(taskResult result: StreamChatServiceTaskResult) {
        switch result {
        case .serviceDidFailMessage():
            self.setInterfaceSending(false)
            break
        case .serviceDidReceiveMessage(let message):
            self.appendMessage(message)
            break
        case .serviceDidSendMessage(let message):
            self.setInterfaceSending(false)
            self.appendMessage(message)
            break
        }
    }

}
