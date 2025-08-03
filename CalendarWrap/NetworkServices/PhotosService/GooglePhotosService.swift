//
//  GooglePhotosService.swift
//  CalendarWrap
//
//  Created by Alex Bumbu on 31.10.2023.
//

import Foundation
import OSLog
import GoogleSignIn
import GoogleAPIClientForREST

private enum Request {
    case albums
    case photos(albumId: String, pageToken: String?)
}

extension Request {

    private var query: GTLRPhotosLibraryQuery {
        let query: GTLRPhotosLibraryQuery
        switch self {
        case .albums:
            query = GTLRPhotosLibraryQuery_AlbumsList.query()
//            query.pageSize = 25 // TODO: investigate auto pagination using shouldFetchNextPages
        case .photos(let albumId, let pageToken):
            let request = GTLRPhotosLibrary_SearchMediaItemsRequest()
            request.albumId = albumId
            request.pageSize = 25 //default
            request.pageToken = pageToken
            
            query = GTLRPhotosLibraryQuery_MediaItemsSearch.query(withObject: request)
        }

        return query
    }

    func perform<T>() async throws -> T {
        let service = GTLRPhotosLibraryService()
        service.authorizer = GIDSignIn.sharedInstance.currentUser?.fetcherAuthorizer

        let result = try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<T, Error>) in
            service.executeQuery(query) { callbackTicket, response, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                if let response = response as? T {
                    continuation.resume(returning: response)
                } else {
                    continuation.resume(throwing: ApiError.invalidResponse)
                }
            }
        })

        return result
    }
}

struct GooglePhotosService {
    
    /// limited to fetching first 25 items
    static func getAlbums() async -> [PhotoAlbum]? {
        do {
            let response: GTLRPhotosLibrary_ListAlbumsResponse = try await Request.albums.perform()
            guard let albums = response.albums else {
                return nil
            }
            
            return PhotoAlbumMapper.mapPhotoAlbums(from: albums)
        } catch {
            Logger.api.error("getAlbums failure \(error)")
            return nil
        }
    }
    
    static func getPhotos(albumId: String, pageToken: String? = nil) async -> (photos: [GooglePhoto]?, nextPageToken: String?) {
        do {
            let response: GTLRPhotosLibrary_SearchMediaItemsResponse = try await Request.photos(albumId: albumId, pageToken: pageToken).perform()
            guard let photos = response.mediaItems else {
                return (photos: nil, nextPageToken: nil)
            }
                        
            return (photos: GooglePhotoMapper.mapPhotos(from: photos), nextPageToken: response.nextPageToken)
        } catch {
            Logger.api.error("getPhotos failure \(error)")
            return (photos: nil, nextPageToken: nil)
        }
    }
}
