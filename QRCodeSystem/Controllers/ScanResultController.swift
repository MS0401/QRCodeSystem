//
//  ScanResultController.swift
//  swiftScan
//
//  Created by xialibing on 15/12/11.
//  Copyright © 2015年 xialibing. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage
import AVKit
import AVFoundation
import MobileCoreServices
import RSLoadingView

class ScanResultController: UIViewController, AVPlayerViewControllerDelegate {
    
    @IBOutlet var player: YouTubePlayerView!
    
    
    var codeResult:LBXScanResult?
   
    var ref: DatabaseReference!
    
    var listArr = [NSDictionary]()
    var playURL: String!
    
    var loadingView = RSLoadingView()
    var timer: Timer!
    var playing = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.edgesForExtendedLayout = UIRectEdge(rawValue: 0)
        
        self.ref = Database.database().reference()
        
        self.GetVideoURL()
    }
    
    func GetVideoURL() {
        
//        self.loadingView.show(on: view)
        self.ref.child("VideoIDs/ConnectData").observeSingleEvent(of: DataEventType.value, with: { snapshot in
            
            for item in snapshot.children {
                let child = item as! DataSnapshot
                let dict = child.value as! NSDictionary
                
                let videoUrl = dict["url"] as! String
                let scanCode = dict["scanCode"] as! String
                
                let unit = ["url": videoUrl, "scanCode": scanCode] as NSDictionary
                print("Video Url", videoUrl)
                self.listArr.append(unit)
            }
            
            for item1 in self.listArr {
                if (self.codeResult?.strScanned)! == (item1["scanCode"] as! String) {
                    self.playURL = (item1["url"] as! String)
                    self.PlayVideo()
                    return
                }
            }
            
            self.loadingView.hide()
            self.NoMatchVideo(title: "No match!", message: "There are no matched video.")
            
            
        })
    }
    
    func substring(string: String, fromIndex: Int, toIndex: Int) -> String? {
        if fromIndex < toIndex && toIndex < string.count /*use string.characters.count for swift3*/{
            let startIndex = string.index(string.startIndex, offsetBy: fromIndex)
            let endIndex = string.index(string.startIndex, offsetBy: toIndex)
            return String(string[startIndex..<endIndex])
        }else{
            return nil
        }
    }
    
    func PlayVideo() {

        let subStr = self.substring(string: self.playURL, fromIndex: 0, toIndex: 10)
        print("SubString is +++++++", subStr!)
        
        if subStr == "https://you" {
            self.loadingView.show(on: view)
            player.playerVars = [
                "playsinline": "1" as AnyObject,
                "controls": "0" as AnyObject,
                "showinfo": "0" as AnyObject
            ]
            let videoId = extractYoutubeVideoId(from: self.playURL)
            if videoId == nil {
                self.loadingView.hide()
                self.NoMatchVideo(title: "No youtube URL", message: "This is not validated youtube url. Please retry validated youtube url.")
            }else {
                player.loadVideoID(videoId!)
                
                self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.HideloadingView), userInfo: nil, repeats: true)
            }
        }else {
            if let url = URL(string: self.playURL){
                
                let player = AVPlayer(url: url)
                let controller=AVPlayerViewController()
                controller.player=player
                controller.view.frame = self.view.frame
                self.view.addSubview(controller.view)
                self.addChildViewController(controller)
                player.play()
            }
        }
    
    }
    
    @objc func HideloadingView() {
        if self.player.ready {
            self.loadingView.hide()
            self.timer.invalidate()
            self.playing = true
            self.player.play()
        }else if self.player.playerState == .Unstarted {
            
        }
    }
    
    func extractYoutubeVideoId(from url: String) -> String? {
        let pattern = "((?<=(v|V)/)|(?<=be/)|(?<=(\\?|\\&)v=)|(?<=embed/))([\\w-]++)"
        guard let range = url.range(of: pattern, options: .regularExpression) else { return nil }
        return String(url[range])
    }
    
    func NoMatchVideo(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message,
                                      preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: { action in
            self.navigationController?.popViewController(animated: true)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
}




