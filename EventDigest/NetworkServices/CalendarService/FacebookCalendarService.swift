//
//  FacebookCalendarService.swift
//  EventDigest
//
//  Created by Alex Bumbu on 02.02.2023.
//

import Foundation
import FBSDKLoginKit
import OSLog

enum ApiError: Error {
    case missingToken
    case parsing
    case unknown
}

private enum Request {
    case pages
    case pageAccessToken(String)
    case events(String, Int, Int)
    case postTextSummary(String, String, Date)
    case postPhotoSummary(String, String, String, Date)
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
        case .postTextSummary(let pageId, _, _):
            return "\(pageId)/feed"
        case .postPhotoSummary(let pageId, _, _, _):
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
        case .postTextSummary(_, let message, let scheduledDate):
            let timeInterval = Int(scheduledDate.timeIntervalSince1970)
            return ["message": message, "published": false, "scheduled_publish_time": timeInterval]
        case .postPhotoSummary(_, let photoURL, let message, let scheduledDate):
            let timeInterval = Int(scheduledDate.timeIntervalSince1970)
            return ["url": photoURL, "name": message, "published": false, "scheduled_publish_time": timeInterval]
        }
    }
    
    var httpMethod: HTTPMethod {
        switch self {
        case .postTextSummary, .postPhotoSummary:
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
        "pages_read_engagement",
        "pages_manage_posts"
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
    
    static func postSummaryText(pageId: String, summary: String, scheduledDate: Date) async -> Bool {
        do {
            let pageToken = try await getPageToken(pageId: pageId)
            let _ = try await Request.postTextSummary(pageId, summary, scheduledDate).perform(token: pageToken)
        } catch {
            Logger.api.error("postTextSummary failure \(error)")
            return false
        }
        
        return true
    }
    
    static func postSummaryPhoto(pageId: String, photoURL: String, summary: String, scheduledDate: Date) async -> Bool {
        do {
            let pageToken = try await getPageToken(pageId: pageId)
            let _ = try await Request.postPhotoSummary(pageId, photoURL, summary, scheduledDate).perform(token: pageToken)
        } catch {
            Logger.api.error("postSummaryPhoto failure \(error)")
            return false
        }
        
        return true
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
