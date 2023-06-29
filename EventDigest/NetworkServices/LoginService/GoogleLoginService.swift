//
//  GoogleLoginService.swift
//  EventDigest
//
//  Created by Alex Bumbu on 19.06.2023.
//

import Foundation
import OSLog
import GoogleSignIn

struct GoogleLoginService: LoginService {
    
    static var isLoggedIn: Bool {
        GIDSignIn.sharedInstance.currentUser != nil
    }

    @MainActor
    static func logIn(from viewController: UIViewController, permissions scopes: [String]) async -> Bool {
        await withCheckedContinuation({ (continuation: CheckedContinuation<Bool, Never>) in
            GIDSignIn.sharedInstance.signIn(withPresenting: viewController, hint: nil, additionalScopes: scopes) { result, error in
                if let error {
                    Logger.api.error("logIn failure \(error)")
                    continuation.resume(returning: false)
                    return
                }
                
                continuation.resume(returning: result != nil)
            }
        })
    }
    
    static func restorePreviousSignIn() async -> Bool {
        await withCheckedContinuation({ (continuation: CheckedContinuation<Bool, Never>) in
            GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                if error != nil {
                    continuation.resume(returning: false)
                    return
                }
                
                continuation.resume(returning: user != nil)
            }
        })
    }
    
    static func logOut() {
        Task {
            do {
                try await GIDSignIn.sharedInstance.disconnect()
            } catch {
                Logger.api.error("disconnect failure \(error)")
            }
        }
    }
}
