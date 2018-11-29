//
//  ProfileBalanceTableViewCell.swift
//  troovy-ios
//
//  Created by Daniil on 16.11.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class ProfileBalanceTableViewCell: UITableViewCell {

    // MARK: Interface Builder Properties
    
    @IBOutlet weak var balanceLabel: UILabel!
    
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
    /// - parameter balance: User wallet balance.
    ///
    func configure(withBalanceString balance: String?) {
        self.balanceLabel.text = balance
    }

}
