//
//  NLSegmentControl.swift
//  NLSegmentControl
//
//  Created by songhailiang on 24/05/2017.
//  Copyright © 2017 hailiang.song. All rights reserved.
//

import UIKit

public class NLSegmentControl: UIView {
    
    public enum SegmentWidthStyle {
        case fixed
        case dynamic
        case equal(width: CGFloat)
    }
    
    public enum SelectionIndicatorStyle {
        case textWidthStripe //indicator width = text width
        case fullWidthStripe //indicator width = segment width
        case box
    }
    
    public enum SelectionIndicatorPosition {
        case top
        case bottom
        case none
    }
    
    public enum SegmentImagePosition {
        case top
        case left
        case bottom
        case right
    }
    
// MARK: - Public Properties
    
    public var segments: [NLSegmentDataSource]
    public var indexChangedHandler: ((_ index: Int) -> (Void))?
    public var segmentTitleFormatter: ((_ item: NLSegmentDataSource, _ selected: Bool) -> NSAttributedString?)?
    public var configSegmentCell: ((_ cell: NLSegmentCell) -> Void)?
    
    /// Style of the segment's width, default is .fixed
    public var segmentWidthStyle: SegmentWidthStyle = .fixed
    
    /// Edges inset edges of segments, default is 0 5 0 5
    public var segmentEdgeInset: UIEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
    
    /// Style of the selection indicator, default is .fullWidthStripe
    public var selectionIndicatorStyle: SelectionIndicatorStyle = .fullWidthStripe
    
    /// Height of the selection indicator, default is 5.0
    public var selectionIndicatorHeight: CGFloat = 5.0
    
    /// Edge insets of the selection indicator. When selection indicator is .top, bottom edge insets are not used, when .bottom, top edge insets are not used. Default is .zero
    public var selectionIndicatorEdgeInset: UIEdgeInsets = .zero
    
    /// Color of the selection indicator, default is .black
    public var selectionIndicatorColor: UIColor = .black {
        didSet {
            self.selectionIndicator.backgroundColor = selectionIndicatorColor
        }
    }
    
    /// Position of the selection indicator, default is .bottom
    public var selectionIndicatorPosition: SelectionIndicatorPosition = .bottom {
        didSet {
            if self.superview == nil {
                return
            }
            if let layout = indicatorPositionConstraint {
                layout.isActive = false
            }
            switch selectionIndicatorPosition {
            case .top:
                indicatorPositionConstraint = selectionIndicator.nl_equalTop(toView: self)
            case .bottom:
                indicatorPositionConstraint = selectionIndicator.nl_equalBottom(toView: self)
            case .none:
                break
            }
        }
    }
    
    /// Color of selection box, default is .clear
    public var selectionBoxColor: UIColor = .clear {
        didSet {
            selectionBox.backgroundColor = selectionBoxColor
        }
    }
    
