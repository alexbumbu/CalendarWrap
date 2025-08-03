//
//  Cache.swift
//  CalendarWrap
//
//  Created by Alex Bumbu on 09.02.2023.
//

import Foundation

extension Cache.Session {
    
    var key: String {
        switch self {
        case .currentCalendar:
            return "session.currentCalendar"
        }
    }
}
