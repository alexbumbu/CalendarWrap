//
//  ReplaceRootSegue.swift
//  EventDigest
//
//  Created by Alex Bumbu on 02.02.2023.
//

import UIKit

class ReplaceRootSegue: UIStoryboardSegue {
    
    override func perform() {
        guard let navigationController = source.navigationController else {
            return
        }
        
        navigationController.setViewControllers([destination], animated: true)
    }
}
