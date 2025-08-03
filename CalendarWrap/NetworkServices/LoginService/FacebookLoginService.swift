//
//  FacebookLoginService.swift
//  CalendarWrap
//
//  Created by Alex Bumbu on 19.06.2023.
//

import Foundation
import OSLog
import FBSDKLoginKit

enum LoginError: Error {
    case cancelled
}

struct FacebookLoginService: LoginService {
    
    static var isLoggedIn: Bool {
        guard let token, !token.isExpired else {
            return false
        }
        
        return true        
    }
    
    @MainActor
    static func logIn(from viewController: UIViewController, permissions: [String]) async -> Bool {
        await withCheckedContinuation({ (continuation: CheckedContinuation<Bool, Never>) in
            LoginManager().logIn(permissions: permissions, from: viewController) { result, error in
                if error != nil || result?.isCancelled == true {
                    Logger.api.error("logIn failure \(error ?? LoginError.cancelled)")
                    continuation.resume(returning: false)
                    return
                }
                
                continuation.resume(returning: result != nil)
            }
        })
    }
    
    static func restorePreviousSignIn() async -> Bool {
        guard FacebookLoginService.isLoggedIn else {
            return false
        }
            
        return true
    }
    
    static func logOut() {
        LoginManager().logOut()
    }
}

private extension FacebookLoginService {
    
    static var token: AccessToken? { AccessToken.current }
}
