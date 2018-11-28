//
//  RegistrationModel.swift
//  beefboard
//
//  Created by Oliver on 28/11/2018.
//  Copyright © 2018 Oliver Bell. All rights reserved.
//

import Foundation

protocol RegistrationModelDelegate: class {
    func didRegister()
    func didRecieveRegistrationError(error: ApiError)
}

class RegistrationModel {
    weak var delegate: RegistrationModelDelegate?
    
}
