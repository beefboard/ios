//
//  ProfileController.swift
//  beefboard
//
//  Created by Oliver on 02/11/2018.
//  Copyright © 2018 Oliver Bell. All rights reserved.
//

import UIKit
import AwaitKit

/**
 * View controller for displaying
 * a users profile information
 */
class ProfileController: UIViewController {
    var isMe: Bool = false
    var details: User?
    
    private var authSource = AuthModel()
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    
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
            usernameLabel.text = userDetails.username
            emailLabel.text = userDetails.email
        }
    }
    
    func doLogout() {
        let dialog = UIAlertController(
            title: NSLocalizedString("Logout", comment: ""),
            message: NSLocalizedString("Are you sure you would like to logout", comment: ""),
            preferredStyle: .alert
        )
        dialog.addAction(
            UIAlertAction(
                title: NSLocalizedString("Yes", comment: ""),
                style: .destructive,
                handler: { (action) in
                    self.authSource.logout()
                }
            )
        )
        dialog.addAction(
            UIAlertAction(
                title: NSLocalizedString("Cancel", comment: ""),
                style: .default,
                handler: nil
            )
        )
        self.present(dialog, animated: false, completion: nil)
    }
}

extension ProfileController: AuthModelDelegate {
    func didReceiveAuth(auth: User?) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func didReceiveAuthError(error: ApiError) {}
}
