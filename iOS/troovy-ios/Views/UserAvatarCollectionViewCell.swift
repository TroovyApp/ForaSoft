//
//  UserAvatarCollectionViewCell.swift
//  troovy-ios
//
//  Created by Daniil on 20.10.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

import Kingfisher

class UserAvatarCollectionViewCell: UICollectionViewCell {
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var imageView: UIImageView!
    
    // MARK: Public Methods
    
    /// Configures cell with passed properties.
    ///
    /// - parameter user: User model.
    /// - parameter serverAddress: Server address.
    ///
    func configure(withUser user: UserModel, serverAddress: String) {
        if let avatarURL = user.profilePictureURL, let imageURL = URL.address(byAppendingServerAddress: serverAddress, toContentPath: avatarURL) {
            let imageResourse = ImageResource(downloadURL: imageURL)
            self.imageView.kf.indicatorType = .activity
            (self.imageView.kf.indicator?.view as? UIActivityIndicatorView)?.color = .white
            self.imageView.kf.setImage(with: imageResourse)
        } else {
            self.imageView.kf.cancelDownloadTask()
            self.imageView.image = nil
        }
    }
    
}
