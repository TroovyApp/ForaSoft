//
//  CourseVideoPreviewTableViewCell.swift
//  troovy-ios
//
//  Created by Daniil on 18.09.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

import Kingfisher

class CourseVideoPreviewTableViewCell: CourseImagePreviewTableViewCell {

    // MARK: Interface Builder Properties
    
    @IBOutlet weak var videoButton: UIButton!
    
    // MARK: Init Methods & Superclass Overriders
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    // MARK: Controls Actions
    
    @IBAction func videoButtonAction(_ sender: UIButton) {
        self.delegate?.coursePreviewCellShouldPlayVideo(cell: self)
    }

}
