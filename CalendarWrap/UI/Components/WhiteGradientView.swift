//
//  WhiteGradientView.swift
//  CalendarWrap
//
//  Created by Alex Bumbu on 09.03.2024.
//

import UIKit

class WhiteGradientView: UIView, GradientView {
    
    var colors: [CGColor] {
        [UIColor(white: 1, alpha: 0).cgColor,
         UIColor(white: 1, alpha: 0.3).cgColor,
         UIColor(white: 1, alpha: 0.5).cgColor,
         UIColor(white: 1, alpha: 0.7).cgColor,
         UIColor(white: 1, alpha: 0.8).cgColor,
         UIColor.white.cgColor
        ]
    }
    
    var locations: [NSNumber]? {
        [0, 0.15, 0.3, 0.4, 0.5, 0.7]
    }
    
    override open class var layerClass: AnyClass {
       return CAGradientLayer.classForCoder()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        let gradientLayer = layer as! CAGradientLayer
        gradientLayer.type = type
        gradientLayer.colors = colors
        gradientLayer.locations = locations
    }
}
