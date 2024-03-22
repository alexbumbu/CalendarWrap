//
//  AlbumCell.swift
//  EventDigest
//
//  Created by Alex Bumbu on 18.03.2024.
//

import UIKit

class AlbumCell: UITableViewCell {
    
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private(set) weak var titleLabel: UILabel!
    
    
    var albumIsVisible: Bool = false {
        didSet {
            iconImageView.isHighlighted = albumIsVisible
            titleLabel.isHighlighted = albumIsVisible
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        iconImageView.isHighlighted = false
        titleLabel.isHighlighted = false
    }
}
