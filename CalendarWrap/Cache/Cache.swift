//
//  Cache.swift
//  CalendarWrap
//
//  Created by Alex Bumbu on 09.02.2023.
//

import Foundation

enum Cache {
    
    static func clear() {
        guard let domain = Bundle.main.bundleIdentifier else {
            return
        }
                
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
    }
}

extension Cache {
    
    enum Preferences: CaseIterable, Cacheable, DefaultsRegistrable {
        case useFacebookCalendar
        case useGoogleCalendar
        case summaryPostTemplate
    }
    
    enum Session: CaseIterable, Cacheable {
        case currentCalendar
    }
}

// MARK: -

protocol Cacheable {
    
    var userDefaults: UserDefaults { get }
    var key: String { get }
    
    @discardableResult
    func save<T: Any>(_ value: T, encode: Bool) -> Bool
    func load<T: Any>(decode: Bool) -> T? where T: Decodable
    
    func remove()
}

extension Cacheable {
    
    var userDefaults: UserDefaults { UserDefaults.standard }
    
    @discardableResult
    func save<T: Any>(_ value: T, encode: Bool = false) -> Bool {
        var valueToSave: Any = value
        if encode {
            let encoder = JSONEncoder()
            guard
                let value = value as? Encodable,
                let encodedData = try? encoder.encode(value)
            else {
                return false
            }
            
            valueToSave = encodedData
        }
        
        userDefaults.set(valueToSave, forKey: key)
        
        return true
    }
    
    func load<T: Any>(decode: Bool = false) -> T? where T: Decodable {
        if decode {
            let decoder = JSONDecoder()
            guard let encodedData = userDefaults.data(forKey: key) else {
                return nil
            }
            
            return try? decoder.decode(T.self, from: encodedData)
        } else {
            return userDefaults.object(forKey: key) as? T
        }
    }

    func remove() {
        userDefaults.removeObject(forKey: key)
    }
}

//MARK: -

private protocol DefaultsRegistrable {
    
    func registerDefaults(_ value: Any, encode: Bool)
}
