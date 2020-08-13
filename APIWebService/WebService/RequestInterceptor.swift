//
//  RequestInterceptor.swift
//  APIWebService
//
//  Created by Michael Dean Villanda on 8/13/20.
//  Copyright © 2020 Michael Dean Villanda. All rights reserved.
//

import Foundation
import Alamofire

class Interceptor: RequestInterceptor {
    var isRefreshing: Bool = false
    
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var request = urlRequest
        
        // TODO: Add update header tokens here
        /*
         if let token = validToken {
             request.headers.update(name: "header-name", value: token)
         }
         */
        completion(.success(request))
    }
    
    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        
        guard let statusCode = request.response?.statusCode else {
            completion(.doNotRetry)
            return
        }
        
        switch statusCode {
        case 401, 498:
            self.refreshToken { (flag) in
                /// Update tokens
                completion(.retry)
            }
        default:
            completion(.doNotRetry)
        }
    }
    
    func refreshToken(_ completion: @escaping (Bool) -> Void) {
        guard !isRefreshing else { return }
        
        isRefreshing = true
        
        // TODO: Add refresh token call here then call below
        
        completion(true)
        isRefreshing = false
    }
}
