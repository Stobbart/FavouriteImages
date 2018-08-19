//
//  CustomLayout.swift
//  FavouriteImages
//
//  Created by Adam Rikardsen-Smith on 16/07/2018.
//  Copyright © 2018 Adam Rikardsen-Smith. All rights reserved.
//

import Foundation
import UIKit

class CustomLayout: UICollectionViewLayout{
    
    fileprivate var cellPadding: CGFloat = 6
    static var numberOfColumns: Int = 1
    fileprivate var firstSectionAttributesCache = [UICollectionViewLayoutAttributes]()
    fileprivate var secondSectionAttributesCache = [UICollectionViewLayoutAttributes]()
    
    var contentHeight: CGFloat {
        guard let collectionView = collectionView else {
            return 0
        }
        return CGFloat(collectionView.numberOfItems(inSection: 0)) * contentWidth / CGFloat(CustomLayout.numberOfColumns * CustomLayout.numberOfColumns)
    }
    
    var contentWidth: CGFloat {
        guard let collectionView = collectionView else {
            return 0
        }
        return collectionView.bounds.width
    }
    
    override var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }
    
    override func prepare() {
        let columnWidthHeight = contentWidth / CGFloat(CustomLayout.numberOfColumns)
        let numberOfFirstSectionCells: Int = (collectionView?.numberOfItems(inSection: 0)) ?? 0
        for item in 0 ..<  numberOfFirstSectionCells{
            let frame = CGRect(x: CGFloat(item % CustomLayout.numberOfColumns) * columnWidthHeight, y: CGFloat(Int(columnWidthHeight) * Int((item / CustomLayout.numberOfColumns))), width: columnWidthHeight, height: columnWidthHeight)
            let attributes = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: item, section: 0))
            let insetFrame = frame.insetBy(dx: cellPadding, dy: cellPadding)
            attributes.frame = insetFrame
            firstSectionAttributesCache.append(attributes)
        }
        
        let numberOfSecondSectionCells: Int = (collectionView?.numberOfItems(inSection: 1)) ?? 0
        for item in 0 ..<  numberOfSecondSectionCells{
            let frame = CGRect(x: CGFloat(item % CustomLayout.numberOfColumns) * columnWidthHeight, y: CGFloat(Int(columnWidthHeight) * Int((item / CustomLayout.numberOfColumns))), width: columnWidthHeight, height: columnWidthHeight)
            let attributes = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: item, section: 1))
            let insetFrame = frame.insetBy(dx: cellPadding, dy: cellPadding)
            attributes.frame = insetFrame
            secondSectionAttributesCache.append(attributes)
        }
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {

        var visibleLayoutAttributes = [UICollectionViewLayoutAttributes]()

        for attributes in firstSectionAttributesCache {
            visibleLayoutAttributes.append(attributes)
        }
        
        for attributes in secondSectionAttributesCache {
            visibleLayoutAttributes.append(attributes)
        }
        
        return visibleLayoutAttributes
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if indexPath.section == 0{
            return firstSectionAttributesCache[indexPath.item]
        } else{
            return secondSectionAttributesCache[indexPath.item]
        }
        
    }
}
