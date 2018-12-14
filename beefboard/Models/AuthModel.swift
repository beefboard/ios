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

/**
 * AuthModel, handling auth for all views which
 * require anything to do with credentials or login
 */
class AuthModel {
    weak var delegate: AuthModelDelegate?
    
    private static let USER_AUTH_KEY = "user_auth"
    private var currentAuth: User?
    
    init() {
        self.loadCurrentAuth()
    }
    
    /**
     * Attempt to retrieve our current auth access.
     *
     * A local cached auth will first be broadcast if
     * it exists, where we then try to refresh those
     * details.
     *
     * Broadcasts didReceiveAuth when auth is retrieved
     */
    func retrieveAuth()  {
        if self.currentAuth != nil {
            self.delegate?.didReceiveAuth(auth: self.currentAuth)
        }
        
        async {
            do {
                self.currentAuth = try await(BeefboardApi.getAuth())
            } catch (ApiError.invalidCredentials) {
                self.currentAuth = nil
            } catch {}
            
            self.saveAuth()
            
            DispatchQueue.main.async {
                self.delegate?.didReceiveAuth(auth: self.currentAuth)
            }
        }
    }
    
    /**
     * Attempt to login with credentials. Will store
     * Auth on success and broadcast didReceiveAuth
     *
     * Will broadcast failure, when login fails
     */
    func login(username: String, password: String) {
        async {
            do {
                try await(BeefboardApi.login(username: username, password: password))
                self.retrieveAuth()
            } catch let error as ApiError {
                DispatchQueue.main.async {
                    self.delegate?.didReceiveAuthError(error: error)
                }
            }
        }
    }
    
    /**
     * Attempt logout, and remove cached auth details
     *
     * Broadcasts null from didReceiveAuth when finished
     */
    func logout() {
        async {
            do {
                try await(BeefboardApi.logout())
            } catch {}
            
            self.currentAuth = nil;
            self.saveAuth()
            
            DispatchQueue.main.async {
                self.delegate?.didReceiveAuth(auth: self.currentAuth)
            }
        }
    }
    
    // MARK: - Cache management
    
    private func loadCurrentAuth() {
        // Attempt to load auth details from Userdefaults
        // and decode
        if let userAuthJsonString = UserDefaults.standard.string(forKey: AuthModel.USER_AUTH_KEY) {
            if let userAuthJson = userAuthJsonString.data(using: String.Encoding.utf8, allowLossyConversion: false) {
                self.currentAuth = try? JSONDecoder().decode(User.self, from: userAuthJson)
            }
        } else {
            self.currentAuth = nil
        }
    }
    
    private func saveAuth() {
        // Attempt to save our current auth details to
        // Userdefaults
        if let auth = self.currentAuth {
            if let jsonData = try? JSONEncoder().encode(auth) {
                let jsonString = String(decoding: jsonData, as: UTF8.self)
                UserDefaults.standard.setValue(jsonString, forKey: AuthModel.USER_AUTH_KEY)
            }
        } else {
            UserDefaults.standard.setValue(nil, forKey: AuthModel.USER_AUTH_KEY)
        }
    }
}
