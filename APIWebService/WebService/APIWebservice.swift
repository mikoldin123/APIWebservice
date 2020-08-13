//
//  APIWebservice.swift
//  APIWebService
//
//  Created by Michael Dean Villanda on 8/13/20.
//  Copyright © 2020 Michael Dean Villanda. All rights reserved.
//

import Foundation
import RxSwift
import Alamofire

public enum APINetworkState {
    
    case idle
    case started
    case finished
    case error(Error)
}

public struct AlwaysSuccess: Codable {
    public init() {}
}

public struct StringDataResponse: Codable {
    public let message: String
}

public extension StringDataResponse {
    init(_ string: String) {
        message = string
    }
}

public enum ContentDataType {
    
    case form
    case multiPart
}

fileprivate struct APIWebserviceConstants {
    
    static let timeout: TimeInterval = 60 * 2
}
 
class APIRequest {
    
    static let shared = APIRequest();
    fileprivate let defaultConfig: URLSessionConfiguration = {
        let defConfig = URLSessionConfiguration.default
        defConfig.urlCache = nil
        defConfig.timeoutIntervalForRequest = APIWebserviceConstants.timeout
        defConfig.timeoutIntervalForResource = APIWebserviceConstants.timeout
        return defConfig
    }()

    fileprivate lazy var manager = Alamofire.Session(configuration: defaultConfig)
    
    func custom(config: URLSessionConfiguration = URLSessionConfiguration.default) {
        let configuration = config
        configuration.urlCache = nil
        configuration.timeoutIntervalForRequest = APIWebserviceConstants.timeout
        configuration.timeoutIntervalForResource = APIWebserviceConstants.timeout
        manager = Alamofire.Session(configuration: configuration)
    }
}

public protocol APIWebservice {
    
    var baseURL: String { get }
    var endpoint: String { get }
    var requestURL: URL? { get }
    
    var headers: HTTPHeaders? { get }
    var parameters: [String: Any]? { get }
    
    var method: HTTPMethod { get }
    var contentType: ContentDataType { get }
    var encoding: ParameterEncoding { get }
    
    var interceptor: RequestInterceptor? { get }
    var modifier: Session.RequestModifier? { get }
    
    func request<T: Codable>() -> Single<T>
}

public extension APIWebservice {
    
    var requestURL: URL? {
        return URL(string: "\(self.baseURL)\(self.endpoint)")
    }
    
    var headers: HTTPHeaders? {
        return nil
    }
    
    var contentType: ContentDataType {
        return ContentDataType.form
    }
    
    var encoding: ParameterEncoding {
        return JSONEncoding.default
    }
    
    var interceptor: RequestInterceptor? {
        return nil
    }

    var modifier: Session.RequestModifier? {
        return nil
    }
    
    func request<T: Codable>() -> Single<T> {
        
        return Single<T>.create { single -> Disposable in
            
            guard let url = self.requestURL else {
                single(.error(APIWebserviceError.invalidURL))
                return Disposables.create()
            }
             
            let manager = APIRequest.shared.manager
            
            var encoding: ParameterEncoding = self.encoding
            switch self.method {
            case .get:
                encoding = URLEncoding.default
            default:
                break
            }
            
            if self.contentType == .multiPart {

                manager
                    .upload(multipartFormData: { multipartData in
                        let reqParams = self.parameters ?? [:]
                        reqParams.forEach { (key, value) in
                            if let data = "\(value)".data(using: .utf8) {
                                multipartData.append(data, withName: key)
                            }
                        }
                    }, to: url,
                       usingThreshold: UInt64.init(),
                       method: self.method,
                       headers: self.headers,
                       interceptor: self.interceptor,
                       fileManager: .default,
                       requestModifier: self.modifier)
                    .response { (result) in
                        
                        if
                            let response = result.data,
                            let model: T = try? JSONDecoder().decode(T.self, from: response) {
                            
                            single(.success(model))
                        } else {
                            guard let uData = result.data, let strData = String(data: uData, encoding: String.Encoding.utf8) else {
                                single(.error(APIWebserviceError.requestError))
                                return
                            }
                            
                            let message = StringDataResponse(strData)
      
                            if T.self is StringDataResponse.Type, let msg = message as? T {
                                single(.success(msg))
                            } else {
                                print("error request")
                                single(.error(APIWebserviceError.requestError))
                            }
                        }
                }
                
                return Disposables.create()
            }
            
            let dataRequest = manager.request(url,
                                              method: self.method,
                                              parameters: self.parameters,
                                              encoding: encoding,
                                              headers: self.headers,
                                              interceptor: self.interceptor,
                                              requestModifier: self.modifier)
            
            if self.interceptor != nil {
                dataRequest.validate()
            }
            
            dataRequest.responseData { result in
                if let dataError = result.error {
                    
                    guard let errorData = result.data else {
                        single(.error(APIWebserviceError.responseError(dataError, code: result.response?.statusCode ?? 0, data: nil)))
                        return
                    }
                    
                    single(.error(APIWebserviceError.responseError(dataError, code: result.response?.statusCode ?? 0, data: errorData)))
                    
                } else if let response = result.data {
                    
                    do {
                        
                        let emptyModel = AlwaysSuccess()
                        
                        if T.self is AlwaysSuccess.Type, let empty = emptyModel as? T {
                            single(.success(empty))
                            return
                        }
                        
                        let decoder = JSONDecoder()
                        
                        let model: T = try decoder.decode(T.self, from: response)
                        single(.success(model))
                        
                    } catch {
                        
                        if let strData = String(data: response, encoding: String.Encoding.utf8) {
                            print("ERROR: \(strData)")
                        }
                        
                        single(.error(APIWebserviceError.parseError(response)))
                    }
                } else {
                    single(.error(APIWebserviceError.requestError))
                }
            }
            
            return Disposables.create {
                dataRequest.cancel()
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
        .observeOn(MainScheduler.asyncInstance)
    }
}
