//
//  UIViewController + Alert.swift
//  EventDigest
//
//  Created by Alex Bumbu on 20.06.2023.
//

import UIKit

@MainActor
extension UIViewController {
    
    func showInfoAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        
        present(alert, animated: true)
    }
}
