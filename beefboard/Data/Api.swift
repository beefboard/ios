//
//  Api.swift
//  beefboard
//
//  Created by Oliver on 31/10/2018.
//  Copyright © 2018 Oliver Bell. All rights reserved.
//

import Foundation
import AwaitKit
import PromiseKit
import Alamofire

struct PostVotes: Decodable {
    let grade: Int
    let user: Int?
    
    public init(grade: Int, user: Int?) {
        self.grade = grade
        self.user = user
    }
}

struct Post: Decodable {
    let id: String
    let title: String
    let content: String
    let author: String
    let date: Date
    let numImages: Int
    let approved: Bool
    let pinned: Bool
    let votes: PostVotes
    
    public init(
        id: String,
        title: String,
        content: String,
        author: String,
        date: Date,
        numImages: Int,
        approved: Bool,
        pinned: Bool,
        votes: PostVotes
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.author = author
        self.date = date
        self.numImages = numImages
        self.approved = approved
        self.pinned = pinned
        self.votes = votes
    }
}

struct PostsList: Decodable {
    let posts: [Post]
}

struct User: Codable {
    let username: String
    let firstName: String
    let lastName: String
    let admin: Bool
    let email: String
}

enum ApiError: Error {
    case unknownError
    case connectionError
    case invalidCredentials
    case invalidRequest
    case notFound
    case invalidResponse
    case serverError
    case serverUnavailable
    case timeOut
    case unsuppotedURL
}

enum DateError: String, Error {
    case invalidDate
}

extension Formatter {
    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}

class BeefboardApi {
    private static let TOKEN_KEY = "token"
    private static let TOKEN_HEADER = "x-access-token"
    private static let BEEFBOARD_API_HOST = "https://api.beefboard.mooo.com/v1"
    
    private static func getToken() -> String? {
        return UserDefaults.standard.string(forKey: BeefboardApi.TOKEN_KEY)
    }
    
    private static func setToken(token: String) {
        UserDefaults.standard.set(token, forKey: BeefboardApi.TOKEN_KEY)
    }
    
    public static func hasToken() -> Bool {
        return self.getToken() != nil
    }
    
    private static func clearToken() {
        UserDefaults.standard.set(nil, forKey: BeefboardApi.TOKEN_KEY)
    }
    
    private static func buildUrl(to path: String) -> String {
        return BeefboardApi.BEEFBOARD_API_HOST + path
    }
    
    private static func buildHeaders() -> HTTPHeaders {
        if let token = getToken() {
            return [BeefboardApi.TOKEN_HEADER: token]
        }
        
        return [:]
    }
    
    private static func checkErrorCode(_ errorCode: Int) -> ApiError {
        switch errorCode {
        case 400:
            return .invalidRequest
        case 401:
            return .invalidCredentials
        case 404:
            return .notFound
        default:
            return .unknownError
        }
    }
    
    public static func getImageUrl(forPost postId: String, forImage imageId: Int) -> String {
        return "\(BeefboardApi.BEEFBOARD_API_HOST)/posts/\(postId)/images/\(imageId)"
    }
    
    public static func login(username: String, password: String) -> Promise<Bool> {
        self.clearToken()
        let request = Alamofire.request(
            buildUrl(to: "/me"),
            method: .put,
            parameters: ["username": username, "password": password],
            encoding: JSONEncoding.default,
            headers: buildHeaders()
        )
        request.session.configuration.timeoutIntervalForRequest = 1
        
        return Promise{ seal in
            request
                .validate()
                .responseJSON{ response in
                    switch response.result {
                    case .success(let json):
                        guard let json = json as? [String: Any] else {
                            return seal.reject(ApiError.invalidResponse)
                        }
                        guard let token = json["token"] as? String else {
                            return seal.reject(ApiError.invalidResponse)
                        }
                        self.setToken(token: token)
                        return seal.fulfill(true)
                    case .failure(let error as AFError):
                        if let code = error.responseCode {
                            return seal.reject(self.checkErrorCode(code))
                        }
                        return seal.reject(error)
                    case .failure:
                        return seal.reject(ApiError.connectionError)
                    }
                }
        }
    }
    
    public static func logout() -> Promise<Void> {
        if !self.hasToken() {
            return Promise{ seal in
                seal.fulfill(())
            }
        }
        
        let request = Alamofire.request(
            buildUrl(to: "/me"),
            method: .delete,
            encoding: JSONEncoding.default,
            headers: buildHeaders()
        )
        request.session.configuration.timeoutIntervalForRequest = 1
        
        return Promise{ seal in
            request
                .validate()
                .responseJSON{ response in
                    self.clearToken()
                    return seal.fulfill(())
            }
        }
    }
    
