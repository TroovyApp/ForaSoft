//
//  OrderCollectionViewFlowLayout.swift
//  troovy-ios
//
//  Created by Daniil on 14.12.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class OrderCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
    override init() {
        super.init()
        
        self.minimumLineSpacing = 0.0
        self.minimumInteritemSpacing = 0.0
        self.sectionInset = UIEdgeInsetsMake(16.0, 0.0, 0.0, 0.0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.minimumLineSpacing = 0.0
        self.minimumInteritemSpacing = 0.0
        self.sectionInset = UIEdgeInsetsMake(16.0, 0.0, 0.0, 0.0)
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributes = super.layoutAttributesForElements(in: rect)
        for attribute in attributes ?? [] {
            if attribute.representedElementCategory == .cell {
                attribute.zIndex = Int.max - attribute.indexPath.row
            }
        }
        return attributes
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attribute = super.layoutAttributesForItem(at: indexPath)
        if attribute?.representedElementCategory == .cell {
            attribute?.zIndex = Int.max - indexPath.row
        }
        return attribute
    }
    
}
