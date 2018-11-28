//
//  RegistrationController.swift
//  beefboard
//
//  Created by Oliver on 25/11/2018.
//  Copyright © 2018 Oliver Bell. All rights reserved.
//

import UIKit

class RegistrationController: UIViewController {

    @IBAction func signupAction(_ sender: Any) {
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBOutlet weak var signupButton: UIBarButtonItem!
    
    @IBOutlet weak var usernameInput: UITextField!
    
    @IBOutlet weak var passwordInput: UITextField!
    @IBOutlet weak var password2Input: UITextField!
    
    @IBOutlet weak var emailInput: UITextField!
    
    @IBOutlet weak var firstnameInput: UITextField!
    @IBOutlet weak var lastnameInput: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.disableSignup()
    }
    
    func disableSignup() {
        self.signupButton!.isEnabled = false;
    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
