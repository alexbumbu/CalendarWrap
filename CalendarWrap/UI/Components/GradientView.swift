//
//  GradientView.swift
//  CalendarWrap
//
//  Created by Alex Bumbu on 09.03.2024.
//

import UIKit

protocol GradientView: UIView {
    
    var type: CAGradientLayerType { get }
    var colors: [CGColor] { get }
    var locations: [NSNumber]? { get }
}

extension GradientView {
    
    var type: CAGradientLayerType {
        .axial
    }
}
