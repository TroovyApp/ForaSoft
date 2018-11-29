//
//  StreamChatMessageTableViewCell.swift
//  troovy-ios
//
//  Created by Daniil on 13.11.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

import Kingfisher

class StreamChatMessageTableViewCell: UITableViewCell {
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    
    // MARK: Init Methods & Superclass Overriders

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    // MARK: Public Methods
    
    /// Configures cell with parameters.
    ///
    /// - parameter username: Message author username.
    /// - parameter message: Message text.
    ///
    func configure(withUsername username: String, message: String, serverAddress: String, avatarImageURL: String?, isStreamer: Bool, isCurrentUser: Bool) {
        if isCurrentUser {
            self.usernameLabel.text = "You"
            self.usernameLabel.textColor = UIColor.tv_purpleTextColor()
        } else {
            self.usernameLabel.text = username
            
            if isStreamer {
                self.usernameLabel.textColor = UIColor.tv_redTextColor()
            } else {
                self.usernameLabel.textColor = UIColor.white.withAlphaComponent(0.6)
            }
        }
        
        self.messageLabel.text = message
        
        if let profileImageURL = avatarImageURL, let imageURL = URL.address(byAppendingServerAddress: serverAddress, toContentPath: profileImageURL) {
            let resourse = ImageResource(downloadURL: imageURL)
            self.profileImageView.kf.indicatorType = .activity
            (self.profileImageView.kf.indicator?.view as? UIActivityIndicatorView)?.color = .white
            self.profileImageView.kf.setImage(with: resourse)
        } else {
            self.profileImageView.kf.cancelDownloadTask()
            self.profileImageView.image = UIImage.tv_profilePlaceholder()
        }
    }

}
