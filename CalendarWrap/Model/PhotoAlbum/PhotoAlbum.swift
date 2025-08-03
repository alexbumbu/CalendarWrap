//
//  PhotoAlbum.swift
//  CalendarWrap
//
//  Created by Alex Bumbu on 09.01.2024.
//

import Foundation

class PhotoAlbum: NSObject {
    let id: String
    let title: String
    let photosCount: Int
    let coverPhotoBaseUrl: URL
    let productUrl: URL
    
    var photos: [Photo]?
    
    var photosFetched: Bool {
        photos != nil
    }
    
    init(id: String, title: String, photosCount: Int, coverPhotoBaseUrl: URL, productUrl: URL) {
        self.id = id
        self.title = title
        self.photosCount = photosCount
        self.coverPhotoBaseUrl = coverPhotoBaseUrl
        self.productUrl = productUrl
    }
}
