//
//  GooglePhotoMapper.swift
//  CalendarWrap
//
//  Created by Alex Bumbu on 09.01.2024.
//

import Foundation

struct GooglePhotoMapper {
    
    static func mapPhoto(from mediaItem: GTLRPhotosLibrary_MediaItem) -> GooglePhoto? {
        guard
            let id = mediaItem.identifier,
            let filename = mediaItem.filename,
            let mimeType = mediaItem.mimeType,
            let baseUrlString = mediaItem.baseUrl,
            let baseUrl = URL(string: baseUrlString),
            let productUrlString = mediaItem.productUrl,
            let productUrl = URL(string: productUrlString),
            let width = mediaItem.mediaMetadata?.width?.doubleValue,
            let height = mediaItem.mediaMetadata?.height?.doubleValue
        else {
            return nil
        }
        
        let size = CGSize(width: width, height: height)
                
        return GooglePhoto(id: id, filename: filename, mimeType: mimeType, baseURL: baseUrl, productURL: productUrl, size: size)
    }
    
    static func mapPhotos(from mediaItems: [GTLRPhotosLibrary_MediaItem]) -> [GooglePhoto] {
        mediaItems.compactMap() { mapPhoto(from: $0) }
    }
}
