//
//  UIRoute.swift
//  EventDigest
//
//  Created by Alex Bumbu on 27.04.2023.
//

import Foundation

enum UIRoute: String {
    case loginScreen
}

extension UIRoutesNavigator {
    
    func navigateToRoute(_ route: UIRoute) {
        navigateToRoute(route.rawValue)
    }
}
