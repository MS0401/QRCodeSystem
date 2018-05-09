//
//  CustomCell.swift
//  Pranayama
//
//  Created by Sachin on 09/11/17.
//  Copyright © 2017 Hitesh Saini. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class CustomCell: UICollectionViewCell {
    
    @IBOutlet var imageview : UIImageView!
    @IBOutlet var durationLbl : UILabel!
    @IBOutlet var checkView: UIView!
    @IBOutlet var checkIcon: UIImageView!
    
    var player: AVPlayer!
    var playerLayer: AVPlayerLayer!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
//        self.checkIcon.image = UIImage(named: "check1")
        
    }

}
