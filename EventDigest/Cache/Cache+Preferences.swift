//
//  Cache.swift
//  EventDigest
//
//  Created by Alex Bumbu on 09.02.2023.
//

import Foundation

extension Cache.Preferences {
    
    var key: String {
        switch self {
        case .useFacebookCalendar:
            return "preferences.useFacebookCalendar"
        case .useGoogleCalendar:
            return "preferences.useGoogleCalendar"
//        case .publishPost:
//            return "preferences.publishPost"
        }
    }
    
    func registerDefaults(_ value: Any) {
        userDefaults.register(defaults: [key: value])
    }
}

extension Cache.Preferences {
    
    static func registerDefaults() {
        useFacebookCalendar.registerDefaults(false)
        useGoogleCalendar.registerDefaults(false)
    }
}
