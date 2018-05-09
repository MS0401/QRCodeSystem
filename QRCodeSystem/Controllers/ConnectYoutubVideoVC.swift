//
//  ConnectYoutubVideoVC.swift
//  QRCodeSystem
//
//  Created by MyCom on 4/26/18.
//  Copyright © 2018 MyCom. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage
import RSLoadingView
import MessageUI
import AFNetworking

class ConnectYoutubVideoVC: UIViewController, UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout, MFMailComposeViewControllerDelegate {
    
    @IBOutlet var connectBtn: UIBarButtonItem!
    var listArr = [String]()
    var connectListArr = [NSDictionary]()
    var videolist: UICollectionView!
    var ref: DatabaseReference!
    var loadingView = RSLoadingView()
    
    var selectedIndexPath : IndexPath?
    
    var qrImage: UIImage?
    var qrTxt: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadingView.show(on: view)
        
        self.ref = Database.database().reference()
        
        self.navigationItem.title = "Videos"
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        videolist = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
        videolist.register(UINib(nibName: "CustomCell", bundle: nil), forCellWithReuseIdentifier: "Cell")
        videolist.backgroundColor = UIColor.clear
        videolist.delegate = self
        videolist.dataSource = self
        self.view.addSubview(videolist)
        self.connectBtn.isEnabled = false
        
