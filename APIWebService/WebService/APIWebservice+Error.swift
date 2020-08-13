//
//  APIWebservice+Error.swift
//  APIWebService
//
//  Created by Michael Dean Villanda on 8/13/20.
//  Copyright © 2020 Michael Dean Villanda. All rights reserved.
//

import Foundation
import RxSwift
import Alamofire

public enum APIWebserviceError: Error {
    case invalidURL
    case requestError
    case responseError(Error, code: Int, data: Data?)
    case parseError(Data)
    case noToken
    case apiError(String)
    
    public var errorMessage: String {
        switch self {
        case .apiError(let string):
            return "APIError: \(string)"
        case .requestError:
            return "RequestError"
        case .responseError(let err, let code, let data):
            var dataErrorString = ""
            if let apiData = data, let dataString = String(data: apiData, encoding: .utf8) {
               dataErrorString = dataString
            }
            return "\(err) code:\(code) data: \(dataErrorString)"
        case .parseError(let data):
            var dataErrorString = ""
            if let dataString = String(data: data, encoding: .utf8) {
               dataErrorString = dataString
            }
            return "Parse Error: \(dataErrorString)"
        case .noToken:
            return "No Token"
        case .invalidURL:
            return "Invalid URL"
        }
    }
}

public extension APIWebserviceError {
    static func errorModelFromError<E: Codable>(_ error: Error) -> E? {
        if let apiError = error as? APIWebserviceError {
            switch apiError {
            case .parseError(let dataError):
                return try? JSONDecoder().decode(E.self, from: dataError)
            case .responseError(_, _, let data):
                if let errorData = data {
                    return try? JSONDecoder().decode(E.self, from: errorData)
                }
                return nil
            default:
                return nil
            }
        }
        return nil
    }
}
