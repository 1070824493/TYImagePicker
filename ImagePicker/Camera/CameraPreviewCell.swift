//
//  PhotoCameraPreviewCell.swift
//  ImagePickerProject
//
//  Created by ty on 16/7/6.
//  Copyright © 2016年 ty. All rights reserved.
//

import UIKit

class CameraPreviewCell: UICollectionViewCell {
  
  @IBOutlet weak var cameraPreviewView: CameraPreviewView!
  
  override func awakeFromNib() {
    super.awakeFromNib()

    cameraPreviewView.startPreview()
    
  }
}
