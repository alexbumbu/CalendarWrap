//
//  Logger.swift
//  EventDigest
//
//  Created by Alex Bumbu on 03.02.2023.
//

import Foundation
import OSLog

extension Logger {
    
    private static var subsystem = Bundle.main.bundleIdentifier!
    
    static let api = Logger(subsystem: subsystem, category: "API")
}
