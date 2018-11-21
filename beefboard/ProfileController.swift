//
//  ProfileController.swift
//  beefboard
//
//  Created by Oliver on 02/11/2018.
//  Copyright © 2018 Oliver Bell. All rights reserved.
//

import UIKit

class ProfileController: UIViewController {
    var isMe: Bool = false
    var details: User?;
    
    @IBOutlet weak var logoutButton: UIButton!
    
    @IBAction func logoutAction(_ sender: Any) {
        BeefboardApi.clearToken()
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func doneAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.logoutButton.isHidden = !isMe
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
