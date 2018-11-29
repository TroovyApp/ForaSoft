//
//  CourseAttachmentCollectionViewCell.swift
//  troovy-ios
//
//  Created by Daniil on 22.09.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

import Kingfisher

class CourseAttachmentCollectionViewCell: UICollectionViewCell {
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var attachmentImageView: UIImageView!
    
    // MARK: Public Methods
    
    /// Configures cell with passed properties.
    ///
    /// - parameter attachment: Attachment model.
    /// - parameter serverAddress: Server address.
    ///
    func configure(withAttachment attachment: CourseAttachmentModel, serverAddress: String) {
        if let previewImageURL = attachment.thumbnailAddress, let imageURL = URL.address(byAppendingServerAddress: serverAddress, toContentPath: previewImageURL) {
            let imageResource = ImageResource(downloadURL: imageURL)
            self.attachmentImageView.kf.indicatorType = .activity
            self.attachmentImageView.kf.setImage(with: imageResource)
        } else {
            self.attachmentImageView.kf.cancelDownloadTask()
            self.attachmentImageView.image = nil
        }
    }
    
}
