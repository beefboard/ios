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

/**
 * Object representing the current
 * votes on a post
 */
struct PostVotes: Decodable {
    let grade: Int
    let user: Int?
    
    public init(grade: Int, user: Int?) {
        self.grade = grade
        self.user = user
    }
}

/**
 * Object representing a Post
 * with details stored in server
 */
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

/**
 * Representation of JSON structure
 * containing posts. Used for decoding
 */
private struct PostsList: Decodable {
    let posts: [Post]
}

/**
 * Object containing profile details
 */
struct User: Codable {
    let username: String
    let firstName: String
    let lastName: String
    let admin: Bool
    let email: String
}

/**
 * Categories of API ommited
 * by API
 */
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

/**
 * Extend formatter to allow for Javascript ISO8601
 * strings to be decodeded
 */
extension Formatter {
    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}

/**
 * Public interface to the beefboard API.
 *
 * Stores access token and handles automatic access token
 * injection to all requests
 */
class BeefboardApi {
    private static let TOKEN_KEY = "token"
    private static let TOKEN_HEADER = "x-access-token"
    private static let BEEFBOARD_API_HOST = "https://api.beefboard.mooo.com/v1"
    //private static let BEEFBOARD_API_HOST = "http://localhost:2832/v1"
    
    private static let TIMEOUT = 3.0
    
    // MARK: - Token storage handling
    
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
    
    // MARK: - Request builders
    
    private static func buildUrl(to path: String) -> String {
        return BeefboardApi.BEEFBOARD_API_HOST + path
    }
    
    private static func buildHeaders() -> HTTPHeaders {
        // Add a token to the headers only if we have a token
        if let token = getToken() {
            return [BeefboardApi.TOKEN_HEADER: token]
        }
        
        return [:]
    }
    
    // MARK: - Error handlers
    
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
    
    // MARK: - API
    
    /**
     * Build the static image url for the
     * given image parameters
     */
    public static func getImageUrl(forPost postId: String, forImage imageId: Int) -> String {
        return "\(BeefboardApi.BEEFBOARD_API_HOST)/posts/\(postId)/images/\(imageId)"
    }
    
    /**
     * Login to the API with the given creds.
     *
     * Success will store the token automatically
     */
    public static func login(username: String, password: String) -> Promise<Bool> {
        self.clearToken()
        let request = Alamofire.request(
            buildUrl(to: "/me"),
            method: .put,
            parameters: ["username": username, "password": password],
            encoding: JSONEncoding.default,
            headers: buildHeaders()
        )
        request.session.configuration.timeoutIntervalForRequest = TIMEOUT
        
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
    
    /**
     * Logout of the API and remove our token.
     *
     * Always successful
     */
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
        request.session.configuration.timeoutIntervalForRequest = TIMEOUT
        
        return Promise{ seal in
            request
                .validate()
                .responseJSON{ response in
                    self.clearToken()
                    return seal.fulfill(())
            }
        }
    }
    
    /**
     * Get the given user details
     */
    public static func getUser(username: String) -> Promise<User?> {        
        let request = Alamofire.request(
            buildUrl(to: "/accounts/" + username),
            encoding: JSONEncoding.default,
            headers: buildHeaders()
        )
        request.session.configuration.timeoutIntervalForRequest = TIMEOUT
        
        return Promise{ seal in
            request
                .validate()
                .responseData{ response in
                    switch response.result {
                    case .success(let data):
                        var auth: User? = nil
                        do {
                            auth = try JSONDecoder().decode(User.self, from: data)
                        } catch (_) {
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
    
    /**
     * Get our current auth access rights. Requires login
     */
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
        request.session.configuration.timeoutIntervalForRequest = TIMEOUT
        
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
    
    /**
     * Get a list of posts for the homepage
     */
    public static func getPosts() -> Promise<[Post]> {
        let request = Alamofire.request(
            buildUrl(to: "/posts"),
            encoding: JSONEncoding.default,
            headers: buildHeaders()
        )
        request.session.configuration.timeoutIntervalForRequest = TIMEOUT
        
        // Create a decoder to decode the datetime stamps
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
    
    /**
     * Get data about the given post ID.
     *
     * If logged in, this will allow admins to see all posts,
     * and authors to see their unapproved posts
     */
    public static func getPost(id: String) -> Promise<Post> {
        let request = Alamofire.request(
            buildUrl(to: "/posts/\(id)"),
            encoding: JSONEncoding.default,
            headers: buildHeaders()
        )
        request.session.configuration.timeoutIntervalForRequest = TIMEOUT
        
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
                        do {
                            let post = try decoder.decode(Post.self, from: data)
                            return seal.fulfill(post)
                        } catch (let e) {
                            print(e)
                            return seal.reject(ApiError.invalidResponse)
                        }
                        
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
    
    /**
     * Make a registration request to
     * the API with the given details
     */
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
        
        request.session.configuration.timeoutIntervalForRequest = TIMEOUT
        
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
    
    /**
     * Make a new post request to the API
     *
     * Requires login
     */
    public static func newPost(
        title: String,
        content: String,
        images: [UIImage],
        progressHandler: @escaping (Double) -> ()
    ) -> Promise<String> {
        
        var headers = self.buildHeaders()
        headers["Content-type"] = "multipart/form-data"
        
        return Promise{ seal in
            // Build the request using Multipart form data, and add
            // the images in JPEG format to the form.
            Alamofire.upload(
                multipartFormData: { (multipartFormData) in
                    for image in images {
                        let imgData = image.jpegData(compressionQuality: 0.5)!
                        multipartFormData.append(imgData, withName: "images", fileName: "test.jpg", mimeType: "image/jpeg")
                    }
                    
                    multipartFormData.append(title.data(using: .utf8)!, withName: "title")
                    multipartFormData.append(content.data(using: .utf8)!, withName: "content")
                },
                usingThreshold: UInt64.init(),
                to: self.buildUrl(to: "/posts"),
                method: .post,
                headers: headers,
                encodingCompletion: { encodingResult in
                    switch encodingResult {
                    case .success(let upload, _, _):
                        upload.responseJSON { response in
                            switch response.result {
                            case .success(let json):
                                guard let json = json as? [String: Any] else {
                                    return seal.reject(ApiError.invalidResponse)
                                }
                                guard let postId = json["id"] as? String else {
                                    return seal.reject(ApiError.invalidResponse)
                                }
                            
                                seal.fulfill(postId)
                            case .failure(let error as AFError):
                                if let code = error.responseCode {
                                    return seal.reject(self.checkErrorCode(code))
                                }
                                return seal.reject(error)
                            case .failure:
                                return seal.reject(ApiError.connectionError)
                            }
                        }
                        upload.uploadProgress { progress in
                            progressHandler(progress.fractionCompleted)
                        }
                    case .failure(let error as AFError):
                        if let code = error.responseCode {
                            return seal.reject(self.checkErrorCode(code))
                        }
                        return seal.reject(error)
                    case .failure:
                        return seal.reject(ApiError.connectionError)
                    }
                }
            )
        }
    }
    
    /**
     * Set the pinned value of a post
     *
     * Requires a
     */
    public static func setPostPin(id: String, pinned: Bool) -> Promise<Bool> {
        let request = Alamofire.request(
            buildUrl(to: "/posts/\(id)"),
            method: .put,
            parameters: ["pinned": pinned],
            encoding: JSONEncoding.default,
            headers: buildHeaders()
        )
        request.session.configuration.timeoutIntervalForRequest = TIMEOUT
        
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
}
