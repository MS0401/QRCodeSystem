//
//  SignUpViewController.swift
//  QRCodeSystem
//
//  Created by MyCom on 4/18/18.
//  Copyright © 2018 MyCom. All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import RSLoadingView
import Photos

enum PhotoSource {
    case library
    case camera
}

class SignUpViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet var profileImage: UIImageView!
    @IBOutlet var userName: UITextField!
    @IBOutlet var email: UITextField!
    @IBOutlet var password: UITextField!
    @IBOutlet var phoneNumber: UITextField!
    
    var appDelegate: AppDelegate!
    
    var userPhoneNumber = ""
    
    //MARK: BackgroundTaskIdentifier for backgrond update location
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier!
    var backgroundTaskIdentifier2: UIBackgroundTaskIdentifier!
    
    //MARK: first sharing current location
    var firstShared: Bool = true
    
    var downloadingBool: Bool = false
    
    var dictArray: [NSDictionary] = [NSDictionary]()
    
    // Loading View property
    let loadingView = RSLoadingView()
    
    // ImagePickerController property
    let imagePicker = UIImagePickerController()
    
    //MARK: Firebase initial path
    var ref: DatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ImagePickerController delegate confirm.
        self.imagePicker.delegate = self
        
        //MARK: base URL for Firebase database.
        self.ref = Database.database().reference()
        
        self.Setup()
        
        //MARK: Appdelegate property
        appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        //MARK: when touch anywhere, dismissing keyboard.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SignUpViewController.dismissKeyboard))
        self.view.addGestureRecognizer(tap)
        
    }
    
    func Setup() {
        
        self.CircleImage(profileImage: self.profileImage)
        self.dictArray.removeAll()
    }
    
    //MARK: Calls this function when the tap is recorgnized
    @objc func dismissKeyboard() {
        
        view.endEditing(true)
    }
    
    @IBAction func SignUpAction(_ sender: UIButton) {
        
        let save_email = self.email.text!
        let defaults = UserDefaults.standard
        defaults.set(save_email, forKey: "save_email")
        
        
        if self.email.text == "" {
            self.showAlert("Warning!", message: "You didn't input your email. Please input your email.")
        }else if self.password.text == "" {
            self.showAlert("Warning!", message: "You didn't input your password. Please input your password.")
        }else if self.userName.text == "" {
            self.showAlert("Warning!", message: "You didn't input your name. Please input your name.")
        }else if self.profileImage.image == UIImage(named: "profile.png") {
            self.showAlert("Warning!", message: "You didn't select your profile image. Please select your profile image.")
        }else if self.phoneNumber.text == "" {
            self.showAlert("Warning!", message: "You didn't input phone number. Please input phone number.")
        }else {
            
            self.loadingView.show(on: view)
            
            self.FirebaseEmailSignUp()
        }
        
    }
    
    
    func FirebaseEmailSignUp() {
        
        Auth.auth().createUser(withEmail: email.text!, password: password.text!) { (user, error) in
            
            if error == nil {
                print("You have successfully signed up")
                
                //MARK: Uploading user information for chatting.
                user?.sendEmailVerification(completion: nil)
                
                let storageRef = Storage.storage().reference().child("usersProfilePics").child(user!.uid)
                let imageData = UIImageJPEGRepresentation(self.profileImage.image!, 0.1)
                storageRef.putData(imageData!, metadata: nil, completion: { (metadata, err) in
                    if err == nil {
                        let path = metadata?.downloadURL()?.absoluteString
                        
                        let values = ["name": self.userName.text!, "email": self.email.text!, "profilePicLink": path!]
                        Database.database().reference().child("users").child((user?.uid)!).child("credentials").updateChildValues(values, withCompletionBlock: { (errr, _) in
                            if errr == nil {
                                let userInfo = ["email" : self.email.text!, "password" : self.password.text!]
                                UserDefaults.standard.set(userInfo, forKey: "userInformation")
                                
                                self.Uploading()
                            }
                        })
                    }
                })
                
                
            } else {
                let alertController = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert)
                
                let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                alertController.addAction(defaultAction)
                
                self.present(alertController, animated: true, completion: nil)
                self.loadingView.hide()
            }
        }
    }
    
    // MARK: Uploading User profile information to Firebase database.
    func Uploading() {
        
        //MARK: Firebase uploading function/// ******** important ********
        
        //getting image URL from library or photoAlbum.
        var data: NSData = NSData()
        if let image = self.profileImage.image {
            
            data = UIImageJPEGRepresentation(image, 0.1)! as NSData
        }
        
        let imageURL = data.base64EncodedString(options: NSData.Base64EncodingOptions.lineLength64Characters)
        
        let userName = self.userName.text!
        let userEmail = self.email.text!
        let userPassword = self.password.text!
        
        
        let dataInformation: NSDictionary = ["imageURL": imageURL, "userName": userName, "userEmail": userEmail, "userPassword": userPassword, "phoneNumber": self.userPhoneNumber]
        
        print("my phone number is \(self.userPhoneNumber)")
        
        //MARK: add firebase child node
        let child1 = ["/QRCodeSystem/\(self.userPhoneNumber)/Profile/profile/": dataInformation] // profile Image uploading
        
        //MARK: Write data to Firebase
        self.ref.updateChildValues(child1, withCompletionBlock: { (error, ref) in
            
            if error == nil {
                
                //MARK: Go to the VerificationViewController
                let Root = self.storyboard?.instantiateViewController(withIdentifier: "nav") as! NVController
                self.present(Root, animated: true, completion: nil)
                
                self.loadingView.hide()
            }else {
                self.loadingView.hide()
                self.showAlert("Error!", message: (error?.localizedDescription)!)
            }
        })
    }
    
    
    //making circle image
    func CircleImage(profileImage: UIImageView) {
        // Circle images
        profileImage.layer.cornerRadius = profileImage.frame.size.height / 2
        profileImage.layer.borderWidth = 0.5
        profileImage.layer.borderColor = UIColor.clear.cgColor
        profileImage.clipsToBounds = true
        
    }
    
    @IBAction func SelectImage(_ sender: UIButton) {
        
        let sheet = UIAlertController(title: nil, message: "Select the source", preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "Camera", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.openPhotoPickerWith(source: .camera)
        })
        let photoAction = UIAlertAction(title: "Gallery", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.openPhotoPickerWith(source: .library)
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        sheet.addAction(cameraAction)
        sheet.addAction(photoAction)
        sheet.addAction(cancelAction)
        self.present(sheet, animated: true, completion: nil)
        
    }
    
    func openPhotoPickerWith(source: PhotoSource) {
        switch source {
        case .camera:
            let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
            if (status == .authorized || status == .notDetermined) {
                self.imagePicker.sourceType = .camera
                self.imagePicker.allowsEditing = true
                
                self.present(self.imagePicker, animated: true, completion: nil)
            }
        case .library:
            let status = PHPhotoLibrary.authorizationStatus()
            if (status == .authorized || status == .notDetermined) {
                self.imagePicker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary)!
                self.imagePicker.modalPresentationStyle = .popover
                self.imagePicker.sourceType = .photoLibrary// or savedPhotoAlbume
                self.imagePicker.allowsEditing = true
                self.imagePicker.delegate = self
                self.present(self.imagePicker, animated: true, completion: nil)
            }
        }
    }
    
    //MARK: UIImagePickerContollerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.profileImage.backgroundColor = UIColor.clear
            self.profileImage.image = pickedImage
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Show Alert View Controller
    func showAlert(_ title: String, message: String) {
        
        let alertView = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertView.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        alertView.view.tintColor = UIColor(netHex: 0xFF7345)
        
        self.present(alertView, animated: true, completion: nil)
    }
    
    //MARK: Getting current Time
    func GetCurrentTime() -> String {
        
        //MARK: Making project name - year.
        let format_year = DateFormatter()
        format_year.dateFormat = "yyyy"
        let year = format_year.string(from: Date())
        
        //MARK: Making project name - month.
        let format_month = DateFormatter()
        format_month.dateFormat = "MM"
        let month = format_month.string(from: Date())
        
        //MARK: Making project name - day.
        let format_day = DateFormatter()
        format_day.dateFormat = "dd"
        let day = format_day.string(from: Date())
        
        //MARK: Making project name - hour.
        let format_hour = DateFormatter()
        format_hour.dateFormat = "HH"
        let hour = format_hour.string(from: Date())
        
        //MARK: Making project name - minutes.
        let format_minute = DateFormatter()
        format_minute.dateFormat = "mm"
        let minute = format_minute.string(from: Date())
        
        //MARK: Making project name - second.
        let format_second = DateFormatter()
        format_second.dateFormat = "ss"
        let second = format_second.string(from: Date())
        
        let date = "\(year)Y\(month)Mth\(day)D\(hour)H\(minute)Mi\(second)S"
        
        return date
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

}

////MARK: extension UIColor(hexcolor)
//extension UIColor {
//    
//    // Convert UIColor from Hex to RGB
//    convenience init(red: Int, green: Int, blue: Int) {
//        assert(red >= 0 && red <= 255, "Invalid red component")
//        assert(green >= 0 && green <= 255, "Invalid green component")
//        assert(blue >= 0 && blue <= 255, "Invalid blue component")
//        
//        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
//    }
//    
//    convenience init(netHex: Int) {
//        self.init(red: (netHex >> 16) & 0xff, green: (netHex >> 8) & 0xff, blue: netHex & 0xff)
//    }
//}

