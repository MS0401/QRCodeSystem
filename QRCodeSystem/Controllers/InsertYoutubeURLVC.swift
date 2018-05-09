//
//  InsertYoutubeURLVC.swift
//  QRCodeSystem
//
//  Created by MyCom on 4/25/18.
//  Copyright © 2018 MyCom. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import YoutubeDirectLinkExtractor
import MobileCoreServices

class InsertYoutubeURLVC: UIViewController, UITextFieldDelegate, AVPlayerViewControllerDelegate {
    
    @IBOutlet var urlTxt: UITextField!
    @IBOutlet var openBtn: UIButton!
    @IBOutlet var openIdBtn: UIButton!
    @IBOutlet var videoIdTxt: UITextField!
    
    var urlBool = false
    var playe: AVPlayer!
    var previewPlayer = AVPlayerViewController()
        
    override func viewDidLoad() {
        super.viewDidLoad()

        self.openBtn.layer.cornerRadius = self.openBtn.frame.size.height/2
        self.openIdBtn.layer.cornerRadius = self.openIdBtn.frame.size.height/2
    }
    
    @IBAction func OpenVideo(_ sender: UIButton) {
        
        switch sender.tag {
        case 0:
            if urlTxt.text == "" {
                self.postAlert("No url!", message: "Please input youtube url.")
            }else {
                self.urlTxt.resignFirstResponder()
                self.urlBool = true
                self.performSegue(withIdentifier: "web", sender: self)
            }
            break
        case 1:
            if videoIdTxt.text == "" {
                self.postAlert("No Video ID!", message: "Please input youtube Video ID.")
            }else {
                self.videoIdTxt.resignFirstResponder()
                self.performSegue(withIdentifier: "web", sender: self)
            }
            break
        default:
            break
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "web" {
            if self.urlBool {
                let web = segue.destination as! WebViewViewController
                web.videoUrl = urlTxt.text!
                web.urlBool = true
            }else {
                let web = segue.destination as! WebViewViewController
                web.videoId = videoIdTxt.text!
                web.urlBool = false
            }
            
        }
    }
    
    // Utility method to display an alert to the user.
    func postAlert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message,
                                      preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    //UITextField delegate method.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}
