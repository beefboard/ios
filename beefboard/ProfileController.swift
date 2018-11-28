//
//  ProfileController.swift
//  beefboard
//
//  Created by Oliver on 02/11/2018.
//  Copyright © 2018 Oliver Bell. All rights reserved.
//

import UIKit
import AwaitKit

class ProfileController: UIViewController {
    var isMe: Bool = false
    var details: User?
    
    private var authSource = AuthModel()
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    
    @IBOutlet weak var logoutButton: UIBarButtonItem!
    
    @IBAction func logoutAction(_ sender: Any) {
        self.doLogout()
    }
    
    @IBAction func doneAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.authSource.delegate = self
        
        if !self.isMe {
            self.logoutButton.isEnabled = false
            self.logoutButton.tintColor = UIColor.clear
        }
        
        if let userDetails = self.details {
            nameLabel.text = "\(userDetails.firstName) \(userDetails.lastName)"
            usernameLabel.text = "\(userDetails.username)"
        }
    }
    
    func doLogout() {
        self.authSource.logout()
    }
}

extension ProfileController: AuthModelDelegate {
    func didReceiveAuth(auth: User?) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func didReceiveAuthError(error: ApiError) {}
}
