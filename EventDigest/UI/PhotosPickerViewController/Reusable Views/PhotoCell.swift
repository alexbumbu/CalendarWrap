//
//  PhotoCell.swift
//  EventDigest
//
//  Created by Alex Bumbu on 10.01.2024.
//

import UIKit

class PhotoCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var selectedIconImageView: UIImageView!
    
    var didLongPress: (() -> Void)?
        
    override var isHighlighted: Bool {
        didSet {
            selectedIconImageView.isHighlighted = isHighlighted
        }
    }
    
    override var isSelected: Bool {
        didSet {
            selectedIconImageView.image = isSelected ? selectedIconImageView.highlightedImage : nil
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressAction))
        addGestureRecognizer(longPressGesture)
    }
    
    @objc func longPressAction() {
        didLongPress?()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        imageView.image = nil
    }
}
