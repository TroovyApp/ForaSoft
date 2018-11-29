//
//  FinishedStreamViewController.swift
//  troovy-ios
//
//  Created by Daniil on 20.10.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class FinishedStreamViewController: TroovyViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var instructionLabel: UILabel?
    @IBOutlet weak var durationValueLabel: UILabel?
    @IBOutlet weak var durationLabel: UILabel?
    @IBOutlet weak var viewersValueLabel: UILabel?
    @IBOutlet weak var viewersLabel: UILabel?
    @IBOutlet weak var collectionView: UICollectionView?
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView?
    
    // MARK: Public Properties
    
    /// Determines if user owns this session.
    var isSessionOwner = false
    
    /// Model of the stream info.
    var streamInfoModel: StreamInfoModel!
    
    /// Model of the unauthorised user.
    var authorisedUserModel: AuthorisedUserModel!
    
    // MARK: Properties Overriders
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: Private Properties
    
    private let infoPlistService = InfoPlistService()
    private var videoStreamService: VideoStreamService!
    
    private var users: [UserModel] = []
    
    private var loadUsersMethod: String?
    
    // MARK: Init Methods & Superclass Overriders

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadUsers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.structFinishedView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    override func inject(propertiesWithAssembly assembly: ViewControllerAssemblyManager) {
        self.videoStreamService = assembly.videoStreamService
    }
    
    override func configureServices() {
        self.videoStreamService.delegate = self
    }
    
    override func serviceMethodSucceeded(withMethod method: String, resultDictionary: [String : Any]?, resultArray: [[String : Any]]?, resultString: String?) {
        if method == self.loadUsersMethod {
            if let usersDictionaries = resultArray {
                var users: [UserModel] = []
                for dictionary in usersDictionaries {
                    let user = UserModel(withDictionary: dictionary)
                    users.append(user)
                }
                
                self.applyUsers(users)
            }
        }
    }
    
    override func shouldShowAlert(forMethod method: String) -> Bool {
        if method == self.loadUsersMethod {
            return false
        }
        
        return super.shouldShowAlert(forMethod: method)
    }
    
    override func serviceMethodFailed(withMethod method: String) {
        if method == self.loadUsersMethod {
            self.loadUsers()
        }
    }
    
    override func showLoadingView(withMethod method: String) {
        if method == self.loadUsersMethod {
            return
        }
    }
    
    // MARK: Private Methods
    
    private func structFinishedView() {
        if self.isSessionOwner {
            self.instructionLabel?.text = ApplicationMessages.Instructions.ownerSessionFinished
        } else {
            self.instructionLabel?.text = ApplicationMessages.Instructions.viewerSessionFinished
        }
        
        self.durationValueLabel?.text = "\(self.streamInfoModel.duration!)"
        self.durationLabel?.text = (self.streamInfoModel.duration == 1 ? "minute" : "minutes")
        
        self.viewersValueLabel?.text = "\(self.streamInfoModel.usersIdentifiers.count)"
        self.viewersLabel?.text = (self.streamInfoModel.usersIdentifiers.count == 1 ? "viewer" : "viewers")
    }
    
    private func loadUsers() {
        self.collectionView?.isHidden = true
        self.activityIndicator?.startAnimating()
        
//        self.loadUsersMethod = self.videoStreamService.loadUsers(withUsersIdentifiers: self.streamInfoModel.usersIdentifiers, user: self.authorisedUserModel)
    }
    
    private func applyUsers(_ users: [UserModel]) {
        self.users = users
        self.collectionView?.reloadData()
        
        self.activityIndicator?.stopAnimating()
        self.collectionView?.isHidden = false
    }
    
    // MARK: Protocols Implementation
    
    // MARK: UICollectionViewDelegate && UICollectionViewDataSource
    
    internal func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UserAvatarCollectionViewCell", for: indexPath) as! UserAvatarCollectionViewCell
        return cell
    }
    
    internal func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let userCell = cell as? UserAvatarCollectionViewCell {
            let index = indexPath.row
            let user = self.users[index]
            
            userCell.configure(withUser: user, serverAddress: self.infoPlistService.serverURL())
        }
    }
    
    internal func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.users.count
    }
    
    internal func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        let index = indexPath.row
//        let user = self.users[index]
    }
    
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.height
        let height = collectionView.bounds.height
        
        return CGSize(width: width, height: height)
    }
    
    internal func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) {
            cell.alpha = 0.66
            cell.contentView.alpha = 0.66
        }
    }
    
    internal func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) {
            cell.alpha = 1.0
            cell.contentView.alpha = 1.0
        }
    }

}