    /// Text attributes to apply to labels of the unselected segments
    public var titleTextAttributes: [NSAttributedStringKey: AnyObject] = [
        NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14),
        NSAttributedStringKey.foregroundColor: UIColor.black
        ]
    
    /// Text attributes to apply to labels of the selected segments
    public var selectedTitleTextAttributes: [NSAttributedStringKey:AnyObject] = [
        NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14),
        NSAttributedStringKey.foregroundColor: UIColor.black
        ]
    
    /// Vertical divider between the segments. Default is false
    public var enableVerticalDivider: Bool = false
    /// Color of vertical divider. Default is .gray
    public var verticalDividerColor: UIColor = .gray
    /// Width of vertical divider. Default is 1.0f
    public var verticalDividerWidth: CGFloat = 1.0
    /// Inset top and bottom of vertical divider. Default is 15.0
    public var verticalDividerInset: CGFloat = 15.0
    /// image position relative to text, default is .left
    public var imagePosition: SegmentImagePosition = .left
    /// space between image and title, default is 8.0
    public var imageTitleSpace: CGFloat = 8.0
    
    /// current selected index
    public fileprivate(set) var selectedSegmentIndex: Int = 0
    
    /// current selected segment
    public var selectedSegment: NLSegmentDataSource? {
        return segments.item(at: selectedSegmentIndex)
    }
    
    // MARK: - Private Properties
    
    //Contraints
    fileprivate var indicatorHeightConstraint: NSLayoutConstraint?
    fileprivate var indicatorLeadingConstraint: NSLayoutConstraint?
    fileprivate var indicatorWidthConstraint: NSLayoutConstraint?
    fileprivate var indicatorPositionConstraint: NSLayoutConstraint?
    fileprivate var boxLeadingConstraint: NSLayoutConstraint?
    fileprivate var boxWidthConstraint: NSLayoutConstraint?
    
    fileprivate var segmentWidth: CGFloat = 0
    fileprivate var segmentWidths: [CGFloat] = []
    
    fileprivate lazy var segmentCollection: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets.zero
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.dataSource = self
        collection.delegate = self
        collection.scrollsToTop = false
        collection.backgroundColor = .clear
        collection.showsVerticalScrollIndicator = false
        collection.showsHorizontalScrollIndicator = false
        
        collection.register(NLSegmentCell.self, forCellWithReuseIdentifier: "Cell")
        
        return collection
    }()
    
    fileprivate lazy var selectionIndicator: UIView = {
        let selectionIndicator = UIView()
        selectionIndicator.backgroundColor = self.selectionIndicatorColor
        selectionIndicator.translatesAutoresizingMaskIntoConstraints = false
        return selectionIndicator
    }()
    
    fileprivate lazy var selectionBox: UIView = {
        let box = UIView()
        box.backgroundColor = self.selectionBoxColor
        box.translatesAutoresizingMaskIntoConstraints = false
        return box
    }()
    
    // MARK: - Life Circle
    public init() {
        self.segments = []
        super.init(frame: .zero)
    }
    
    public override init(frame: CGRect) {
        self.segments = []
        super.init(frame: frame)
    }
    
    public init(segments: [NLSegmentDataSource]) {
        self.segments = segments
        super.init(frame: .zero)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        self.segments = []
        super.init(coder: aDecoder)
    }
    
    public override func willMove(toSuperview newSuperview: UIView?) {
        addSubview(selectionBox)
        addSubview(segmentCollection)
        addSubview(selectionIndicator)
        bringSubview(toFront: selectionIndicator)
    }
    
    public override func updateConstraints() {
        
        calcSegmentWidth()
        
        //collection view
        segmentCollection.nl_equalWidth(toView: self)
        segmentCollection.nl_equalHeight(toView: self)
        segmentCollection.nl_equalCenterX(toView: self)
        segmentCollection.nl_equalCenterY(toView: self)
        
        //selection box
        boxLeadingConstraint = selectionBox.nl_equalLeft(toView: self)
        boxWidthConstraint = selectionBox.nl_widthIs(0)
        selectionBox.nl_equalTop(toView: self)
        selectionBox.nl_equalBottom(toView: self)
        
        //selection indicator
        if selectionIndicatorPosition != .none {
            indicatorHeightConstraint = selectionIndicator.nl_heightIs(selectionIndicatorHeight)
            indicatorLeadingConstraint = selectionIndicator.nl_equalLeft(toView: self)
            indicatorWidthConstraint = selectionIndicator.nl_widthIs(0)
            switch selectionIndicatorPosition {
            case .top:
                indicatorPositionConstraint = selectionIndicator.nl_equalTop(toView: self)
            case .bottom:
                indicatorPositionConstraint = selectionIndicator.nl_equalBottom(toView: self)
            default:
                break
            }
        }
        updateSelectionIndicator()
        
        super.updateConstraints()
    }
}

// MARK: - Public Methods
public extension NLSegmentControl {
    /**
     Changes the currently selected segment index.
     
     - parameter index: Index of the segment to select.
     - parameter animated: A boolean to specify whether the change should be animated or not
     */
    public func setSelectedSegmentIndex(_ index: Int, animated: Bool) {
        guard index < itemsCount else {
            return
        }
        
        selectedSegmentIndex = index
        
        scrollToSelectedSegmentIndex(animated: animated)
        updateSelectionIndicator()
        
        if animated {
            UIView.animate(withDuration: 0.25, animations: {
                self.layoutIfNeeded()
            })
        } else {
            self.layoutIfNeeded()
        }
    }
    
    public func reloadSegments() {
        layoutIfNeeded()
        calcSegmentWidth()
        segmentCollection.reloadData()
        if selectedSegmentIndex < itemsCount {
            scrollToSelectedSegmentIndex(animated: false)
        }
        
        updateSelectionIndicator()
    }
}

// MARK: - Private Methods
extension NLSegmentControl {

    fileprivate var itemsCount: Int {
        return segments.count
    }
    
