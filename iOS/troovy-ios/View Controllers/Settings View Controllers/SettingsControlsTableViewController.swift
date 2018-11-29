//
//  SettingsControlsTableViewController.swift
//  troovy-ios
//
//  Created by Daniil on 24.11.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

protocol SettingsControlsDelegate: class {
    func settingsControlsShouldLogout(_ controls: SettingsControlsTableViewController)
}

class SettingsControlsTableViewController: UITableViewController {
    
    // MARK: Public Properties
    
    /// Delegate. Responds to SettingsControlsDelegate.
    weak var delegate: SettingsControlsDelegate?

    // MARK: Init Methods & Superclass Overriders
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: Protocols Implementation
    
    // MARK: UITableViewDelegate & UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row == 0 {
            self.delegate?.settingsControlsShouldLogout(self)
        }
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

}
