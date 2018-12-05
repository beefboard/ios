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
    func didReceiveUsernameInfo(taken: Bool)
    func didReceiveEmailValid(valid: Bool)
    func didReceivePasswordsValid(valid: Bool)
    func didRecieveRegistrationError(error: ApiError)
}

class RegistrationModel {
    private static let EMAIL_TEST = NSPredicate(
        format:"SELF MATCHES %@",
        "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    )
    
    weak var delegate: RegistrationModelDelegate?
    
    func checkUsername(username: String) {
        async {
            var details: User? = nil
            do {
                details = try await(BeefboardApi.getUser(username: username))
            } catch let e as ApiError {
                print(e)
            }
            
            DispatchQueue.main.async {
                self.delegate?.didReceiveUsernameInfo(taken: details != nil)
            }
        }
    }
    
    func checkEmail(email: String) {
        DispatchQueue.main.async {
            self.delegate?.didReceiveEmailValid(valid: RegistrationModel.EMAIL_TEST.evaluate(with: email))
        }
    }
    
    func checkPasswords(password: String, password2: String) {
        DispatchQueue.main.async {
            self.delegate?.didReceivePasswordsValid(valid: password == password2)
        }
    }
    
    func register(
        username: String,
        password: String,
        email: String,
        firstName: String,
        lastName: String
    ) {
        async {
            do {
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
