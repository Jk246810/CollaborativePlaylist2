//
//  LoginViewController.swift
//  CollaborativePlaylist2
//
//  Created by Brian on 7/12/17.
//  Copyright © 2017 jamee. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseAuthUI
import FirebaseDatabase

typealias FIRUser = FirebaseAuth.User

class LoginViewController: UIViewController {

    @IBOutlet weak var loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    
    }
    
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        guard let authUI = FUIAuth.defaultAuthUI()
            else { return }
        
        // 2
        authUI.delegate = self
        
        // 3
        let authViewController = authUI.authViewController()
        present(authViewController, animated: true)
    }
    
}

extension LoginViewController: FUIAuthDelegate {
    func authUI(_ authUI: FUIAuth, didSignInWith user: FIRUser?, error: Error?) {
        if let error = error {
            //assertionFailure("Error signing in: \(error.localizedDescription)")
            return
        }
        
        guard let user = user
            else { return }
        
        
        UserService.I.show(forUID: user.uid) { (user) in
            if let user = user {
                // handle existing user
                //UserService.I.setCurrent(user, writeToUserDefaults: true)
                
                let initialViewController = UIStoryboard.initialViewController(for: .main)
                self.show(initialViewController, sender: nil)
            } else {
                // handle new user
                self.performSegue(withIdentifier: Constants.Segue.toCreateUsername, sender: self)
            }
        }
    }
    
    
}
