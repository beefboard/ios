//
//  RegistrationModel.swift
//  beefboard
//
//  Created by Oliver on 28/11/2018.
//  Copyright © 2018 Oliver Bell. All rights reserved.
//

import Foundation
import AwaitKit

protocol RegistrationModelDelegate: class {
    func didRegister(username: String, password: String)
    func didReceiveEmailValid(valid: Bool)
    func didReceivePasswordsValid(valid: Bool)
    func didRecieveRegistrationError(error: ApiError)
}

/**
 * Registration handling for all views which require
 * account registration methods
 */
class RegistrationModel {
    // Matcher for valid emails
    private static let EMAIL_TEST = NSPredicate(
        format:"SELF MATCHES %@",
        "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    )
    
    weak var delegate: RegistrationModelDelegate?
    
    /**
     * Check the given email address for validness.
     *
     * Broadcasts didReceiveEmailValid when check has
     * finished
     */
    func checkEmail(email: String) {
        DispatchQueue.main.async {
            // Use the REGEX to check for validitiy
            self.delegate?.didReceiveEmailValid(valid: RegistrationModel.EMAIL_TEST.evaluate(with: email))
        }
    }
    
    /**
     * Check to see if the given passwords match
     *
     * Broadcasts didReceivePasswordsValid when successful
     */
    func checkPasswords(password: String, password2: String) {
        DispatchQueue.main.async {
            self.delegate?.didReceivePasswordsValid(valid: password == password2)
        }
    }
    
    /**
     * Attempt registration with the given details
     *
     * Broadcasts didRegister with username and password
     * upon success and didRecieveRegistrationError on
     * Registration failure
     */
    func register(
        username: String,
        password: String,
        email: String,
        firstName: String,
        lastName: String
    ) {
        async {
            do {
                // Try to register
                try await(
                    BeefboardApi.register(
                        username: username,
                        password: password,
                        email: email,
                        firstName: firstName,
                        lastName: lastName
                    )
                )
            } catch (let error as ApiError) {
                // Catch and broadcast errors
                DispatchQueue.main.async {
                    self.delegate?.didRecieveRegistrationError(error: error)
                }
                return
            }
            
            DispatchQueue.main.async {
                self.delegate?.didRegister(username: username, password: password)
            }
        }
    }
}
