//
//  ProfilesModel.swift
//  beefboard
//
//  Created by Oliver on 14/12/2018.
//  Copyright © 2018 Oliver Bell. All rights reserved.
//

import Foundation
import AwaitKit

protocol ProfilesModelDelegate: class {
    func didReceiveProfileDetails(user: User?)
    func didReceiveProfileDetailsError(error: ApiError)
}

/**
 * Model for handling retrieval of all
 * profile type data
 */
class ProfilesModel {
    weak var delegate: ProfilesModelDelegate?
    
    /**
     * Attempt to get a given users details
     *
     * Broadcasts didReceiveProfileDetails on success,
     * and didReceiveProfileDetailsError with error on
     * failure
     */
    func retrieveDetails(username: String) {
        async {
            do {
                let details = try await(BeefboardApi.getUser(username: username))
                DispatchQueue.main.async {
                    self.delegate?.didReceiveProfileDetails(user: details)
                }
            } catch let e as ApiError {
                DispatchQueue.main.async {
                    self.delegate?.didReceiveProfileDetailsError(error: e)
                }
            }
        }
    }
}
