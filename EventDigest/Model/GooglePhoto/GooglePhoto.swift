//
//  GooglePhoto.swift
//  EventDigest
//
//  Created by Alex Bumbu on 09.01.2024.
//

import Foundation

class GooglePhoto: Photo {
    
    private enum Constants {
        static let maxImageSize = CGSize(width: 2048, height: 2048)
    }
    
    let filename: String
    let mimeType: String
    let size: CGSize
    
    private let baseURL: URL
    private let productURL: URL
    
    override var url: URL? {
        if size.width > Constants.maxImageSize.width || size.height > Constants.maxImageSize.height {
            return url(size: Constants.maxImageSize, maintainingAspectRatio: true)
        }
        
        // no need to check for aspect ratio for default size
        return url(size: size, maintainingAspectRatio: false)
    }
    
    init(id: String, filename: String, mimeType: String, baseURL: URL, productURL: URL, size: CGSize) {
        self.filename = filename
        self.mimeType = mimeType
        self.baseURL = baseURL
        self.productURL = productURL
        self.size = size
        
        super.init(id: id)
    }
    
    func url(size: CGSize, maintainingAspectRatio: Bool) -> URL? {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            return baseURL
        }
        
        var scaledSize = size
        if maintainingAspectRatio {
            scaledSize = convertSize(size, toAspectRatioOf: self.size)
        }
        
        components.path = components.path.appending("=w\(Int(scaledSize.width))-h\(Int(scaledSize.height))")
        
        return components.url
    }
}

private extension GooglePhoto {
    
    func convertSize(_ size: CGSize, toAspectRatioOf photoSize: CGSize) -> CGSize {
        let aspectRatio = photoSize.width / photoSize.height
        let scaledWidth = size.height * aspectRatio
        let scaledHeight = size.width / aspectRatio
        
        // Ensure neither width nor height is lower than the original size
        let resultWidth = max(scaledWidth, size.width)
        let resultHeight = max(scaledHeight, size.height)
        
        // Ensure the aspect ratio is maintained
        let resultSize: CGSize
        if resultWidth / resultHeight > aspectRatio {
            resultSize = CGSize(width: resultHeight * aspectRatio, height: resultHeight)
        } else {
            resultSize = CGSize(width: resultWidth, height: resultWidth / aspectRatio)
        }
        
        return resultSize
    }
}
