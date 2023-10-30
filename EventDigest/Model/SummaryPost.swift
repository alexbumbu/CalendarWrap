//
//  SummaryPost.swift
//  EventDigest
//
//  Created by Alex Bumbu on 03.02.2023.
//

import Foundation

struct SummaryPost {
    var imageURL: URL?
    var events: [CalendarEvent]? {
        didSet {
            events?.sort { $0.startTime.compare($1.startTime) == .orderedAscending }
        }
    }
    
    func summary(introText: String = "", endText: String = "") -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMM d"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "ha"
        
        var lastDateHeader = ""
        let summary = events?.reduce(into: "") { partialResult, event in
            let dateHeader = dateFormatter.string(from: event.startTime) + event.startTime.daySuffix() + ":"
            if dateHeader != lastDateHeader {
                partialResult.append("\(dateHeader)\n\n")
                lastDateHeader = dateHeader
            }
            
            let location = event.location != nil ? "at \(event.location!)" : "location N/A"
            let startTime = timeFormatter.string(from: event.startTime)
            let eventSummary = "\(event.name), \(event.isOnline ? "online" : location),🕒 \(startTime)\n\n"
            partialResult.append(eventSummary)
        } ?? ""
                
        return "\(introText)\n\(summary)\n\(endText)\n"
    }
}

// MARK: -

extension Date {
    
    func daySuffix() -> String {
        Foundation.Calendar.current.component(.day, from: self).ordinalSuffix()
    }
}

extension Int {
    
    func ordinalSuffix() -> String {
        let suffixes = ["th", "st", "nd", "rd", "th", "th", "th", "th", "th", "th"]
        let value = self % 100
        let ordinalSuffix: String
        if value >= 11 && value <= 13 {
            ordinalSuffix = "th"
        } else {
            ordinalSuffix = suffixes[value % 10]
        }
        return ordinalSuffix
    }
}
