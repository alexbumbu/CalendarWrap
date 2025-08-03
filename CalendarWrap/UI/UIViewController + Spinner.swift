//
//  UIViewController + Spinner.swift
//  CalendarWrap
//
//  Created by Alex Bumbu on 22.02.2023.
//

import UIKit
import MBProgressHUD

@MainActor
extension UIViewController {
    
    func showSpinner() {
        let spinner = MBProgressHUD.showAdded(to: view, animated: true)
        spinner.show(animated: true)
    }
    
    func hideSpinner() {
        MBProgressHUD.hide(for: view, animated: true)
    }
}
