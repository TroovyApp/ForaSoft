//
//  CoursesEmptyView.swift
//  troovy-ios
//
//  Created by forasoft on 10/08/2018.
//  Copyright © 2018 ForaSoft. All rights reserved.
//

import UIKit

class CoursesEmptyView: UIView {

    @IBOutlet var bgImage: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var leftButton: UIButton!
    @IBOutlet var rightButton: UIButton!
    
    public var leftButtonHandler: (()->Void)?
    public var rightButtonHandler: (()->Void)?

    @IBAction func buttonPressed(_ sender: UIButton) {
        if sender === leftButton {
            leftButtonHandler?()
        } else {
            rightButtonHandler?()
        }
    }
    
    public func configure(withCourseListType courseListType: CourseListProperties.CourseListType) {
        switch courseListType {
        case .subscribed:
            bgImage.image = UIImage(named: "empty_tab_1")
            titleLabel.text = ApplicationMessages.Instructions.subscribedCoursesEmptyMessage
            rightButton.setTitle("EXPLORE", for: .normal)
        case .all:
            bgImage.image = UIImage(named: "empty_tab_1")
            titleLabel.text = ApplicationMessages.Instructions.allCoursesEmptyMessage
            rightButton.setTitle("CREATE", for: .normal)
        case .own:
            bgImage.image = UIImage(named: "empty_tab_2")
            titleLabel.text = ApplicationMessages.Instructions.ownCoursesEmptyMessage
            rightButton.setTitle("CREATE", for: .normal)
        default:
            break
        }
        
    }
}
