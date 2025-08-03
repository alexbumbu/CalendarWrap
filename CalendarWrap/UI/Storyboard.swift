//
//  Storyboard.swift
//  CalendarWrap
//
//  Created by Alex Bumbu on 22.03.2024.
//

import UIKit

enum Storyboard: String {
    case Main
    case Photo
    
    var instance: UIStoryboard {
        // Warning: with the current implementation this works only with main bundle
        UIStoryboard(name: rawValue, bundle: nil)
    }
}

extension Storyboard {
    
    func instantiateViewController<T>(creator: ((NSCoder) -> T?)? = nil) -> T where T: UIViewController {
        instance.instantiateViewController(identifier: String(describing: T.self), creator: creator)
    }

}
