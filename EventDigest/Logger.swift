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
    
    #if DEBUG
    static let debug = Logger(subsystem: subsystem, category: "DEBUG")
    #endif
    
    static let api = Logger(subsystem: subsystem, category: "API")
    static let ui = Logger(subsystem: subsystem, category: "UI")
}
