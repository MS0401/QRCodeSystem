//
//  WebViewViewController.swift
//  QRCodeSystem
//
//  Created by MyCom on 4/25/18.
//  Copyright © 2018 MyCom. All rights reserved.
//

import UIKit
import WebKit
import RSLoadingView
import Firebase
import FirebaseStorage

class WebViewViewController: UIViewController {
    
    @IBOutlet var videoPlayer: YouTubePlayerView!
    @IBOutlet var play: UIBarButtonItem!
    
    var videoUrl: String!
    var urlBool = false
    var videoId: String!
    var playing: Bool = false
    var loadingView = RSLoadingView()
    var timer: Timer!
    var ref: DatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.ref = Database.database().reference()
        
        self.loadingView.show(on: view)
        videoPlayer.playerVars = [
            "playsinline": "1" as AnyObject,
            "controls": "0" as AnyObject,
            "showinfo": "0" as AnyObject
        ]
        if self.urlBool {
            let videoId = extractYoutubeVideoId(from: videoUrl)
            if videoId == nil {
                self.loadingView.hide()
                self.postAlert2("No youtube URL", message: "This is not validated youtube url. Please input validated youtube url.")
            }else {
                videoPlayer.loadVideoID(videoId!)
                
                self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.HideloadingView), userInfo: nil, repeats: true)
            }
        }else {
            videoPlayer.loadVideoID(videoId)
            
            self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.HideloadingView), userInfo: nil, repeats: true)
        }
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    
    @objc func HideloadingView() {
        if self.videoPlayer.ready {
            self.loadingView.hide()
            self.timer.invalidate()
            self.playing = true
        }else if self.videoPlayer.playerState == .Unstarted {
            
        }
    }
    
    func extractYoutubeVideoId(from url: String) -> String? {
        let pattern = "((?<=(v|V)/)|(?<=be/)|(?<=(\\?|\\&)v=)|(?<=embed/))([\\w-]++)"
        guard let range = url.range(of: pattern, options: .regularExpression) else { return nil }
        return String(url[range])
    }

    @IBAction func PlayVideo(_ sender: UIBarButtonItem) {
        
        if self.videoPlayer.ready {
            if self.videoPlayer.playerState != YouTubePlayerState.Playing {
                self.videoPlayer.play()
                self.play.title = "Pause"
            }else if self.videoPlayer.playerState == YouTubePlayerState.Playing {
                self.videoPlayer.pause()
                self.play.title = "Play"
            }
        }
    }
    
    @IBAction func RegisterYoutubeVideo(_ sender: UIBarButtonItem) {
        
        if self.playing {
            if self.videoPlayer.playerState == .Playing {
                self.videoPlayer.pause()
            }
            self.loadingView.show(on: view)
            var urlArray = ["https://youtu.be/MMIsbl3DIL8", "https://www.youtube.com/watch?v=B5l_vNEcFWg", "https://www.youtube.com/watch?v=MMIsbl3DIL8"]
            
            urlArray.append(self.videoUrl)
            let dataInformation: NSDictionary = ["urls": urlArray]
            
            //MARK: add firebase child node
            let child = ["/YoutubeVideos/VideoURLs/Videos": dataInformation] // profile Image uploading
            
            self.ref.updateChildValues(child, withCompletionBlock: { (error, ref) in
                
                if error != nil {
                    print("Failed uploaded video id", error!)
                    return
                }
                self.loadingView.hide()
                self.postAlert1("Success!", message: "Your youtube url was registered successfully.")
            })
            
        }else {
            self.postAlert("Warning!", message: "In order to check url is validate or not, please play video.")
        }
        
    }
    
    // Utility method to display an alert to the user.
    func postAlert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message,
                                      preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func postAlert1(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message,
                                      preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: { action in
            let  vc =  self.navigationController?.viewControllers.filter({$0 is MainViewController}).first
            self.navigationController?.popToViewController(vc!, animated: true)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func postAlert2(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message,
                                      preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: { action in
            let  vc =  self.navigationController?.viewControllers.filter({$0 is InsertYoutubeURLVC}).first
            self.navigationController?.popToViewController(vc!, animated: true)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
}
