//
//  CourseAttachmentsCollectionViewCell.swift
//  troovy-ios
//
//  Created by Daniil on 25.10.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

protocol CourseAttachmentsCellDelegate: class {
    func courseAttachmentsButtonClicked(_ cell: CourseAttachmentsCollectionViewCell)
}

class CourseAttachmentsCollectionViewCell: CourseInfoCollectionViewCell {
    
    // MARK: Interafce Builder Properties
    
    @IBOutlet weak var attachmentsButton: UIButton!
    
    // MARK: Private Properties
    
    private weak var delegate: CourseAttachmentsCellDelegate?
    
    // MARK: Public Methods
    
    /// Configures cell with data.
    ///
    /// - parameter title: Attachments button title.
    /// - parameter delegate: Delegate. Responds to CourseAttachmentsCellDelegate protocol.
    ///
    func configure(withTitle title: String, delegate: CourseAttachmentsCellDelegate?) {
        self.attachmentsButton.setTitle(title, for: .normal)
        self.delegate = delegate
    }
    
    // MARK: Controls Actions
    
    @IBAction func attachmentsButtonAction(_ sender: UIButton) {
        self.delegate?.courseAttachmentsButtonClicked(self)
    }
    
}
