//
//  Photo.swift
//  EventDigest
//
//  Created by Alex Bumbu on 19.03.2024.
//

import Foundation

class Photo: NSObject {
    
    let id: String
    private(set) var url: URL?
    
    init(id: String) {
        self.id = id
    }
}
