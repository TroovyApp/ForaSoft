//
//  CourseCollectionViewCell.swift
//  troovy-ios
//
//  Created by Daniil on 30.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

import Kingfisher

class CourseCollectionViewCell: UICollectionViewCell, CourseModelDelegate {
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var containerView: UIView?
    @IBOutlet weak var courseImageView: UIImageView?
    @IBOutlet weak var courseTitleLabel: UILabel?
    @IBOutlet weak var courseDescriptionLabel: UILabel?
    @IBOutlet weak var coursePriceView: UIView?
    @IBOutlet weak var coursePriceLabel: UILabel?
    @IBOutlet weak var courseAuthorLabel: UILabel?
    
    // MARK: Private Properties
    
    private var serverAddress: String?
    private var numberFormatter: NumberFormatter?
    
    private var courseModel: CourseModel? {
        willSet {
            self.courseModel?.removeDelegate(self)
        }
        didSet {
            self.courseModel?.delegate = self
        }
    }
    
    // MARK: Init Methods & Superclass Overriders
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    // MARK: Public Methods
    
    /// Configures cell with passed properties.
    ///
    /// - parameter course: Course model.
    /// - parameter serverAddress: Server address.
    /// - parameter numberFormatter: Price number formatter.
    ///
    func configure(withCourse course: CourseModel, serverAddress: String, numberFormatter: NumberFormatter) {
        self.courseModel = course
        self.serverAddress = serverAddress
        self.numberFormatter = numberFormatter
        
        self.applyPreviewImage(withCourse: course, serverAddress: serverAddress)
        self.courseTitleLabel?.text = course.title
        self.courseDescriptionLabel?.text = course.specification
        self.courseAuthorLabel?.text = course.creatorName.uppercased()

        if let priceTier = course.priceTier, let price = TroovyProducts.shared.priceForProductIdentifier(priceTier) {
            self.coursePriceView?.isHidden = false
            self.coursePriceLabel?.text = numberFormatter.string(from: price)
        } else {
            self.coursePriceView?.isHidden = true
            self.coursePriceLabel?.text = nil
        }
//        if let price = course.price {
//            self.coursePriceView?.isHidden = false
//            self.coursePriceLabel?.text = numberFormatter.string(from: price)
//        } else {
//            self.coursePriceView?.isHidden = true
//            self.coursePriceLabel?.text = nil
//        }
    }
    
    // MARK: Private Methods
    
    private func applyPreviewImage(withCourse course: CourseModel, serverAddress: String) {
        var imageResourse: ImageResource?
        if let previewImageURL = course.previewImageURL, let imageURL = URL.address(byAppendingServerAddress: serverAddress, toContentPath: previewImageURL) {
            imageResourse = ImageResource(downloadURL: imageURL)
        }
        
        if let resourse = imageResourse {
            self.courseImageView?.kf.indicatorType = .activity
            self.courseImageView?.kf.setImage(with: resourse)
        } else {
            self.courseImageView?.kf.cancelDownloadTask()
            self.courseImageView?.image = UIImage.courseCellPlaceholder()
        }
    }
    
    // MARK: Protocols Implementation
    
    // MARK: CourseModelDelegate
    
    internal func courseChagned(course: CourseModel) {
        if let serverAddress = self.serverAddress, let courseID = self.courseModel?.id, let numberFormatter = self.numberFormatter {
            if course.id == courseID {
                self.configure(withCourse: course, serverAddress: serverAddress, numberFormatter: numberFormatter)
            }
        }
    }
    
}
