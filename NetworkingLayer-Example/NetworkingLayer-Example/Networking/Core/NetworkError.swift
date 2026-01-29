//
//  NetworkError.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import Foundation

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingFailed
    case serverError
    case networkUnavailable
    case unauthorized
    case forbidden
    case notFound
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingFailed:
            return "Failed to decode response"
        case .serverError:
            return "Server error occurred"
        case .networkUnavailable:
            return "Network unavailable"
        case .unauthorized:
            return "Unauthorized access"
        case .forbidden:
            return "Access forbidden"
        case .notFound:
            return "Resource not found"
        case .timeout:
            return "Request timeout"
        }
    }
}