//
//  TempVC.swift
//  QRCodeSystem
//
//  Created by MyCom on 4/26/18.
//  Copyright © 2018 MyCom. All rights reserved.
//

import UIKit

class TempVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var tableView: UITableView!
    
    var titles = ["Recorded Videos", "Youtube Videos"]
    var qrTxt: String!
    var qrImage: UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "temp", for: indexPath) as! MainListCell
        
        cell.title.text = titles[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            self.performSegue(withIdentifier: "link", sender: self)
            break
        case 1:
            self.performSegue(withIdentifier: "youtube", sender: self)
            break
        default:
            break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "link" {
            let link = segue.destination as! LinkingVideoAndQRCodVC
            link.scannedCode = self.qrTxt
            link.qrcodeImage = self.qrImage
            
            //            link.selectImage.image = qrImage.image
        }else if segue.identifier == "youtube" {
            let youtube = segue.destination as! ConnectYoutubVideoVC
            youtube.qrTxt = self.qrTxt
            youtube.qrImage = self.qrImage
        }
    }
    
}
