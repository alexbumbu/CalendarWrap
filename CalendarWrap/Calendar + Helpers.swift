//
//  Calendar + Helpers.swift
//  CalendarWrap
//
//  Created by Alex Bumbu on 03.08.2024.
//

import Foundation

extension Calendar {
    
    func endOfDay(for date: Date) -> Date {
        var components = dateComponents(in: TimeZone.current, from: date)
        components.hour = 23
        components.minute = 59
        components.second = 0
        
        return components.date!
    }
    
    func datesInInterval(_ interval: DateInterval) -> [Date] {
        var dates = [Date]()
        var currentDate = interval.start
        
        while currentDate <= interval.end {
            dates.append(currentDate)
            
            // move to the next day
            guard let nextDate = date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            
            currentDate = startOfDay(for: nextDate)
        }
        
        return dates
    }
}
