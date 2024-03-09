//
//  ViewController.swift
//  EventDigest
//
//  Created by Alex Bumbu on 02.02.2023.
//

import UIKit
import FBSDKLoginKit
import GoogleSignIn

class LoginViewController: UIViewController {
    
    private enum Segue: String, SegueNavigation {
        case showCreateSummaryPostSegue
        
        var identifier: String { rawValue }
    }
    
    @IBOutlet private weak var spinner: UIActivityIndicatorView!
    @IBOutlet private weak var facebookLoginButton: UIButton!
    @IBOutlet private weak var googleLoginButton: GIDSignInButton!
        
    override func viewDidLoad() {
        super.viewDidLoad()
                
        googleLoginButton.style = .wide
        
        googleLoginButton.isHidden = true
        facebookLoginButton.isHidden = true

        Task {
            let success = await restorePreviousSignIn()
            if !success {
                await MainActor.run {
                    spinner.stopAnimating()

                    googleLoginButton.isHidden = false
                    facebookLoginButton.isHidden = false
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: false)

        super.viewWillAppear(animated)
    }
    
    @IBAction func facebookSignInAction() {
        facebookLoginButton.isHidden = true
        googleLoginButton.isHidden = true
        
        Task {
            guard await signIn(serviceType: FacebookLoginService.self, permissions: FacebookCalendarService.permissions) else {
                await MainActor.run {
                    facebookLoginButton.isHidden = false
                    googleLoginButton.isHidden = false
                }
                
                return
            }
            
            await fetchCalendars(serviceType: FacebookCalendarService.self)
            await selectCalendar()
            Cache.Preferences.useFacebookCalendar.save(true)
            
            if Session.current?.activeCalendar != nil {
                navigateToCreatePost()
            }
        }
    }
    
    @IBAction func googleSignInAction() {
        facebookLoginButton.isHidden = true
        googleLoginButton.isHidden = true
        
        Task {
            guard await signIn(serviceType: GoogleLoginService.self, permissions: GoogleCalendarService.permissions) else {
                await MainActor.run {
                    facebookLoginButton.isHidden = false
                    googleLoginButton.isHidden = false
                }
                
                return
            }
            
            await fetchCalendars(serviceType: GoogleCalendarService.self)
            await selectCalendar()
            Cache.Preferences.useGoogleCalendar.save(true)
            
            if Session.current?.activeCalendar != nil {
                navigateToCreatePost()
            }
        }
    }
}

private extension LoginViewController {
    
    func signIn<T>(serviceType: T.Type, permissions: [String]) async -> Bool where T: LoginService {
        await T.logIn(from: self, permissions: permissions)
    }
    
    func fetchCalendars<T>(serviceType: T.Type) async where T: CalendarService {
        spinner.startAnimating()
                
        guard let calendars = await T.getCalendars() else {
            return
        }
        
        spinner.stopAnimating()
        
        if Session.current != nil {
            Session.current?.calendars = calendars
        } else {
            Session.current = Session(calendars: calendars)
        }
    }
    
    func restorePreviousSignIn() async -> Bool {
        let serviceType: LoginService.Type
        switch Session.current?.activeCalendar.type {
        case .facebook:
            serviceType = FacebookLoginService.self
        case .google:
            serviceType = GoogleLoginService.self
        case .none:
            return false
        }
        
        guard await serviceType.restorePreviousSignIn() else {
            return false
        }
        
        if Session.current?.activeCalendar != nil {
            navigateToCreatePost()
        }
        
        return true
    }
    
    @MainActor
    func selectCalendar() async {
        guard let calendars = Session.current?.calendars else {
            return
        }
        
        if calendars.count == 1, let calendar = calendars.first {
            Session.current?.activeCalendar = calendar
            return
        }
                
        let calendar = await withCheckedContinuation({ (continuation:CheckedContinuation<Calendar?, Never>) in
            let alert = UIAlertController(title: "Select calendar", message: "", preferredStyle: .actionSheet)

            calendars.forEach { calendar in
                alert.addAction(UIAlertAction(title: calendar.name, style: .default) { _ in
                    continuation.resume(returning: calendar)
                })
            }
            alert.addAction(UIAlertAction(title: "Logout", style: .destructive) { [weak self] _ in
                self?.logout()
                continuation.resume(returning: nil)
            })
            
            present(alert, animated: true)
        })
                
        if let calendar {
            Session.current?.activeCalendar = calendar
        }
    }
    
    @MainActor
    func logout() {
        GoogleLoginService.logOut()
        FacebookLoginService.logOut()
        
        Cache.clear()
        Session.current = nil
        
        googleLoginButton.isHidden = false
        facebookLoginButton.isHidden = false
    }
    
    @MainActor
    func navigateToCreatePost() {
        Segue.showCreateSummaryPostSegue.perform(in: self, sender: nil)
    }
}
