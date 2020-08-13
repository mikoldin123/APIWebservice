//
//  ItunesWebservices.swift
//  APIWebService
//
//  Created by Michael Dean Villanda on 8/13/20.
//  Copyright © 2020 Michael Dean Villanda. All rights reserved.
//

import Foundation
import Alamofire

enum ItunesWebservice: APIWebservice {
    case search(offset: Int)
    
    var baseURL: String {
        return "https://itunes.apple.com"
    }
    
    var endpoint: String {
        switch self {
        case .search:
            return "/search"
        }
    }
    
    var parameters: [String : Any]? {
        switch self {
        case .search(let offset):
            var dictParams: [String: Any] = ["term": "star", "country": "au", "media": "movie", "limit": 20]
            if offset > 0 {
                dictParams["offset"] = offset
            }
            return dictParams
        }
    }
    
    var method: HTTPMethod {
        return HTTPMethod.get
    }
}
