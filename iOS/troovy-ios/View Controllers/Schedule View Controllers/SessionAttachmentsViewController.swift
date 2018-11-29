//
//  SessionAttachmentsViewController.swift
//  troovy-ios
//
//  Created by Daniil on 09.11.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class SessionAttachmentsViewController: TroovyViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: Public Properties
    
    /// Model of the unauthorised user.
    var authorisedUserModel: AuthorisedUserModel!
    
    /// Course session.
    var sessionModel: CourseSessionModel!
    
    // MARK: Properties Overriders
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: Private Properties
    
    private let infoPlistService = InfoPlistService()
    private var coursesService: CoursesService!
    
    private var attachments: [CourseAttachmentModel] = []
    
    private var numberFormatter: NumberFormatter!
    
    private var firstLaunch = true
    private var loadingAttachments = false
    
    private var loadSessionAttachmentsMethod: String?
    
    // MARK: Init Methods & Superclass Overriders

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.attachments = self.sessionModel.attachments
        
        self.setupNumberFormatter()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.firstLaunch {
            self.firstLaunch = false
            self.checkAttachmentsLoaded()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func inject(propertiesWithAssembly assembly: ViewControllerAssemblyManager) {
        self.coursesService = assembly.coursesService
    }
    
    override func configureServices() {
        self.coursesService.delegate = self
    }
    
    override func serviceMethodSucceeded(withMethod method: String, resultDictionary: [String : Any]?, resultArray: [[String : Any]]?, resultString: String?) {
        if method == self.loadSessionAttachmentsMethod {
            var attachments: [CourseAttachmentModel] = []
            if let attachmentsInfo = resultArray {
                for info in attachmentsInfo {
                    let attachment = CourseAttachmentModel(withDictionary: info)
                    attachments.append(attachment)
                }
            }
            
            self.sessionModel.update(withAttachments: attachments)
            
            self.loadingAttachments = false
            self.apply(serverAttachments: attachments)
        }
    }
    
    override func serviceMethodFailed(withMethod method: String) {
        if method == self.loadSessionAttachmentsMethod {
            self.loadingAttachments = false
            self.apply(serverAttachments: [])
        }
    }
    
    override func showLoadingView(withMethod method: String) {
        if method == self.loadSessionAttachmentsMethod {
            let isAnimating = self.activityIndicator?.isAnimating ?? false
            if !isAnimating {
                self.activityIndicator?.startAnimating()
            }
            
            self.tableView.isHidden = true
            self.emptyView.isHidden = true
        }
    }
    
    override func hideLoadingView(withMethod method: String) {
        if method == self.loadSessionAttachmentsMethod {
            self.tableView.isHidden = (self.attachments.count == 0)
            self.emptyView.isHidden = (self.attachments.count != 0 || self.loadingAttachments)
            
            let isAnimating = self.activityIndicator?.isAnimating ?? false
            if isAnimating {
                self.activityIndicator?.stopAnimating()
            }
        }
    }
    
    // MARK: Private Methods
    
    private func setupNumberFormatter() {
        self.numberFormatter = NumberFormatter()
        self.numberFormatter.numberStyle = .none
    }
    
    private func checkAttachmentsLoaded() {
        self.apply(serverAttachments: self.attachments)
        
        if self.attachments.count > 0 {
            let isAnimating = self.activityIndicator?.isAnimating ?? false
            if isAnimating {
                self.activityIndicator?.stopAnimating()
            }
        } else {
            self.loadAttachments()
        }
    }
    
    private func apply(serverAttachments: [CourseAttachmentModel]?) {
        var attachmentsChanged = false
        if let attachments = serverAttachments {
            self.attachments = attachments
            attachmentsChanged = true
        }
        
        self.tableView.isHidden = (self.attachments.count == 0)
        self.emptyView.isHidden = (self.attachments.count != 0 || self.loadingAttachments)
        
        if attachmentsChanged {
            self.tableView.reloadData()
        }
    }
    
    private func loadAttachments() {
        if self.loadingAttachments {
            return
        }
        
        guard let sessionID = self.sessionModel.id else {
            return
        }
        
        self.loadingAttachments = true
        self.loadSessionAttachmentsMethod = self.coursesService.loadSessionAttachments(withSessionID: sessionID, user: self.authorisedUserModel)
    }
    
    // MARK: Controls Actions
    
    @IBAction func reloadButtonAction( _ sender: UIButton) {
        self.loadAttachments()
    }
    
    // MARK: Protocols Implementation
    
    // MARK: UITableViewDelegate & UITableViewDataSource
    
    internal func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    internal func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.attachments.count
    }
    
    internal func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let orderString = self.numberFormatter.string(from: NSNumber(value: indexPath.row + 1)) ?? "\(indexPath.row + 1)"
        let name = "Video " + orderString
        let showSeparator = ((indexPath.row + 1) < self.attachments.count)
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "SessionAttachmentTableViewCell") as! SessionAttachmentTableViewCell
        cell.configure(withName: name, showSeparator: showSeparator)
        return cell
    }
    
    internal func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let attachment = self.attachments[indexPath.row]
        self.router.showSessionAttachmentViewController(withAuthorisedUserModel: self.authorisedUserModel, attachmentModel: attachment)
    }
    
    internal func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 49.0
    }
    
    internal func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    internal func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

}