    //calculate all segments width
    fileprivate func calcSegmentWidth() {
        
        if bounds.equalTo(.zero) {
            return
        }
        
        if itemsCount > 0 {
            segmentWidth = bounds.width / CGFloat(itemsCount)
        }
        
        switch segmentWidthStyle {
        case .fixed:
            //
            for i in 0 ..< itemsCount {
                let width = widthOfContentAt(index: i)
                segmentWidth = max(width + segmentEdgeInset.left + segmentEdgeInset.right, segmentWidth)
            }
        case .dynamic:
            segmentWidths.removeAll()
            for i in 0 ..< itemsCount {
                let width = widthOfContentAt(index: i)
                segmentWidths.append(width + segmentEdgeInset.left + segmentEdgeInset.right)
            }
        case .equal(let width):
            segmentWidth = width
        }
    }
    
    //width of the segment
    fileprivate func widthOfSegmentAt(index: Int) -> CGFloat {
        switch segmentWidthStyle {
        case .fixed, .equal(_):
            return segmentWidth
        case .dynamic:
            if index >= segmentWidths.count {
                return 0
            }
            return segmentWidths[index]
        }
    }
    
    //width of the segment content(ignore segment edge inset)
    fileprivate func widthOfContentAt(index: Int) -> CGFloat {
        guard index < itemsCount else {
            return 0
        }
        var textWidth: CGFloat = 0
        var imageWidth: CGFloat = 0
        //calc width of selected and normal, use the wider one
        if let text = attributedTitleAtIndex(index, selected: false) {
            textWidth = ceil(text.size().width)
        }
        if let text = attributedTitleAtIndex(index, selected: true) {
            textWidth = max(textWidth, ceil(text.size().width))
        }
        if let image = segments.item(at: index)?.segmentImage {
            imageWidth = image.size.width
        }
        
        //both text and image
        if textWidth > 0 && imageWidth > 0 {
            switch imagePosition {
            case .left, .right:
                return textWidth + imageWidth + imageTitleSpace
            case .top, .bottom:
                return max(textWidth, imageWidth)
            }
        }
        
        return max(textWidth, imageWidth)
    }
    
    fileprivate func updateSelectionIndicator() {
        
        selectionIndicator.isHidden = false
        
        var offsetX: CGFloat = 0.0
        for i in 0 ..< selectedSegmentIndex {
            offsetX = offsetX + widthOfSegmentAt(index: i)
        }
        
        let selectedSegmentWidth = widthOfSegmentAt(index: selectedSegmentIndex)
        let edgeInset = selectionIndicatorEdgeInset.left + selectionIndicatorEdgeInset.right
        if selectionIndicatorStyle != .box {
            offsetX += selectionIndicatorEdgeInset.left
        }
        
        switch selectionIndicatorStyle {
        case .fullWidthStripe:
            indicatorWidthConstraint?.constant = selectedSegmentWidth - edgeInset
        case .textWidthStripe:
            let selectedContentWidth = widthOfContentAt(index: selectedSegmentIndex)
            if selectedContentWidth < selectedSegmentWidth {
                indicatorWidthConstraint?.constant = selectedContentWidth - edgeInset
                offsetX = offsetX + segmentEdgeInset.left + (selectedSegmentWidth / 2.0 - selectedContentWidth / 2.0)
            } else {
                indicatorWidthConstraint?.constant = selectedContentWidth - edgeInset
                offsetX = offsetX + segmentEdgeInset.left
            }
        case .box:
            indicatorWidthConstraint?.constant = selectedSegmentWidth
            boxWidthConstraint?.constant = selectedSegmentWidth
        }
        
        indicatorLeadingConstraint?.constant = offsetX - segmentCollection.contentOffset.x
        indicatorHeightConstraint?.constant = selectionIndicatorHeight
        boxLeadingConstraint?.constant = offsetX - segmentCollection.contentOffset.x
        
        switch selectionIndicatorPosition {
        case .top:
            indicatorPositionConstraint?.constant = selectionIndicatorEdgeInset.top
        case .bottom:
            indicatorPositionConstraint?.constant = selectionIndicatorEdgeInset.bottom
        case .none:
            selectionIndicator.isHidden = true
        }
    }
    
    fileprivate func scrollToSelectedSegmentIndex(animated: Bool) {
        segmentCollection.selectItem(at: IndexPath(item: selectedSegmentIndex, section: 0), animated: animated, scrollPosition: .centeredHorizontally)
    }
    
