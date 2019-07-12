//
//  ViewController.swift
//  PhotoBrowserProject
//
//  Created by ty on 15/11/25.
//  Copyright © 2015年 ty. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    //轮播图相关
    
    @IBOutlet weak var customCollectionView: UICollectionView!
    //    var customCollectionView: UICollectionView!
    var selectedImages: [UIImage]! = []
    let identifier = "imageCellIdentifier"
    override func viewDidLoad() {
        customCollectionView.register(UINib(nibName: "ImageCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: identifier)
    }

  @IBOutlet var isCropSwitch: UISwitch!
  
  @IBOutlet weak var spaceTF: UITextField!
  @IBOutlet weak var maskEnableSwitch: UISwitch!
  @IBOutlet var maxCountTextField: UITextField!
  @IBOutlet weak var numberOfColumnField: UITextField!
    
  @IBOutlet weak var columnHField: UITextField!
  //  @IBOutlet var imageViews: [UIImageView]!
  
  fileprivate lazy var imagePickerHelper: TYImagePickerHelper = {
    return TYImagePickerHelper(delegate: self)
  }()
  
  var isCrop: Bool = false
  var type: TYImagePickerType = .albumAndCamera
  var maxCount = 9
  var rowCountH = 6
  var rowCountV = 4
  var maskEnable = false
  var reourceOption: TYResourceOption = [.image]
  
  @IBAction func onStart() {
    
    imagePickerHelper.isCrop = isCrop
    imagePickerHelper.maxSelectedCount = maxCount
    imagePickerHelper.type = type
    imagePickerHelper.resourceOption = reourceOption
    imagePickerHelper.rowCountH = rowCountH
    imagePickerHelper.rowCountV = rowCountV
    imagePickerHelper.maskEnable = maskEnable
    imagePickerHelper.bottomButtonTitle = "确定"
    imagePickerHelper.bottomLabelTitle = "测试底部标题"
    imagePickerHelper.space = CGFloat(spaceTF.text == "" ? 0 : Double(spaceTF.text!)!)
    imagePickerHelper.start()
  }
  
  
  @IBAction func onMaskEnable(_ sender: UISwitch) {
    maskEnable = sender.isOn
  }
  
  @IBAction func onIsCrop(_ sender: UISwitch) {
    
    isCrop = sender.isOn
    
    if isCrop {
      maxCountTextField.text = "1"
      maxCount = 1
      spaceTF.isHidden = false
      spaceTF.text = "20"
    }else{
      spaceTF.isHidden = true
      spaceTF.text = nil
    }
    
  }
  
  @IBAction func onStyle(_ sender: UISegmentedControl) {
    switch sender.selectedSegmentIndex {
    case 0:
      type = .albumAndCamera
    case 1:
      type = .album
    case 2:
      type = .camera
    default:
      break
    }
  }
  
  @IBAction func onResourceType(_ sender: UISegmentedControl) {
    switch sender.selectedSegmentIndex {
    case 0:
      reourceOption = [.image, .data]
    case 1:
      maxCountTextField.text = "1"
      reourceOption = .video
    default:
      break
    }
  }
  
  @IBAction func onCountChange(_ sender: UITextField) {
    
    guard let maxCount = Int(sender.text!) else { return }
    
    self.maxCount = maxCount
    
    if maxCount != 1 {
      isCropSwitch.setOn(false, animated: true)
    }
  }
  
  @IBAction func onColumnChange(_ sender: UITextField) {
    
    guard let rowCount = Int(sender.text!) else { return }
    self.rowCountV = rowCount
  }
  
  @IBAction func onColumnChangeH(_ sender: UITextField) {
    guard let rowCount = Int(sender.text!) else { return }
    self.rowCountH = rowCount
  }
}

extension ViewController: TYImagePickerDelegate {
  
  func pickedPhoto(_ imagePickerHelper: TYImagePickerHelper, didPickResource resource: TYResourceType) {
    print(#function)
    if case .video(video: let tmpAVAsset) = resource, let avAsset = tmpAVAsset {
      print(avAsset)
    }
    
    if case .rawImageData(imageData: let imageData) = resource, let _imageData = imageData {
      
      print(_imageData.count)
    }
    
    if case .image(images: let images) = resource {
        print(images.count)
        if isCrop == true {
            selectedImages = [images[0]]
        }else{
            selectedImages = images
        }
        customCollectionView.reloadData()
    }
  }
  
    ///对图片进行大小压缩
    func imageWithImage(_ image:UIImage, kWidth: CGFloat) -> UIImage {
        
        var newSize:CGSize = image.size
        
        
        if image.size.width >= kWidth {
            newSize = CGSize(width: kWidth, height: kWidth)
        }
        
        UIGraphicsBeginImageContext(newSize)
        image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
  func pickedPhoto(_ imagePickerHelperDidCancel: TYImagePickerHelper) {
    print("取消选择")
  }
}

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    //MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectedImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! ImageCollectionViewCell

        cell.imgView?.image = selectedImages[indexPath.row]
        return cell
    }
    
    //MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let detail = DetailViewController(nibName: "DetailViewController", bundle: nil)
        detail.img = selectedImages[indexPath.item]
        self.present(detail, animated: true, completion: nil)
    }
}

