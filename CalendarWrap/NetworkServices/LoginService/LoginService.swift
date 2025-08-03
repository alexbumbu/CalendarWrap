//
//  LoginService.swift
//  CalendarWrap
//
//  Created by Alex Bumbu on 19.06.2023.
//

import UIKit

protocol LoginService {
    
    static var isLoggedIn: Bool { get }
    
    static func logIn(from viewController: UIViewController, permissions scopes: [String]) async -> Bool
    static func restorePreviousSignIn() async -> Bool
    static func logOut()
}
