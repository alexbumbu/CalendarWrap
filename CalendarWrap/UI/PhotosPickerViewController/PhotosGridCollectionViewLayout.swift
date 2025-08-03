//
//  PhotosGridCollectionViewLayout.swift
//  CalendarWrap
//
//  Created by Alex Bumbu on 04.04.2024.
//

import UIKit

private typealias PhotoItem = (photo: Photo, indexPath: IndexPath, size: CGSize?)

class PhotosGridCollectionViewLayout: UICollectionViewLayout {
    
    private enum Constants {
        static let aspectRatioTwoByThree = 2.0 / 3.0
        static let aspectRatioThreeByTwo = 3.0 / 2.0
        
        static let sectionHeaderHeight = 70.0
        static let sectionFooterHeight = 126.0
    }
    
    var photoForIndexPath: ((IndexPath) -> Photo)?

    private var cache: [UICollectionViewLayoutAttributes] = .init()
    
    func sizeForItem(at indexPath: IndexPath) -> CGSize? {
        layoutAttributesForItem(at: indexPath)?.size
    }

    override func prepare() {
        super.prepare()
                
        guard let collectionView = collectionView, let photoForIndexPath = photoForIndexPath else {
            return
        }
        
        cache.removeAll()
        
        let contentWidth = collectionViewContentSize.width
        // the spacer is used to avoid sizes with decimal values
        let spacer = contentWidth.truncatingRemainder(dividingBy: 2)
        
        var xOffset: CGFloat = 0
        var yOffset: CGFloat = 0
        
        let setCellLayoutAttributesForItems: ([PhotoItem]) -> Void = { [weak self] group in
            let insets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
            
            for item in group {
                guard let size = item.size else {
                    return
                }
                
                var adjustedSize = size
                adjustedSize.width -= (insets.left + insets.right)
                adjustedSize.height -= (insets.top + insets.bottom)
                
                let frame = CGRect(origin: CGPoint(x: xOffset + insets.left, y: yOffset + insets.top), size: adjustedSize)
                let attributes = UICollectionViewLayoutAttributes(forCellWith: item.indexPath)
                attributes.frame = frame
                self?.cache.append(attributes)
                
                xOffset += size.width
                xOffset += spacer
            }
            
            if xOffset >= contentWidth || group.count == 1 {
                xOffset = 0
                yOffset += group.first?.size?.height ?? .zero
                yOffset += spacer
            }
        }
        
        let setAttributesForSupplementaryViewOfKind: (String, IndexPath) -> Void = { [weak self] kind, indexPath in
            let height: CGFloat
            switch kind {
            case UICollectionView.elementKindSectionHeader:
                height = Constants.sectionHeaderHeight
            case UICollectionView.elementKindSectionFooter:
                height = Constants.sectionFooterHeight
            default:
                height = 0
            }
            
            let attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: kind, with: indexPath)
            attributes.frame = CGRect(x: 0, y: yOffset, width: contentWidth, height: height)
            self?.cache.append(attributes)
            
            yOffset += height
        }
        
        for section in 0 ..< collectionView.numberOfSections {
            let itemsCount = collectionView.numberOfItems(inSection: section)
            var showSingleCell = itemsCount % 2 == 1
            var group = [PhotoItem]()
            
            let indexPath = IndexPath(item: 0, section: section)
            setAttributesForSupplementaryViewOfKind(UICollectionView.elementKindSectionHeader, indexPath)

            for item in 0 ..< itemsCount {
                let indexPath = IndexPath(item: item, section: section)
                let photo = photoForIndexPath(indexPath)
                
                group.append((photo, indexPath, nil))
                
                if group.count == 2 {
                    switch (group[0].photo.orientation, group[1].photo.orientation) {
                    case (.landscape, .landscape):
                        let width = (contentWidth/2).rounded(.down)
                        let height = (width * Constants.aspectRatioTwoByThree).rounded(.down)
                        
                        group[0].size = CGSize(width: width, height: height)
                        group[1].size = CGSize(width: width, height: height)
                    case (.landscape, .portrait):
                        let height = (contentWidth/2).rounded(.down)
                        let portraitWidth = (height * Constants.aspectRatioTwoByThree).rounded(.down)
                        let landscapeWidth = contentWidth - portraitWidth
                        
                        group[0].size = CGSize(width: landscapeWidth, height: height)
                        group[1].size = CGSize(width: portraitWidth, height: height)
                    case (.portrait, .landscape):
                        let height = (contentWidth/2).rounded(.down)
                        let portraitWidth = (height * Constants.aspectRatioTwoByThree).rounded(.down)
                        let landscapeWidth = contentWidth - portraitWidth
                        
                        group[0].size = CGSize(width: portraitWidth, height: height)
                        group[1].size = CGSize(width: landscapeWidth, height: height)
                    case (.portrait, .portrait):
                        let width = (contentWidth/2).rounded(.down)
                        let height = (width * Constants.aspectRatioThreeByTwo).rounded(.down)
                        
                        group[0].size = CGSize(width: width, height: height)
                        group[1].size = CGSize(width: width, height: height)
                    }
                    
                    setCellLayoutAttributesForItems(group)
                    group.removeAll(keepingCapacity: true)
                }
                
                if (showSingleCell && photo.orientation == .landscape) || item == itemsCount - 1, !group.isEmpty  {
                    if photo.orientation == .landscape {
                        let height = (contentWidth * Constants.aspectRatioTwoByThree).rounded(.down)
                        group[0].size = CGSize(width: contentWidth, height: height)
                    } else {
                        let width = (contentWidth/2).rounded(.down)
                        let height = (width * Constants.aspectRatioThreeByTwo).rounded(.down)
                        group[0].size = CGSize(width: width, height: height)
                    }
                    
                    setCellLayoutAttributesForItems(group)
                    group.removeAll(keepingCapacity: true)
                    showSingleCell = false
                }
            }
        }
                
        let indexPath = IndexPath(item: 0, section: collectionView.numberOfSections - 1)
        setAttributesForSupplementaryViewOfKind(UICollectionView.elementKindSectionFooter, indexPath)
    }
    
    override var collectionViewContentSize: CGSize {
        guard let collectionView = collectionView else {
            return .zero
        }
        
        let contentWidth = collectionView.bounds.width
        let contentHeight = cache.last?.frame.maxY ?? 0
        
        return CGSize(width: contentWidth, height: contentHeight)
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return cache.filter { rect.intersects($0.frame) }
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cache.first(where: { $0.indexPath == indexPath && $0.representedElementCategory == .cell })
    }
    
    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cache.first(where: { $0.indexPath == indexPath && $0.representedElementCategory == .supplementaryView })
    }
}
