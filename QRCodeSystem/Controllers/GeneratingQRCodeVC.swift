//
//  GeneratingQRCodeVC.swift
//  QRCodeSystem
//
//  Created by MyCom on 4/22/18.
//  Copyright © 2018 MyCom. All rights reserved.
//

import UIKit
import MessageUI
import RSLoadingView

class GeneratingQRCodeVC: UIViewController, UITextFieldDelegate, MFMailComposeViewControllerDelegate {
    
    @IBOutlet var qrText: UITextField!
    @IBOutlet var generateBtn: UIButton!
    @IBOutlet var qrImage: UIImageView!
    @IBOutlet var slider: UISlider!
    @IBOutlet var connectVideoBtn: UIButton!
    
    var loadingView = RSLoadingView()
    var qrcodeImage: CIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.qrText.delegate = self
        self.generateBtn.layer.cornerRadius = self.generateBtn.frame.size.height/2
        self.connectVideoBtn.layer.cornerRadius = self.connectVideoBtn.frame.size.height/2
        
        self.connectVideoBtn.isHidden = true
        slider.isHidden = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        qrImage.image = nil
        qrcodeImage = nil
        qrText.text = ""
        self.connectVideoBtn.isHidden = true
        self.slider.isHidden = true
        qrText.isEnabled = true
        generateBtn.setTitle("Generate", for: UIControlState.normal)
    }

    @IBAction func GeneratingQRCode(_ sender: UIButton) {
        
        if qrcodeImage == nil {
            if qrText.text == "" {
                return
            }
            
            let data = qrText.text?.data(using: String.Encoding.isoLatin1, allowLossyConversion: false)
            
            let filter = CIFilter(name: "CIQRCodeGenerator")
            
            filter?.setValue(data, forKey: "inputMessage")
            filter?.setValue("Q", forKey: "inputCorrectionLevel")
            
            qrcodeImage = filter?.outputImage
            
            qrText.resignFirstResponder()
            
            generateBtn.setTitle("Clear", for: UIControlState.normal)
                        
            displayQRCodeImage()
        }
        else {
            qrImage.image = nil
            qrcodeImage = nil
            qrText.text = ""
            generateBtn.setTitle("Generate", for: UIControlState.normal)
            
        }
        
        qrText.isEnabled = !qrText.isEnabled
        slider.isHidden = !slider.isHidden
        connectVideoBtn.isHidden = !connectVideoBtn.isHidden
    }
    
    @IBAction func ConnectingVideo(_ sender: UIButton) {
        self.performSegue(withIdentifier: "temp", sender: self)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "temp" {
            let link = segue.destination as! TempVC
            link.qrTxt = qrText.text!
            link.qrImage = self.qrImage.image
            
//            link.selectImage.image = qrImage.image
        }
    }
    
    @IBAction func ScalQRCode(_ sender: UISlider) {
        
        qrImage.transform = CGAffineTransform(scaleX: CGFloat(slider.value), y: CGFloat(slider.value))
    }
    
    // MARK: Custom method implementation
    
    func displayQRCodeImage() {
        let scaleX = qrImage.frame.size.width / qrcodeImage.extent.size.width
        let scaleY = qrImage.frame.size.height / qrcodeImage.extent.size.height
        
        let transformedImage = qrcodeImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        qrImage.image = self.convert(cmage: transformedImage)
        
    }
    
    func convert(cmage:CIImage) -> UIImage
    {
        let context:CIContext = CIContext.init(options: nil)
        let cgImage:CGImage = context.createCGImage(cmage, from: cmage.extent)!
        let image:UIImage = UIImage.init(cgImage: cgImage)
        return image
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}
