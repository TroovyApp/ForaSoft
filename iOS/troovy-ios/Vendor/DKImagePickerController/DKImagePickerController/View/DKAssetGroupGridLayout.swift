//
//  DKAssetGroupGridLayout.swift
//  DKImagePickerControllerDemo
//
//  Created by ZhangAo on 16/1/17.
//  Copyright © 2016年 ZhangAo. All rights reserved.
//

import UIKit

open class DKAssetGroupGridLayout: UICollectionViewFlowLayout {
	
	open override func prepare() {
		super.prepare()
		
		let interval: CGFloat = 5
		self.minimumInteritemSpacing = interval
		self.minimumLineSpacing = interval
        self.sectionInset = UIEdgeInsetsMake(6.0, 11.0, 6.0, 11.0)
		
		let contentWidth = self.collectionView!.bounds.width
		
		let itemCount = 3
		let itemWidth = round((contentWidth - self.sectionInset.left - self.sectionInset.right - interval * (CGFloat(itemCount) - 1)) / CGFloat(itemCount))
        let itemHeight = round(itemWidth * 1.32456)
		
		let itemSize = CGSize(width: itemWidth, height: itemHeight)
		self.itemSize = itemSize
	}
    
}
