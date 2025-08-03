//
//  UINavigationController + Root.swift
//  CalendarWrap
//
//  Created by Alex Bumbu on 02.02.2024.
//

import UIKit

extension UINavigationController {
    
    var rootViewController: UIViewController? {
        viewControllers.first
    }
}
