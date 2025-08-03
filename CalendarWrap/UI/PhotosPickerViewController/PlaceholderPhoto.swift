//
//  PlaceholderPhoto.swift
//  CalendarWrap
//
//  Created by Alex Bumbu on 19.03.2024.
//

import Foundation

class PlaceholderPhoto: Photo {
    
    init() {
        super.init(id: UUID().uuidString)
    }
}
