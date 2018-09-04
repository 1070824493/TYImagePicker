//
//  CameraHelper.swift
//  Yuanfenba
//
//  Created by ty on 16/3/3.
//  Copyright © 2016年 Juxin. All rights reserved.
//

import UIKit
import Photos

class CameraHelper: NSObject {

  static let cropViewControllerTranlateType_Push = 0
  static let cropViewControllerTranlateType_Present = 1

  fileprivate weak var handlerViewController: UIViewController?
  
  var isCrop = false
  var space:CGFloat = 0
  //当为false时由ImagePickerHelper来负责dismiss
  var cropViewControllerTranlateType: Int = CameraHelper.cropViewControllerTranlateType_Push
  
  var imagePicker:UIImagePickerController!

  init(handlerViewController: UIViewController) {
    
    self.handlerViewController = handlerViewController
    
  }
  
  func openCamera() {

    if UIImagePickerController.isSourceTypeAvailable(.camera) && AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) == .authorized {
      imagePicker = UIImagePickerController()
      imagePicker.sourceType = .camera
      imagePicker.cameraDevice = .front
      imagePicker.isEditing = false
      imagePicker.delegate = self
      handlerViewController?.modalPresentationStyle = .overCurrentContext
      handlerViewController?.present(imagePicker, animated: true, completion: nil)
    } else {
      let _ = UIAlertView(title: self.GetLocalizableText(key: "TYImagePickerCameraUnavailable"), message: nil, delegate: nil, cancelButtonTitle: self.GetLocalizableText(key: "TYImagePickerSureText")).show()
    }
  }
}

extension CameraHelper: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    
    let type : String = info[UIImagePickerControllerMediaType] as! String
    
    if type == "public.image" {
      
      let image : UIImage = info[UIImagePickerControllerOriginalImage] as! UIImage
      
      if isCrop {
        
        let viewController = PhotoCropViewController(image: image)
        viewController.space = self.space
        viewController.hidesBottomBarWhenPushed = true
        
        picker.dismiss(animated: false, completion: nil)

        //这种情况dismiss，是因为外部会dismiss掉PhotoCropViewController的rootViewController
        if cropViewControllerTranlateType == CameraHelper.cropViewControllerTranlateType_Push {
          
          handlerViewController?.navigationController?.pushViewController(viewController, animated: true)

          //这种情况dismiss是因为会present出新的viewcontroller，外部会dismiss新的viewcontroller
        } else if cropViewControllerTranlateType == CameraHelper.cropViewControllerTranlateType_Present{
          
          handlerViewController?.present(viewController, animated: true, completion: nil)

        }
        
      } else {
        
        picker.dismiss(animated: false, completion: nil)
        
        PhotosManager.sharedInstance.didFinish(.image(images: [image]))
        
      }
      
    }
  }
  
}
