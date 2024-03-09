//
//  FacebookCalendarService.swift
//  EventDigest
//
//  Created by Alex Bumbu on 02.02.2023.
//

import Foundation
import FBSDKLoginKit
import OSLog

private enum Request {
    case pages
    case pageAccessToken(String)
    case events(String, Int, Int)
    case createSummaryPost(String, String, String?, Date?)
    case uploadPhoto(String, String, Bool)
}

extension Request {
    var path: String {
        switch self {
        case .pages:
            return "me/accounts"
        case .pageAccessToken(let pageId):
            return "\(pageId)"
        case .events(let pageId, _, _):
            return "\(pageId)/events"
        case .createSummaryPost(let pageId, _, _, _):
            return "\(pageId)/feed"
        case .uploadPhoto(let pageId, _, _):
            return "\(pageId)/photos"
        }
    }
    
    var parameters: [String: Any] {
        switch self {
        case .pages:
            return ["fields": "name"]
        case .pageAccessToken:
            return ["fields": "access_token"]
        case .events(_, let since, let until):
            return ["fields": "name, start_time, place, is_online", "since": since, "until": until]
        case .createSummaryPost(_, let message, let photoId, let scheduledDate):
            var params: [String: Any] = ["message": message]
            if let photoId {
                params["attached_media"] = "[{\"media_fbid\": \"\(photoId)\"}]"
            }
            
            if let scheduledDate {
                let timeInterval = Int(scheduledDate.timeIntervalSince1970)
                params["published"] = false
                params["unpublished_content_type"] = "SCHEDULED"
                params["scheduled_publish_time"] = timeInterval
            }
            
            return params
        case .uploadPhoto(_, let photoURL, let temporary):
            return ["url": photoURL, "published": false, "temporary": temporary]
        }
    }
    
    var httpMethod: HTTPMethod {
        switch self {
        case .createSummaryPost, .uploadPhoto:
            return .post
        default:
            return .get
        }
    }
}

extension Request {
    
    func perform(token: String? = AccessToken.current?.tokenString) async throws -> [String: Any] {
        guard token != nil else {
            Logger.api.error("Invalid access token")
            throw ApiError.missingToken
        }
        
        let request = GraphRequest(graphPath: path,
                                   parameters: parameters,
                                   tokenString: token,
                                   version: nil,
                                   httpMethod: httpMethod)
        
        let result = try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<[String: Any], Error>) in
            request.start() { connection, result, error in
                if let error {
                    continuation.resume(throwing: error)
                }
                
                if let result = result as? [String: Any] {
                    continuation.resume(returning: result)
                }
            }
        })
        
        return result
    }
}


// MARK: -

typealias Page = Calendar

struct FacebookCalendarService: CalendarService {
    static var permissions: [String] {[
        "public_profile",
        "business_management",
        "pages_read_engagement",
        "pages_manage_posts",
        "business_management",
    ]}
        
    static func getCalendars() async -> [Calendar]? {
        do {
            let response = try await Request.pages.perform()
            guard let data = response["data"] as? [[String: Any]] else {
                Logger.api.error("getCalendars failure \(ApiError.parsing)")
                return nil
            }
            
            return FacebookCalendarMapper.mapCalendars(from: data)
        } catch {
            Logger.api.error("getCalendars failure \(error)")
            return nil
        }
    }
    
    static func getEvents(calendarId: String, since: Date, until: Date) async -> [CalendarEvent]? {
        let since = since.timeIntervalSince1970
        let until = until.timeIntervalSince1970
        
        do {
            let response = try await Request.events(calendarId, Int(since), Int(until)).perform()
            guard let eventsData = response["data"] as? [[String: Any]] else {
                Logger.api.error("getEvents failure \(ApiError.parsing)")
                return nil
            }
            
            return FacebookEventMapper.mapEvents(from: eventsData)
        } catch {
            Logger.api.error("getEvents failure \(error)")
            return nil
        }
    }
}

extension FacebookCalendarService {
        
    static func getPages() async -> [Page]? {
        await getCalendars()
    }
    
    static func createSummaryPost(pageId: String, summary: String, photoId: String?, scheduledDate: Date?) async -> Bool {
        do {
            let pageToken = try await getPageToken(pageId: pageId)
            let _ = try await Request.createSummaryPost(pageId, summary, photoId, scheduledDate).perform(token: pageToken)
            return true
        } catch {
            Logger.api.error("createSummaryPost failure \(error)")
            return false
        }
    }
    
    /// return photoId or nil on error
    static func uploadPhoto(pageId: String, photoURL: String, temporary: Bool) async -> String? {
        do {
            let pageToken = try await getPageToken(pageId: pageId)
            let response = try await Request.uploadPhoto(pageId, photoURL, temporary).perform(token: pageToken)
            
            return response["id"] as? String
        } catch {
            Logger.api.error("postSummaryPhoto failure \(error)")
            return nil
        }
    }
}

private extension FacebookCalendarService {
    
    static func getPageToken(pageId: String) async throws -> String {
        do {
            let response = try await Request.pageAccessToken(pageId).perform()
            guard let token = response["access_token"] as? String else {
                Logger.api.error("getPageToken failure \(ApiError.parsing)")
                throw ApiError.parsing
            }
            
            return token
        } catch {
            Logger.api.error("getPageToken failure \(error)")
            throw error
        }
    }
}
