//
//  Cache.swift
//  CalendarWrap
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
        case .summaryPostTemplate:
            return "preferences.summaryPostTemplate"
        }
    }
    
    func registerDefaults(_ value: Any, encode: Bool = false) {
        var valueToSave: Any = value
        if encode {
            let encoder = JSONEncoder()
            guard
                let value = value as? Encodable,
                let encodedData = try? encoder.encode(value)
            else {
                return
            }
            
            valueToSave = encodedData
        }
        
        userDefaults.register(defaults: [key: valueToSave])
    }
}

extension Cache.Preferences {
    
    static func registerDefaults() {
        useFacebookCalendar.registerDefaults(false)
        useGoogleCalendar.registerDefaults(false)
        summaryPostTemplate.registerDefaults(SummaryTemplate.empty(), encode: true)
    }
}
