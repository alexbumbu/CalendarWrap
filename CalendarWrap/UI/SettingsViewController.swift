//
//  SettingsViewController.swift
//  CalendarWrap
//
//  Created by Alex Bumbu on 27.04.2023.
//

import UIKit

protocol SettingsViewControllerDelegate: AnyObject {
    
    var didUpdateActiveCalendar: (() -> Void)? { get set }
}

class SettingsViewController: UITableViewController {
    
    @IBOutlet private weak var currentCalendarLabel: UILabel!
    @IBOutlet private weak var facebookCalendarSwitch: UISwitch!
    @IBOutlet private weak var googleCalendarSwitch: UISwitch!
    
    private weak var delegate: SettingsViewControllerDelegate?
    
    private var useFacebookCalendar: Bool { facebookCalendarSwitch.isOn }
    private var useGoogleCalendar: Bool { googleCalendarSwitch.isOn }
    
    private var routesNavigator = UIRoutesNavigator.shared
    
    init?(coder: NSCoder, delegate: SettingsViewControllerDelegate) {
        super.init(coder: coder)
        self.delegate = delegate
    }
    
    @available(*, unavailable, renamed: "init(coder:delegate:)")
    required init?(coder: NSCoder) {
        fatalError("Invalid way of decoding this class")
    }
    
    deinit {
        routesNavigator.unregisterObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        routesNavigator.registerObserver(self)
        
        currentCalendarLabel.text = Session.current?.activeCalendar.name ?? ""
        facebookCalendarSwitch.isOn = Cache.Preferences.useFacebookCalendar.load() ?? false
        googleCalendarSwitch.isOn = Cache.Preferences.useGoogleCalendar.load() ?? false
    }
}

extension SettingsViewController: UIRoutingProtocol {
    
    func handleRoute(_ route: String) {
        let route = UIRoute(rawValue: route)
        switch route {
        case .loginScreen:
            self.dismiss(animated: false)
        default:
            break
        }
    }
}

private extension SettingsViewController {
    
    @IBAction func doneAction() {
        dismiss(animated: true)
    }
    
    @IBAction func facebookCalendarToggleAction() {
        googleCalendarSwitch.isOn = !useFacebookCalendar
        
        guard useFacebookCalendar else {
            return
        }
        
        Task {
            if !FacebookLoginService.isLoggedIn {
                guard await logIn(serviceType: FacebookLoginService.self, permissions: FacebookCalendarService.permissions) else {
                    await MainActor.run {
                        facebookCalendarSwitch.isOn = false
                        googleCalendarSwitch.isOn = true
                    }
                
                    return
                }
            }
            
            await fetchCalendars(serviceType: FacebookCalendarService.self)
            await selectCalendar()
                        
            Cache.Preferences.useFacebookCalendar.save(useFacebookCalendar)
            Cache.Preferences.useGoogleCalendar.save(useGoogleCalendar)
            
            reloadUI()
            delegate?.didUpdateActiveCalendar?()
        }
    }
    
    @IBAction func googleCalendarToggleAction() {
        facebookCalendarSwitch.isOn = !useGoogleCalendar
        
        guard useGoogleCalendar else {
            return
        }
        
        Task {
            if !GoogleLoginService.isLoggedIn {
                guard await logIn(serviceType: GoogleLoginService.self, permissions: GoogleCalendarService.permissions) else {
                    await MainActor.run {
                        googleCalendarSwitch.isOn = false
                        facebookCalendarSwitch.isOn = true
                    }
                    
                    return
                }
            }
            
            await fetchCalendars(serviceType: GoogleCalendarService.self)
            await selectCalendar()
                        
            Cache.Preferences.useGoogleCalendar.save(useGoogleCalendar)
            Cache.Preferences.useFacebookCalendar.save(useFacebookCalendar)
            
            reloadUI()
            delegate?.didUpdateActiveCalendar?()
        }
    }
    
    @IBAction func logoutAction() {
        let alert = UIAlertController(title: nil, message: "Are you sure you want to log out?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive) { _ in
            self.logOut()
            self.routesNavigator.navigateToRoute(.loginScreen)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}


// MARK: UITableViewDelegate

@MainActor
extension SettingsViewController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0, indexPath.row == 0 {
            let serviceType: CalendarService.Type
            switch Session.current?.activeCalendar.type {
            case .facebook:
                serviceType = FacebookCalendarService.self
            case .google:
                serviceType = GoogleCalendarService.self
            case .none:
                return
            }
            
            Task {
                await fetchCalendars(serviceType: serviceType)
                await selectCalendar()
                reloadUI()
            }
        }
    }
}

@MainActor
private extension SettingsViewController {
    
    func reloadUI() {
        currentCalendarLabel.text = Session.current?.activeCalendar.name ?? ""
    }
    
    func selectCalendar() async {
        guard let calendars = Session.current?.calendars else {
            return
        }
        
        if calendars.count == 1, let calendar = calendars.first {
            Session.current?.activeCalendar = calendar
            return
        }
                
        let calendar = await withCheckedContinuation({ (continuation:CheckedContinuation<EventsCalendar?, Never>) in
            let alert = UIAlertController(title: "Select calendar", message: "", preferredStyle: .actionSheet)

            calendars.forEach { calendar in
                alert.addAction(UIAlertAction(title: calendar.name, style: .default) { _ in
                    continuation.resume(returning: calendar)
                })
            }
            alert.addAction(UIAlertAction(title: "Logout", style: .destructive) { [weak self] _ in
                self?.logOut()
                continuation.resume(returning: nil)
            })
            
            present(alert, animated: true)
        })
                
        if let calendar {
            Session.current?.activeCalendar = calendar
        }
    }
}

private extension SettingsViewController {
    
    func logIn<T>(serviceType: T.Type, permissions: [String]) async -> Bool where T: LoginService {
        await T.logIn(from: self, permissions: permissions)
    }
    
    func logOut() {
        FacebookLoginService.logOut()
        GoogleLoginService.logOut()
        Cache.clear()
        
        dismiss(animated: true)
    }
    
    func fetchCalendars<T>(serviceType: T.Type) async where T: CalendarService {
//        spinner.startAnimating()
                
        guard let calendars = await T.getCalendars() else {
            return
        }
        
//        spinner.stopAnimating()
        
        if Session.current != nil {
            Session.current?.calendars = calendars
        } else {
            Session.current = Session(calendars: calendars)
        }
    }
}
