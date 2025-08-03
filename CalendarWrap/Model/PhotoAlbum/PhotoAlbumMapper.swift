//
//  PhotoAlbumMapper.swift
//  CalendarWrap
//
//  Created by Alex Bumbu on 09.01.2024.
//

import Foundation

struct PhotoAlbumMapper {
    
    static func mapPhotoAlbum(from album: GTLRPhotosLibrary_Album) -> PhotoAlbum? {
        
        guard
            let id = album.identifier,
            let title = album.title,
            let photosCount = album.mediaItemsCount?.intValue,
            let coverPhotoBaseUrlString = album.coverPhotoBaseUrl,
            let coverPhotoBaseUrl = URL(string: coverPhotoBaseUrlString),
            let productUrlString = album.productUrl,
            let productUrl = URL(string: productUrlString)
        else {
            return nil
        }
        
        return PhotoAlbum(id: id, title: title, photosCount: photosCount, coverPhotoBaseUrl: coverPhotoBaseUrl, productUrl: productUrl)
    }
    
    static func mapPhotoAlbums(from albums: [GTLRPhotosLibrary_Album]) -> [PhotoAlbum] {
        albums.compactMap() { mapPhotoAlbum(from: $0) }
    }
}