    public static func getUser(username: String) -> Promise<User?> {        
        let request = Alamofire.request(
            buildUrl(to: "/accounts/" + username),
            encoding: JSONEncoding.default,
            headers: buildHeaders()
        )
        request.session.configuration.timeoutIntervalForRequest = 1
        
        return Promise{ seal in
            request
                .validate()
                .responseData{ response in
                    switch response.result {
                    case .success(let data):
                        var auth: User? = nil
                        do {
                            auth = try JSONDecoder().decode(User.self, from: data)
                        } catch (let e) {
                            print(e)
                            return seal.reject(ApiError.invalidResponse)
                        }
                        
                        return seal.fulfill(auth!)
                    case .failure(let error as AFError):
                        if let code = error.responseCode {
                            return seal.reject(self.checkErrorCode(code))
                        }
                        return seal.reject(error)
                    case .failure:
                        return seal.reject(ApiError.connectionError)
                    }
            }
        }
    }
    
    public static func getAuth() -> Promise<User?> {
        if !self.hasToken() {
            return Promise{ seal in
                seal.reject(ApiError.invalidCredentials)
            }
        }
        
        let request = Alamofire.request(
            buildUrl(to: "/me"),
            encoding: JSONEncoding.default,
            headers: buildHeaders()
        )
        request.session.configuration.timeoutIntervalForRequest = 1
        
        return Promise{ seal in
            request
                .validate()
                .responseData{ response in
                    switch response.result {
                    case .success(let data):
                        var auth: User? = nil
                        do {
                            auth = try JSONDecoder().decode(User.self, from: data)
                        } catch (let e) {
                            print(e)
                            return seal.reject(ApiError.invalidResponse)
                        }
                        
                        return seal.fulfill(auth!)
                    case .failure(let error as AFError):
                        if let code = error.responseCode {
                            return seal.reject(self.checkErrorCode(code))
                        }
                        return seal.reject(error)
                    case .failure:
                        return seal.reject(ApiError.connectionError)
                    }
            }
        }
    }
    
    public static func getPosts() -> Promise<[Post]> {
        let request = Alamofire.request(
            buildUrl(to: "/posts"),
            encoding: JSONEncoding.default,
            headers: buildHeaders()
        )
        request.session.configuration.timeoutIntervalForRequest = 1
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom({ (decoder) -> Date in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .iso8601)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
            if let date = formatter.date(from: dateStr) {
                return date
            }
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
            if let date = formatter.date(from: dateStr) {
                return date
            }
            throw DateError.invalidDate
        })
        
        return Promise{ seal in
            request
                .validate()
                .responseData{ response in
                    switch response.result {
                    case .success(let data):
                        var postsList: PostsList? = nil
                        do {
                            
                            postsList = try decoder.decode(PostsList.self, from: data)
                        } catch (let e) {
                            print(e)
                            return seal.reject(ApiError.invalidResponse)
                        }
                        
                        return seal.fulfill(postsList!.posts)
                    case .failure(let error as AFError):
                        if let code = error.responseCode {
                            return seal.reject(self.checkErrorCode(code))
                        }
                        return seal.reject(error)
                    case .failure:
                        return seal.reject(ApiError.connectionError)
                    }
            }
        }
    }
    
    public static func register(
        username: String,
        password: String,
        email: String,
        firstName: String,
        lastName: String
    ) -> Promise<Bool> {
        
        let request = Alamofire.request(
            buildUrl(to: "/accounts"),
            method: .post,
            parameters: [
                "username": username,
                "password": password,
                "email": email,
                "firstName": firstName,
                "lastName": lastName
            ],
            encoding: JSONEncoding.default,
            headers: buildHeaders()
        )
        
        request.session.configuration.timeoutIntervalForRequest = 1
        
        return Promise{ seal in
            request
                .validate()
                .responseJSON{ response in
                    switch response.result {
                    case .success(let json):
                        guard let json = json as? [String: Any] else {
                            return seal.reject(ApiError.invalidResponse)
                        }
                        guard let success = json["success"] as? Bool else {
                            return seal.reject(ApiError.invalidResponse)
                        }
                        
                        seal.fulfill(success)
                    case .failure(let error as AFError):
                        if let code = error.responseCode {
                            return seal.reject(self.checkErrorCode(code))
                        }
                        return seal.reject(error)
                    case .failure:
                        return seal.reject(ApiError.connectionError)
                    }
            }
        }
    }
}
