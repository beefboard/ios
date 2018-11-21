//
//  ViewController.swift
//  beefboard
//
//  Created by Oliver on 16/10/2018.
//  Copyright © 2018 Oliver Bell. All rights reserved.
//

import UIKit
import AwaitKit

class LoginController: UIViewController {

    @IBAction func cancelAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBOutlet weak var authLabel: UILabel!
    @IBOutlet weak var passwordInput: UITextField!
    @IBOutlet weak var usernameInput: UITextField!
    
    @IBAction func loginClicked(_ sender: Any) {
        let username = self.usernameInput!.text!
        let password = self.passwordInput!.text!
        if !username.isEmpty && !password.isEmpty {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            async {
                var success = false
                do {
                    success = try await(BeefboardApi.login(username: username, password: password))
                } catch {}
                
                
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    
                    if success {
                        self.dismiss(animated: true, completion: nil)
                    } else {
                        self.authLabel.text = "Invalid username or password"
                    }
                }
            }
        }
    }
    @IBOutlet weak var tokenLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }


}

