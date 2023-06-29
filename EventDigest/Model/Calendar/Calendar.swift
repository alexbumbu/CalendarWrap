//
//  Calendar.swift
//  EventDigest
//
//  Created by Alex Bumbu on 08.02.2023.
//

import Foundation

struct Calendar: Codable {
    enum CalendarType: String, Codable {
        case facebook
        case google
    }
    
    var id: String
    var name: String
    var type: CalendarType
}

extension Calendar: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name && lhs.type == rhs.type
    }
}