        GetListData()
    }
    
    func GetListData() {
        
        //Downloading All video data
        self.ref.child("YoutubeVideos/VideoURLs").observeSingleEvent(of: DataEventType.value, with: { snapshot in
            
            for item1 in snapshot.children {
                let child = item1 as! DataSnapshot
                let dict = child.value as! NSDictionary
                
                let videoUrl = dict["urls"] as! [String]
                
                self.listArr = videoUrl
            }
            
            if self.listArr.count == 0 {
                self.loadingView.hide()
                self.postAlert("No video!", message: "There are no any video. Please recording video for connecting with QR Code!")
            }else {
                //Downloading connect data
                self.ref.child("YoutubeVideos/ConnectData").observeSingleEvent(of: DataEventType.value, with: { snapshot in
                    
                    for item in snapshot.children {
                        let child = item as! DataSnapshot
                        let dict = child.value as! NSDictionary
                        
                        let videoUrl = dict["url"] as! String
                        let scanCode = dict["scanCode"] as! String
                        
                        let unit = ["url": videoUrl, "scanCode": scanCode] as NSDictionary
                        print("Video Url", videoUrl)
                        self.connectListArr.append(unit)
                    }
                    var index = 0
                    for i in self.listArr {
                        for j in self.connectListArr {
                            if i == (j["url"] as! String) {
                                if self.listArr.count == self.connectListArr.count {
                                    self.listArr.removeAll()
                                    break
                                }
                                self.listArr.remove(at: index)
                                
                            }
                        }
                        index = index + 1
                    }
                    
                    if self.listArr.count == 0 {
                        self.loadingView.hide()
                        self.postAlert("No New Video", message: "There are no new video. In order to connect new QR code, please record new video!")
                    }else {
                        self.loadingView.hide()
                        self.videolist.reloadData()
                    }
                })
            }
            
        })
        
    }
    
    @IBAction func ConnectVideo(_ sender: UIBarButtonItem) {
        
        self.loadingView.show(on: view)
        
        //MARK: Uploading current location to Firebase database.
        let selectedUrl = self.listArr[(selectedIndexPath?.row)!]
        let selectedId = self.extractYoutubeVideoId(from: self.listArr[(selectedIndexPath?.row)!])
        
        
        let dataInformation: NSDictionary = ["url": selectedUrl, "scanCode": qrTxt!]
        
        
        //MARK: add firebase child node
        let child = ["/VideoIDs/ConnectData/\(selectedId!)": dataInformation] // profile Image uploading
        
        self.ref.updateChildValues(child, withCompletionBlock: { (error, ref) in
            
            if error != nil {
                print("Failed uploaded video id", error!)
                return
            }
            
            self.SendEmail()
        })
    }
    
    func extractYoutubeVideoId(from url: String) -> String? {
        let pattern = "((?<=(v|V)/)|(?<=be/)|(?<=(\\?|\\&)v=)|(?<=embed/))([\\w-]++)"
        guard let range = url.range(of: pattern, options: .regularExpression) else { return nil }
        return String(url[range])
    }
    
    func SendEmail() {
        if MFMailComposeViewController.canSendMail() {
            print("Can send email")
            
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            
            //Set the subject and message of the email
            mailComposer.setCcRecipients(["Srinath.mit@gmail.com", "fordevelop0401@gmail.com"])
            mailComposer.setSubject("Please print your own QR Code!")
            mailComposer.setMessageBody("Attached image is your own QR Code image. Please print and scan QR code using our iOS app!.", isHTML: true)
            
            if let image = self.qrImage {
                
                let data: NSData = UIImageJPEGRepresentation(image, 0.1)! as NSData
                mailComposer.addAttachmentData(data as Data, mimeType: "image/JPEG", fileName: "QRCode.jpeg")
            }
            
            self.present(mailComposer, animated: true, completion: {() -> Void in
                
                print("Successfully sent message")
                self.loadingView.hide()
            })
        }
    }
    
    //MailComposer Delegate method
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
        self.postAlert("Success", message: "Successfully sent message!")
    }
    
    func postAlert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message,
                                      preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: { action in
            let  vc =  self.navigationController?.viewControllers.filter({$0 is MainViewController}).first
            self.navigationController?.popToViewController(vc!, animated: true)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
//    func GetThumbnailImage(url: String) -> UIImage {
//        let thumbnailurl = URL(string: url)
//        let session = URLSession.shared
//        let task = session.dataTask(with: thumbnailurl!, completionHandler: {(data, response, error) in
//            if data != nil {
//                let image = UIImage(data: data!)
//                if image != nil {
//                    DispatchQueue.main.async(execute: {
//                        return image!
//                    })
//                }
//            }
//        })
//        task.resume()
//        return nil
//
//    }
//
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return listArr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! CustomCell
        
        if let selected = selectedIndexPath, selected == indexPath {
            cell.imageview.alpha = 0.5
            
        }else {
            cell.imageview.alpha = 1.0
        }
        
        let videoId = self.extractYoutubeVideoId(from: self.listArr[indexPath.row])
        let thumbnailImageUrl = "https://img.youtube.com/vi/\(videoId!)/0.jpg"
//        let thumbnailurl = URL(fileURLWithPath: thumbnailImageUrl)
//            do {
//                let imageData = try Data(contentsOf: thumbnailurl as URL)
//                cell.imageview.image = UIImage(data: imageData)
//            } catch {
//                print("Unable to load data: \(error)")
//            }
        
        
        cell.imageview.setImageWith(URL(string: thumbnailImageUrl)!, placeholderImage: UIImage(named: "placeholder-avatar"))
       
        
//        let session = URLSession(configuration: .default)
//        let task = session.dataTask(with: thumbnailurl) {(data, response, error) in
//
//            if let e = error {
//                print("Some error occurred: \(e)")
//            }else {
//                if (response as? HTTPURLResponse) != nil {
//                    if let imageData = data {
//                        let image = UIImage(data: imageData)
//                        cell.imageview.image = image
//                    }else {
//                        print("No image found")
//                    }
//                }else {
//                    print("No response from server")
//                }
//            }
//        }
//        task.resume()
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = (self.view.frame.size.width-20)/2
        return CGSize(width: size, height: size)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard let cell = collectionView.cellForItem(at: indexPath) as? CustomCell, let _ = cell.checkIcon.image else { return }
        
        selectedIndexPath = indexPath
        self.connectBtn.isEnabled = true
        self.videolist.reloadData()
        
        
        print("Didselected")
        
    }

    

}
