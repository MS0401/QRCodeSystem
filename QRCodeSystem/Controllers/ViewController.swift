//
//  ViewController.swift
//  QRCodeSystem
//
//  Created by MyCom on 4/18/18.
//  Copyright © 2018 MyCom. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import RSLoadingView

class ViewController: UIViewController {

    @IBOutlet var email: UITextField!
    @IBOutlet var password: UITextField!
    
    
    //MARK: Firebase initial path
    var ref: DatabaseReference!
    
    var dictArray: [NSDictionary] = [NSDictionary]()
    
    //MARK: RSLoadingView property
    let loadingView = RSLoadingView()
    
    var userPhoneNumber = ""
    
    //MARK: first sharing current location
    var firstShared: Bool = true
    
    var appDelegate: AppDelegate!
    
    //MARK: BackgroundTaskIdentifier for backgrond update location
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier!
    var backgroundTaskIdentifier2: UIBackgroundTaskIdentifier!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //MARK: base URL for Firebase database.
        self.ref = Database.database().reference()
        
        //MARK: keeping inputed user's email
        self.retrieveAccountInfo()
                
        //MARK: Appdelegate property
        appDelegate = UIApplication.shared.delegate as! AppDelegate
        
    }
    
    //Keep inputed email
    func retrieveAccountInfo() {
        
        let defaults = UserDefaults.standard
        
        if defaults.string(forKey: "email") != nil {
            
            self.email.text = defaults.string(forKey: "email")
            self.password.text = defaults.string(forKey: "password")
            
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func LoginAction(_ sender: UIButton) {
        
        let email = self.email.text!
        let password = self.password.text!
        
        
        let defaults = UserDefaults.standard
        
        defaults.set(email, forKey: "email")
        defaults.set(password, forKey: "password")
        
        
        if self.email.text == "" || self.password.text == "" {
            
            //Alert to tell the user that there was an error because they didn't fill anything in the textfields because they didn't fill anything in
            
            let alertController = UIAlertController(title: "Error", message: "Please enter an email and password.", preferredStyle: .alert)
            
            let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(defaultAction)
            
            self.present(alertController, animated: true, completion: nil)
            
        }else {
            
            self.loadingView.show(on: view)
            
            self.FirebaseEmailLogin()
        }
        
    }
    
    func FirebaseEmailLogin() {
        
        Auth.auth().signIn(withEmail: self.email.text!, password: self.password.text!) { (user, error) in
            
            if error == nil {
                
                //Print into the console if successfully logged in
                print("You have successfully logged in")
                
                //MARK: Go to the VerificationViewController
                let Root = self.storyboard?.instantiateViewController(withIdentifier: "nav") as! NVController
                self.present(Root, animated: true, completion: nil)
                
                DispatchQueue.main.async(execute: {() -> Void in
                    self.loadingView.hide()                    
                })
                
            } else {
                
                //Tells the user that there is an error and then gets firebase to tell them the error
                let alertController = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert)
                
                let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                alertController.addAction(defaultAction)
                
                self.present(alertController, animated: true, completion: nil)
                self.loadingView.hide()
            }
        }
    }
    
   
    @IBAction func RegisterAction(_ sender: UIButton) {
        
        let register = self.storyboard?.instantiateViewController(withIdentifier: "signup") as! SignUpViewController
        self.present(register, animated: true, completion: nil)
        
    }
        
    //MARK: Show Alert View Controller
    func showAlert(_ title: String, message: String) {
        
        let alertView = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertView.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        alertView.view.tintColor = UIColor(netHex: 0xFF7345)
        
        self.present(alertView, animated: true, completion: nil)
    }


}

//MARK: extension UIColor(hexcolor)
extension UIColor {
    
    // Convert UIColor from Hex to RGB
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(netHex: Int) {
        self.init(red: (netHex >> 16) & 0xff, green: (netHex >> 8) & 0xff, blue: netHex & 0xff)
    }
}