    fileprivate func attributedTitleAtIndex(_ index: Int, selected: Bool) -> NSAttributedString? {
        guard let segment = segments.item(at: index),
            let title = segment.segmentTitle else { return nil }
        if let attrTitle = segmentTitleFormatter?(segment, selected) {
            return attrTitle
        }
        if selected {
            return NSAttributedString(string: title, attributes: selectedTitleTextAttributes)
        } else {
            return NSAttributedString(string: title, attributes: titleTextAttributes)
        }
    }
}

// MARK: - UICollectionViewDataSource
extension NLSegmentControl: UICollectionViewDataSource {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return itemsCount
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! NLSegmentCell
        
        //text
        if let title = segments.item(at: indexPath.item)?.segmentTitle {
            cell.displayButton.setTitle(title, for: .normal)
            
            if let attrTitle = attributedTitleAtIndex(indexPath.item, selected: false) {
                cell.displayButton.setAttributedTitle(attrTitle, for: .normal)
            }
            
            if let selectedAttrTitle = attributedTitleAtIndex(indexPath.item, selected: true) {
                cell.displayButton.setAttributedTitle(selectedAttrTitle, for: .selected)
            }
        }
        
        //image
        if let image = segments.item(at: indexPath.item)?.segmentImage {
            cell.displayButton.setImage(image, for: .normal)
            
            cell.displayButton.nl_setImagePosition(position: imagePosition, spacing: imageTitleSpace)
        }
        
        //selected image
        if let image = segments.item(at: indexPath.item)?.segmentSelectedImage {
            cell.displayButton.setImage(image, for: .selected)
        }
        
        cell.segmentData = segments.item(at: indexPath.item)
        cell.contentEdgeInset = segmentEdgeInset
        
        //vertical divider
        cell.verticalDivider.isHidden = !enableVerticalDivider || (indexPath.item == itemsCount-1)
        cell.verticalDividerColor = verticalDividerColor
        cell.verticalDividerWidth = verticalDividerWidth
        cell.verticalDividerInset = verticalDividerInset
        
        configSegmentCell?(cell)
        
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension NLSegmentControl: UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize( width: widthOfSegmentAt(index: indexPath.item), height: collectionView.frame.height)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let indexChanged: Bool = indexPath.item != selectedSegmentIndex
        
        selectedSegmentIndex = indexPath.item
        if indexChanged {
            indexChangedHandler?(selectedSegmentIndex)
        }
        
        setSelectedSegmentIndex(selectedSegmentIndex, animated: true)
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == segmentCollection else {
            return
        }
        
        updateSelectionIndicator()
    }
}

// MARK: - Segment Cell

public class NLSegmentCell: UICollectionViewCell {
    
    public fileprivate(set) var segmentData: NLSegmentDataSource?
    
