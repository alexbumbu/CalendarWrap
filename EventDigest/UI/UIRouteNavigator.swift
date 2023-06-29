//
//  UIRouteNavigator.swift
//  EventDigest
//
//  Created by Alex Bumbu on 27.04.2023.
//

import Foundation

protocol UIRoutingProtocol: AnyObject {
    
    func handleRoute(_ route: String)
}

class UIRoutesNavigator {
    
    static var shared = UIRoutesNavigator()
    
    private let observers = NSHashTable<AnyObject>.weakObjects()
    
    func registerObserver(_ observer: UIRoutingProtocol) {
        observers.add(observer)
    }
    
    func unregisterObserver(_ observer: UIRoutingProtocol) {
        observers.remove(observer)
    }
    
    func navigateToRoute(_ route: String) {
        for observer in observers.allObjects {
            guard let observer = observer as? UIRoutingProtocol else {
                continue
            }
            
            observer.handleRoute(route)
        }
    }
}
