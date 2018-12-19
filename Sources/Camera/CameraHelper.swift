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

    if UIImagePickerController.isSourceTypeAvailable(.camera) && (AVCaptureDevice.authorizationStatus(for: AVMediaType.video) == .authorized || AVCaptureDevice.authorizationStatus(for: AVMediaType.video) == .notDetermined) {
      imagePicker = UIImagePickerController()
      imagePicker.sourceType = .camera
      imagePicker.cameraDevice = .front
      imagePicker.isEditing = false
      imagePicker.delegate = self
      handlerViewController?.modalPresentationStyle = .overCurrentContext
      handlerViewController?.present(imagePicker, animated: true, completion: nil)
    } else {
      
      let alert = UIAlertController(title: self.GetLocalizableText(key: "TYImagePickerCameraNoAuth"), message: self.GetLocalizableText(key: "TYImagePickerNoAuthMessage"), preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: self.GetLocalizableText(key: "TYImagePickerCancelText"), style: .cancel, handler: nil))
      alert.addAction(UIAlertAction(title: self.GetLocalizableText(key: "TYImagePickerSureText"), style: .default, handler: { (action) in
        if let openUrl = URL(string: UIApplication.openSettingsURLString) {
          if UIApplication.shared.canOpenURL(openUrl) {
            UIApplication.shared.openURL(openUrl)
          }
        }
      }))
      UIApplication.shared.keyWindow?.rootViewController?.presentedViewController?.present(alert, animated: true, completion: nil)
    }
  }
}


extension CameraHelper: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
// Local variable inserted by Swift 4.2 migrator.
let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

    
    let type : String = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.mediaType)] as! String
    
    if type == "public.image" {
      
      let image : UIImage = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as! UIImage
      
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

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}
