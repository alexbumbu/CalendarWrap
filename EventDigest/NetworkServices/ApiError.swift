//
//  ApiError.swift
//  EventDigest
//
//  Created by Alex Bumbu on 09.03.2024.
//

import Foundation

enum ApiError: Error {
    case missingToken
    case invalidResponse
    case parsing
    case unknown
}
