//
//  CreateCourseHintsViewController.swift
//  troovy-ios
//
//  Created by Daniil on 05.12.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class CreateCourseHintsViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    // MARK: Interface Builder Properties
    
    @IBOutlet weak var collectionView: UICollectionView?
    @IBOutlet weak var pageControl: UIPageControl?
    
    // MARK: Public Properties
    
    var hints: [String] = []
    
    // MARK: Init Methods & Superclass Overriders
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupCollectionView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: Public Methods
    
    /// Selects hint.
    ///
    /// - parameter index: Hit index to select.
    /// - parameter animated: True if changes should be animated. False otherwise.
    ///
    func selectHit(atIndex index: Int, animated: Bool) {
        guard let collectionView = self.collectionView, let pageControl = self.pageControl else {
            return
        }
        
        if index < self.hints.count {
            let itemWidth = collectionView.frame.size.width
            let offset = CGPoint(x: (CGFloat(index) * itemWidth), y: 0.0)
            if offset.x != collectionView.contentOffset.x {
                collectionView.setContentOffset(offset, animated: animated)
            }
        }
        
        if pageControl.numberOfPages > index && pageControl.currentPage != index {
            pageControl.currentPage = index
        }
    }
    
    // MARK: Private Methods
    
    private func setupCollectionView() {
        self.pageControl?.numberOfPages = self.hints.count
        
        if #available(iOS 11.0, *) {
            self.collectionView?.contentInsetAdjustmentBehavior = .never
        }
    }
    
    // MARK: Controls Actions
    
    @IBAction func pageControlAction(_ sender: UIPageControl) {
        let index = sender.currentPage
        self.selectHit(atIndex: index, animated: true)
    }
    
    // MARK: Protocols Implementation
    
    // MARK: UIScrollViewDelegate
    
    internal func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let pageControl = self.pageControl else {
            return
        }
        
        let itemWidth = scrollView.frame.size.width
        let pageIndex = Int(scrollView.contentOffset.x / itemWidth)
        
        if pageControl.numberOfPages > pageIndex && pageControl.currentPage != pageIndex {
            pageControl.currentPage = pageIndex
        }
    }
    
    // MARK: UICollectionViewDelegate && UICollectionViewDataSource
    
    internal func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.hints.count
    }
    
    internal func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HintCollectionViewCell", for: indexPath) as! HintCollectionViewCell
        return cell
    }
    
    internal func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let hintCell = cell as? HintCollectionViewCell {
            let index = indexPath.row
            let hint = self.hints[index]
            
            hintCell.configure(withHintText: hint)
        }
    }
    
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.size.width
        let height = collectionView.frame.size.height
        
        return CGSize(width: width, height: height)
    }

}
