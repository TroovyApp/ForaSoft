//
//  SessionAttachmentTableViewCell.swift
//  troovy-ios
//
//  Created by Daniil on 21.11.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class SessionAttachmentTableViewCell: UITableViewCell {
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var separatorView: UIView!
    
    // MARK: Init Methods & Superclass Overriders

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    // MARK: Public Methods
    
    /// Configures cell with passed properties.
    ///
    /// - parameter name: Cell name to show.
    /// - parameter showSeparator: True is separator should be visible. False otherwise.
    ///
    func configure(withName name: String, showSeparator: Bool) {
        self.nameLabel.text = name
        self.separatorView.isHidden = !showSeparator
    }

}
