//
//  AuthModel.swift
//  beefboard
//
//  Created by Oliver on 27/11/2018.
//  Copyright © 2018 Oliver Bell. All rights reserved.
//

import Foundation
import PromiseKit
import AwaitKit

protocol AuthModelDelegate: class {
    func didReceiveAuth(auth: User?)
    func didReceiveAuthError(error: ApiError)
}


class AuthModel {
    weak var delegate: AuthModelDelegate?
    
    private static let USER_AUTH_KEY = "user_auth"
    private var currentAuth: User?
    
    init() {
        self.loadCurrentAuth()
    }
    
    @discardableResult
    func retrieveAuth() -> Promise<Void> {
        if self.currentAuth != nil {
            self.delegate?.didReceiveAuth(auth: self.currentAuth)
        }
        
        return async {
            print("Recieving auth")
            do {
                self.currentAuth = try await(BeefboardApi.getAuth())
            } catch is ApiError {
                self.currentAuth = nil
            }
            
            self.saveAuth()
            
            DispatchQueue.main.async {
                self.delegate?.didReceiveAuth(auth: self.currentAuth)
            }
        }
    }
    
    func login(username: String, password: String) {
        async {
            do {
                try await(BeefboardApi.login(username: username, password: password))
                try await(self.retrieveAuth())
            } catch let error as ApiError {
                DispatchQueue.main.async {
                    self.delegate?.didReceiveAuthError(error: error)
                }
            }
        }
    }
    
    func logout() {
        async {
            do {
                try await(BeefboardApi.logout())
            } catch {}
            
            print("Has token: \(BeefboardApi.hasToken())")
            
            self.currentAuth = nil;
            self.saveAuth()
            
            DispatchQueue.main.async {
                self.delegate?.didReceiveAuth(auth: self.currentAuth)
            }
        }
    }
    
    private func loadCurrentAuth() {
        print("Loading auth")
        if let userAuthJsonString = UserDefaults.standard.string(forKey: AuthModel.USER_AUTH_KEY) {
            if let userAuthJson = userAuthJsonString.data(using: String.Encoding.utf8, allowLossyConversion: false) {
                print("Got auth")
                self.currentAuth = try? JSONDecoder().decode(User.self, from: userAuthJson)
            }
        } else {
            print("Got null")
            self.currentAuth = nil
        }
    }
    
    private func saveAuth() {
        if let auth = self.currentAuth {
            if let jsonData = try? JSONEncoder().encode(auth) {
                let jsonString = String(decoding: jsonData, as: UTF8.self)
                UserDefaults.standard.setValue(jsonString, forKey: AuthModel.USER_AUTH_KEY)
            }
        } else {
            print("Saving auth as nothing")
            UserDefaults.standard.setValue(nil, forKey: AuthModel.USER_AUTH_KEY)
        }
    }
}
