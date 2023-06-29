//
//  SegueNavigation.swift
//  EventDigest
//
//  Created by Alex Bumbu on 03.02.2023.
//

import UIKit

protocol SegueNavigation {
    var identifier: String { get }
    func perform(in viewController: UIViewController, sender: Any?)
}

extension SegueNavigation {
    
    func perform(in viewController: UIViewController, sender: Any?) {
        viewController.performSegue(withIdentifier: identifier, sender: sender)
    }
}
