//
//  Photo.swift
//  CalendarWrap
//
//  Created by Alex Bumbu on 19.03.2024.
//

import Foundation

class Photo: NSObject {
    
    enum Orientation {
        case portrait
        case landscape
    }
    
    let id: String
    private(set) var url: URL?
    private(set) var orientation: Orientation
    
    init(id: String) {
        self.id = id
        self.orientation = .landscape
    }
}
