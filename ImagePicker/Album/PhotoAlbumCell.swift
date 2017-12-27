//
//  PhotoAlbumCell.swift
//  PhotoBrowserProject
//
//  Created by ty on 15/11/27.
//  Copyright © 2015年 ty. All rights reserved.
//

import UIKit

class PhotoAlbumCell: UITableViewCell {
  
  @IBOutlet weak var thumbImageView: UIImageView!
  @IBOutlet weak var titleLabel: UILabel!

  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    
    // Configure the view for the selected state
  }
  
}
