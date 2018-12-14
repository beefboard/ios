//
//  RegistrationController.swift
//  beefboard
//
//  Created by Oliver on 25/11/2018.
//  Copyright © 2018 Oliver Bell. All rights reserved.
//

import UIKit

class RegistrationController: UIViewController {
    
    private var registrationModel = RegistrationModel()
    private var authModel = AuthModel()
    private var profileModel = ProfilesModel()

    @IBAction func signupAction(_ sender: Any) {
        self.handleSignupClicked()
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        self.handleCancelClicked()
    }
    
    @IBOutlet weak var signupButton: UIBarButtonItem!
    
    @IBOutlet weak var usernameInput: UITextField!
    
    @IBOutlet weak var passwordInput: UITextField!
    @IBOutlet weak var password2Input: UITextField!
    
    @IBOutlet weak var emailInput: UITextField!
    
    @IBOutlet weak var firstnameInput: UITextField!
    @IBOutlet weak var lastnameInput: UITextField!
    
    @IBOutlet weak var emailErrorLabel: UILabel!
    @IBOutlet weak var passwordsErrorLabel: UILabel!
    @IBOutlet weak var usernameErrorLabel: UILabel!
    
    private var emailChecker: String? = nil
    
    private var usernameTaken = false
    private var emailValid = false
    private var passwordsValid = false
    
    private var loading = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registrationModel.delegate = self
        authModel.delegate = self
        profileModel.delegate = self
        
        updateForm()
        
        
        // Setup bindings for input changes to their
        // check functions
        usernameInput.addTarget(
            self,
            action: #selector(RegistrationController.usernameUpdated),
            for: .editingChanged
        )
        
        [passwordInput, password2Input].forEach({
            $0.addTarget(
                self,
                action: #selector(RegistrationController.passwordUpdated),
                for: .editingChanged
            )
        })
        
        emailInput.addTarget(
            self,
            action: #selector(RegistrationController.emailUpdated),
            for: .editingChanged
        )
        
        [firstnameInput, lastnameInput].forEach({
            $0.addTarget(
                self,
                action: #selector(RegistrationController.updateForm),
                for: .editingChanged
            )
        })
    }
    
    func showError(title: String, message: String, completion: (() -> Void)?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: false, completion: completion)
    }
    
    @objc
    func usernameUpdated() {
        if let checkUsername = self.usernameInput.text {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                // Only run this check if the username has not changed
                if self.usernameInput.text == checkUsername {
                    self.profileModel.retrieveDetails(username: checkUsername)
                }
            }
        }
    }
    
    @objc
    func passwordUpdated() {
        if let password = self.passwordInput.text,
            let password2 = self.password2Input.text
        {
            registrationModel.checkPasswords(
                password: password,
                password2: password2
            )
        }
    }
    
    @objc
    func emailUpdated() {
        if let email = self.emailInput.text {
            registrationModel.checkEmail(email: email)
        }
    }
    
    @objc
    func updateForm() {
        let haveUsername = self.usernameInput.text!.count > 0
        
        if haveUsername {
            self.usernameErrorLabel.isHidden = !self.usernameTaken
        } else {
            self.usernameErrorLabel.isHidden = true
        }
        
        let havePasswords =
                self.passwordInput.text!.count > 0
                && self.password2Input.text!.count > 0
        
        if havePasswords {
            self.passwordsErrorLabel.isHidden = self.passwordsValid
        } else {
            self.passwordsErrorLabel.isHidden = true
        }
        
        let haveEmail = self.emailInput.text!.count > 0
        
        if haveEmail {
            self.emailErrorLabel.isHidden = self.emailValid
        } else {
            self.emailErrorLabel.isHidden = true
        }
        
        let haveName =
            self.firstnameInput.text!.count > 0
            && self.lastnameInput.text!.count > 0
        
        
        // Only set the button enabled if we have no errors
        self.signupButton!.isEnabled = (
            haveUsername && !self.usernameTaken
            && havePasswords && self.passwordsValid
            && haveEmail && self.emailValid
            && haveName
            && !self.loading
        );
    }
    
    func handleSignupClicked() {
        self.loading = true
        self.updateForm()
        self.registrationModel.register(
            username: self.usernameInput.text!,
            password: self.passwordInput.text!,
            email: self.emailInput.text!,
            firstName: self.firstnameInput.text!,
            lastName: self.lastnameInput.text!
        )
    }
    
    func handleCancelClicked() {
        let dialog = UIAlertController(
            title: "Cancel",
            message: "Are you sure you want to cancel registration",
            preferredStyle: .alert
        )
        dialog.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { (action) in
            self.dismiss(animated: true, completion: nil)
        }))
        dialog.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        
        self.present(dialog, animated: true, completion: nil)
    }
}

extension RegistrationController: RegistrationModelDelegate {
    func didReceiveEmailValid(valid: Bool) {
        self.emailValid = valid
        self.updateForm()
    }
    
    func didReceivePasswordsValid(valid: Bool) {
        self.passwordsValid = valid
        self.updateForm()
    }
    
    func didRegister(username: String, password: String) {
        self.authModel.login(username: username, password: password)
    }
    
    func didRecieveRegistrationError(error: ApiError) {
        self.loading = false
        self.updateForm()
    }
}

extension RegistrationController: AuthModelDelegate {
    func didReceiveAuth(auth: User?) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func didReceiveAuthError(error: ApiError) {
        self.showError(
            title: "Login error",
            message: "Could not log into account",
            completion: nil
        )
    }
}

extension RegistrationController: ProfilesModelDelegate {
    func didReceiveProfileDetails(user: User?) {
        self.usernameTaken = user != nil
        self.updateForm()
    }
    
    func didReceiveProfileDetailsError(error: ApiError) {}
}
