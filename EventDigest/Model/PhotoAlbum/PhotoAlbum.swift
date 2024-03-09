//
//  PhotoAlbum.swift
//  EventDigest
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
    var photos: [GooglePhoto]?
    
    init(id: String, title: String, photosCount: Int, coverPhotoBaseUrl: URL, productUrl: URL, photos: [GooglePhoto]? = nil) {
        self.id = id
        self.title = title
        self.photosCount = photosCount
        self.coverPhotoBaseUrl = coverPhotoBaseUrl
        self.productUrl = productUrl
        self.photos = photos
    }
}
