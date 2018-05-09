//
//  MainViewController.swift
//  QRCodeSystem
//
//  Created by MyCom on 4/22/18.
//  Copyright © 2018 MyCom. All rights reserved.
//

import UIKit
import MobileCoreServices
import AVKit
import AVFoundation
import Firebase
import FirebaseStorage
import RSLoadingView
import CoreData

var isNewvideo = false

class MainViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet var tableView: UITableView!
    
    let titleList = ["Generating QR Code", "Scaning QR code", "Recording Video", "Youtube Video"]
    
    let imagePicker: UIImagePickerController! = UIImagePickerController()
    
    var ref: DatabaseReference!
    
    //MARK: RSLoadingView property
    let loadingView = RSLoadingView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

       self.ref = Database.database().reference()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "generate" {
            _ = segue.destination as! GeneratingQRCodeVC
        }else if segue.identifier == "youtube" {
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension MainViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "mainList", for: indexPath) as! MainListCell
        
        cell.title.text = self.titleList[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            self.performSegue(withIdentifier: "generate", sender: self)
            break
        case 1:
            
            LBXPermissions.authorizeCameraWith { [weak self] (granted) in
                
                if granted
                {
                    if let strongSelf = self
                    {
                        strongSelf.qqStyle()
                    }
                }else {
                    LBXPermissions.jumpToSystemPrivacySetting()
                }
            }
            
            break
        case 2:
            if (UIImagePickerController.isSourceTypeAvailable(.camera)) {
                if UIImagePickerController.availableCaptureModes(for: .rear) != nil {
                    
                    imagePicker.sourceType = .camera
                    imagePicker.mediaTypes = [kUTTypeMovie as String]
                    imagePicker.allowsEditing = false
                    imagePicker.delegate = self
                    
                    present(imagePicker, animated: true, completion: {})
                } else {
                    postAlert("Rear camera doesn't exist", message: "Application cannot access the camera.")
                }
            } else {
                postAlert("Camera inaccessable", message: "Application cannot access the camera.")
            }
            break
        case 3:
            self.performSegue(withIdentifier: "youtube", sender: self)
            break
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
    }
    
    // MARK: UIImagePickerControllerDelegate delegate methods
    // Finished recording a video
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        print("Got a video")
        
        if let pickedVideo = info[UIImagePickerControllerMediaURL] as? URL {
            print("Here's the file url:", pickedVideo)
            
            self.loadingView.show(on: view)
            
            // Save video to the Firebase storage
            let metadata = StorageMetadata()
            metadata.contentType = "video/mp4"
            let videoName = NSUUID().uuidString
            
            let storageRef = Storage.storage().reference(forURL: "gs://qrcodesystem-fe684.appspot.com")
            let childRef = storageRef.child("videos").child("\(videoName).mp4")
            let uploadTask = childRef.putFile(from: pickedVideo, metadata: metadata, completion: { (metadata, error) in
                
                if error != nil {
                    print("Failed uploaded video", error!)
                    return
                }
                
                if let storageUrl = metadata?.downloadURL()?.absoluteString {
                    
                    self.saveVideo(videoId: videoName,localUrl: pickedVideo, videoUrl: storageUrl)
                    
                    print("Storage Url", storageUrl)
                }
                
            })
            uploadTask.observe(.progress) { snapshot in
                
                let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount)/Double(snapshot.progress!.totalUnitCount)
                print("Percent : \(percentComplete)")
            }
            uploadTask.observe(.success) { snapshot in
                
                print("Successfully uploaded video")
            }
   
        }
        
        imagePicker.dismiss(animated: true, completion: {
            // Anything you want to happen when the user saves an video
        })
    }
    
    // Called when the user selects cancel
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("User canceled image")
        dismiss(animated: true, completion: {
            // Anything you want to happen when the user selects cancel
        })
    }
    
    //Scan QRCode
    func qqStyle()
    {
        print("qqStyle")
        
        let vc = QQScanViewController();
        var style = LBXScanViewStyle()
        style.animationImage = UIImage(named: "CodeScan.bundle/qrcode_scan_light_green")
        vc.scanStyle = style
        self.navigationController?.pushViewController(vc, animated: true)
        
    }
    
    ///////// Save video in directory and save id in coredata to retrive it in future. /////
    func saveVideoInDocumentDirectory(videoID: String, outputUrl: URL) {
        
        let video_data : NSData? = NSData(contentsOf: outputUrl)
        Common().saveVideoInDocumentDirectory(videoID, VideoData: video_data)        
    }
    
    ///////// Save video in directory and save id in coredata to retrive it in future. /////
    func saveVideo(videoId: String, localUrl: URL, videoUrl: String) {
        
        //MARK: Uploading current location to Firebase database.
        let dataInformation: NSDictionary = ["videoId": videoId, "videoUrl": videoUrl]
        
        //MARK: add firebase child node
        let child = ["/VideoIDs/Video/\(videoId)": dataInformation] // profile Image uploading
        
        self.ref.updateChildValues(child, withCompletionBlock: { (error, ref) in
            
            if error != nil {
                print("Failed uploaded video id", error!)
                return
            }
            self.saveVideoInDocumentDirectory(videoID: videoId, outputUrl: localUrl)
            self.loadingView.hide()
            print("Successfully uploaded Video id")
            self.postAlert("Success", message: "You have successfully uploaded video!")
        })
        
    }
    
    // MARK: Utility methods for app
    // Utility method to display an alert to the user.
    func postAlert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message,
                                      preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
