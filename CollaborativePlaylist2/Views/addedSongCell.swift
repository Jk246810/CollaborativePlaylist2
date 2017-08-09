//
//  addedSongCell.swift
//  CollaborativePlaylist2
//
//  Created by Brian on 7/13/17.
//  Copyright © 2017 jamee. All rights reserved.
//

import UIKit
import Kingfisher
import NVActivityIndicatorView

class addedSongCell: UITableViewCell {
    @IBOutlet weak var songImageView: UIImageView!
    @IBOutlet weak var songNameLabel: UILabel!
    
    @IBOutlet weak var activityView: NVActivityIndicatorView!
   
    func configure(with song: Music) {
        songNameLabel.text = song.name
        let imageURL = URL(string: song.mainImage)
        songImageView.kf.setImage(with: imageURL)
    }
    


   
}