    public var displayButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.textAlignment = .center
        button.isUserInteractionEnabled = false
        return button
    }()
    
    fileprivate var verticalDivider: UIView = {
        let view = UIView()
        return view
    }()
    
    fileprivate var contentEdgeInset: UIEdgeInsets = .zero {
        didSet {
            displayButtonTopContraint?.constant = contentEdgeInset.top
            displayButtonLeftContraint?.constant = contentEdgeInset.left
            displayButtonBottomContraint?.constant = -contentEdgeInset.bottom
            displayButtonRightContraint?.constant = -contentEdgeInset.right
        }
    }
    
    fileprivate var verticalDividerColor: UIColor? {
        didSet {
            verticalDivider.backgroundColor = verticalDividerColor
        }
    }
    
    fileprivate var verticalDividerWidth: CGFloat = 0 {
        didSet {
            dividerWidthConstraint?.constant = verticalDividerWidth
            dividerTrailingConstraint?.constant = verticalDividerWidth/2
        }
    }
    
    fileprivate var verticalDividerInset: CGFloat = 0 {
        didSet {
            dividerTopConstraint?.constant = verticalDividerInset
            dividerBottomConstraint?.constant = -verticalDividerInset
        }
    }
    
    fileprivate var displayButtonTopContraint: NSLayoutConstraint?
    fileprivate var displayButtonLeftContraint: NSLayoutConstraint?
    fileprivate var displayButtonBottomContraint: NSLayoutConstraint?
    fileprivate var displayButtonRightContraint: NSLayoutConstraint?
    fileprivate var dividerWidthConstraint: NSLayoutConstraint?
    fileprivate var dividerTopConstraint: NSLayoutConstraint?
    fileprivate var dividerBottomConstraint: NSLayoutConstraint?
    fileprivate var dividerTrailingConstraint: NSLayoutConstraint?
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentView.addSubview(displayButton)
        displayButtonTopContraint = displayButton.nl_equalTop(toView: self.contentView)
        displayButtonLeftContraint = displayButton.nl_equalLeft(toView: self.contentView)
        displayButtonBottomContraint = displayButton.nl_equalBottom(toView: self.contentView)
        displayButtonRightContraint = displayButton.nl_equalRight(toView: self.contentView)
        
        self.contentView.addSubview(verticalDivider)
        verticalDivider.nl_equalCenterY(toView: self.contentView)
        dividerWidthConstraint = verticalDivider.nl_widthIs(verticalDividerWidth)
        dividerTrailingConstraint = verticalDivider.nl_equalRight(toView: self.contentView)
        dividerTopConstraint = verticalDivider.nl_equalTop(toView: self.contentView)
        dividerBottomConstraint = verticalDivider.nl_equalBottom(toView: self.contentView)
    }
    
    override public var isSelected: Bool {
        didSet {
            displayButton.isSelected = isSelected
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Extensions

fileprivate extension Array {
    func item(at index: Int) -> Element? {
        guard startIndex..<endIndex ~= index else { return nil }
        return self[index]
    }
}

fileprivate extension UIButton {
    
    /// set the button image position
    ///
    /// - Parameters:
    ///   - position: image position
    ///   - spacing: spacing between image and title
    func nl_setImagePosition(position: NLSegmentControl.SegmentImagePosition, spacing: CGFloat) {
        setTitle(currentTitle, for: .normal)
        setImage(currentImage, for: .normal)
        
        let imageWidth = imageView?.image?.size.width ?? 0
        let imageHeight = imageView?.image?.size.height ?? 0
        let labelSize = NSString(string: titleLabel?.text ?? "").size(withAttributes: [NSAttributedStringKey.font: titleLabel?.font ?? UIFont.systemFont(ofSize: 12)])
        let labelWidth = labelSize.width
        let labelHeight = labelSize.height
        
        let imageOffsetX = (imageWidth + labelWidth) / 2 - imageWidth / 2
        let imageOffsetY = imageHeight / 2 + spacing / 2
        let labelOffsetX = (imageWidth + labelWidth / 2) - (imageWidth + labelWidth) / 2
        let labelOffsetY = labelHeight / 2 + spacing / 2
        
        let tempWidth = max(labelWidth, imageWidth)
        let changedWidth = labelWidth + imageWidth - tempWidth
        let tempHeight = max(labelHeight, imageHeight)
        let changedHeight = labelHeight + imageHeight + spacing - tempHeight
        
        switch position {
        case .left:
            imageEdgeInsets = UIEdgeInsets(top: 0, left: -spacing / 2, bottom: 0, right: spacing / 2)
            titleEdgeInsets = UIEdgeInsets(top: 0, left: spacing / 2, bottom: 0, right: -spacing / 2)
            contentEdgeInsets = UIEdgeInsets(top: 0, left: spacing / 2, bottom: 0, right: spacing / 2)
        case .right:
            imageEdgeInsets = UIEdgeInsets(top: 0, left: labelWidth + spacing / 2, bottom: 0, right: -(labelWidth + spacing/2))
            titleEdgeInsets = UIEdgeInsets(top: 0, left: -(imageWidth + spacing/2), bottom: 0, right: imageWidth + spacing/2)
            contentEdgeInsets = UIEdgeInsets(top: 0, left: spacing / 2, bottom: 0, right: spacing / 2)
        case .top:
            imageEdgeInsets = UIEdgeInsets(top: -imageOffsetY, left: imageOffsetX, bottom: imageOffsetY, right: -imageOffsetX)
            titleEdgeInsets = UIEdgeInsets(top: labelOffsetY, left: -labelOffsetX, bottom: -labelOffsetY, right: labelOffsetX)
            contentEdgeInsets = UIEdgeInsets(top: imageOffsetY, left: -changedWidth / 2, bottom: changedHeight - imageOffsetY, right: -changedWidth / 2)
        case .bottom:
            imageEdgeInsets = UIEdgeInsets(top: imageOffsetY, left: imageOffsetX, bottom: -imageOffsetY, right: -imageOffsetX)
            titleEdgeInsets = UIEdgeInsets(top: -labelOffsetY, left: -labelOffsetX, bottom: labelOffsetY, right: labelOffsetX)
            contentEdgeInsets = UIEdgeInsets(top: changedHeight - imageOffsetY, left: -changedWidth / 2, bottom: imageOffsetY, right: -changedWidth / 2)
        }
    }
}

