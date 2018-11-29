//
//  CreateSessionTableViewCell.swift
//  troovy-ios
//
//  Created by Daniil on 28.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class CreateSessionTableViewCell: UITableViewCell {
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var plusImageView: UIImageView!
    @IBOutlet weak var createLabel: UILabel!
    
    // MARK: Init Methods & Superclass Overriders

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
