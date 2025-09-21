//
//  NetworkService.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import Foundation
import Combine

protocol NetworkServiceProtocol {
    func request<T: Codable>(
        _ endpoint: Endpoint,
        responseType: T.Type
    ) -> AnyPublisher<T, NetworkError>
}

class NetworkService: NetworkServiceProtocol {
    private let session: URLSession
    private let baseURL: URL
    private let decoder: JSONDecoder
    
    init(session: URLSession = .shared, baseURL: URL) {
        self.session = session
        self.baseURL = baseURL
        self.decoder = JSONDecoder()
        
        // Configure decoder with common strategies
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    // Convenience initializer allowing proxy bypass
    convenience init(baseURL: URL, disableSystemProxies: Bool) {
        if disableSystemProxies {
            let configuration = URLSessionConfiguration.default
            configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
            configuration.timeoutIntervalForRequest = 30
            configuration.timeoutIntervalForResource = 60
            configuration.waitsForConnectivity = true
            configuration.allowsConstrainedNetworkAccess = true
            configuration.allowsExpensiveNetworkAccess = true
            // Disable usage of system HTTP/HTTPS proxies (e.g., 127.0.0.1:9090)
            configuration.connectionProxyDictionary = [:]
            let session = URLSession(configuration: configuration)
            self.init(session: session, baseURL: baseURL)
        } else {
            self.init(session: .shared, baseURL: baseURL)
        }
    }
    
    func request<T: Codable>(
        _ endpoint: Endpoint,
        responseType: T.Type
    ) -> AnyPublisher<T, NetworkError> {
        guard let urlRequest = endpoint.urlRequest(baseURL: baseURL) else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: urlRequest)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.serverError
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    return data
                case 401:
                    throw NetworkError.unauthorized
                case 403:
                    throw NetworkError.forbidden
                case 404:
                    throw NetworkError.notFound
                case 500...599:
                    throw NetworkError.serverError
                default:
                    throw NetworkError.serverError
                }
            }
            .decode(type: T.self, decoder: decoder)
            .mapError { error -> NetworkError in
                if let networkError = error as? NetworkError {
                    return networkError
                } else if error is DecodingError {
                    return NetworkError.decodingFailed
                } else if let urlError = error as? URLError {
                    switch urlError.code {
                    case .timedOut:
                        return NetworkError.timeout
                    case .notConnectedToInternet, .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed, .networkConnectionLost:
                        return NetworkError.networkUnavailable
                    default:
                        return NetworkError.networkUnavailable
                    }
                } else {
                    return NetworkError.networkUnavailable
                }
            }
            .eraseToAnyPublisher()
    }
}