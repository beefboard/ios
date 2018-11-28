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
    private let authModel = AuthModel()
    
    @IBAction func cancelAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet weak var passwordInput: UITextField!
    @IBOutlet weak var usernameInput: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    private var loading = false
    
    @IBAction func loginClicked(_ sender: Any) {
        self.handleLogin()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.authModel.delegate = self
        
        
        // Any time any of the inputs change, update
        // the login button state
        [usernameInput, passwordInput].forEach({
            $0.addTarget(self, action: #selector(LoginController.updateLoginButton), for: .editingChanged)
        })
        self.updateLoginButton()
    }
    
    func handleLogin() {
        let username = self.usernameInput!.text!
        let password = self.passwordInput!.text!
        
        if username.isEmpty || password.isEmpty {
            return
        }
        
        self.usernameInput!.resignFirstResponder()
        self.passwordInput!.resignFirstResponder()
        
        self.setLoading(true)
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        self.authModel.login(username: username, password: password)
    }
    
    func setLoading(_ value: Bool) {
        self.loading = value
        self.updateLoginButton()
    }
    
    @objc
    func updateLoginButton() {
        self.loginButton.isEnabled =
            self.usernameInput.text?.count ?? 0 > 0 &&
            self.passwordInput.text?.count ?? 0 > 0 &&
            !self.loading
    }
}

extension LoginController: AuthModelDelegate {
    func showFailedAlert(message: String) {
        let alert = UIAlertController(title: "Login failed", message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
    
    func didReceiveAuth(auth: User?) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        self.dismiss(animated: true, completion: nil)
    }
    
    func didReceiveAuthError(error: ApiError) {
        // Clear the current password, so that the login cannot be spammed
        self.passwordInput!.text = ""
        self.setLoading(false)
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
        var errorMessage: String = ""
        switch(error) {
        case ApiError.invalidCredentials:
            errorMessage = "Invalid username or password"
        case ApiError.connectionError:
            errorMessage = "Connection error"
        case ApiError.invalidResponse:
            errorMessage = "Server error"
        default:
            errorMessage = "Unknown error"
        }
        
        self.showFailedAlert(message: errorMessage)
    }
}
