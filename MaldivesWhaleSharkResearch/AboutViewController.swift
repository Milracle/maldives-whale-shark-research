//
//  AboutViewController.swift
//  MaldivesWhaleSharkResearch
//
//  Created by mac on 5/2/17.
//  Copyright © 2017 dooddevelopments. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class AboutViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func logoutButtonPressed(_ sender: UIBarButtonItem) {
        
        let userDefaults = UserDefaults.standard
        
        if userDefaults.bool(forKey: "signedIn") == true {
            userDefaults.set(false, forKey: "signedIn")
            userDefaults.synchronize()
            let firebaseAuth = FIRAuth.auth()
            do {
                try firebaseAuth?.signOut()
            } catch let signOutError as NSError {
                print ("Error signing out: %@", signOutError)
            }
        }

        dismiss(animated: true, completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}