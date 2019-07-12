//
//  ImageUploadViewController.swift
//
//
//  Created by ty on 15/4/23.
//  Copyright (c) 2015年 ty. All rights reserved.
//

import UIKit
import Photos

public protocol TYImagePickerDelegate: NSObjectProtocol {
  
  func pickedPhoto(_ imagePickerHelper: TYImagePickerHelper, didPickResource resource: TYResourceType)
  func pickedPhoto(_ imagePickerHelper: TYImagePickerHelper, shouldPickResource resource: TYResourceType) -> Bool
  func pickedPhoto(_ imagePickerHelperDidCancel: TYImagePickerHelper)
}

public extension TYImagePickerDelegate {
  
  func pickedPhoto(_ imagePickerHelper: TYImagePickerHelper, didPickResource resource: TYResourceType) {}
  func pickedPhoto(_ imagePickerHelper: TYImagePickerHelper, shouldPickResource resource: TYResourceType) -> Bool { return true }
  func pickedPhoto(_ imagePickerHelperDidCancel: TYImagePickerHelper){}
}

public enum TYImagePickerType {
  case album
  case camera
  case albumAndCamera
}

public struct TYResourceOption: OptionSet {
  public var rawValue: Int = 0
  public init(rawValue: Int) {
    self.rawValue = rawValue
  }
  
  public static var image = TYResourceOption(rawValue: 1 << 0)
  public static var video = TYResourceOption(rawValue: 1 << 1)
  public static var data = TYResourceOption(rawValue: 1 << 2)
}

public enum TYResourceType {
  case image(images: [UIImage])
  case video(video: AVAsset?)
  case rawImageData(imageData: Data?)
}

open class TYImagePickerHelper: NSObject {
  
  private var cameraHelper: CameraHelper!
  public weak var handlerViewController: UIViewController? //跳转的控制器
  
  public weak var delegate: TYImagePickerDelegate?
  public var maxSelectedCount: Int = 9
  public var isCrop: Bool = false
  public var type: TYImagePickerType = .albumAndCamera
  public var rowCountH: Int = 6
  public var rowCountV: Int = 4
  public var maskEnable:Bool = false
  public var resourceOption: TYResourceOption = .image
  
  public var space: CGFloat = 0 //裁剪框间隔
  public var bottomLabelTitle:String? = nil   //底部文字说明
  public var bottomButtonTitle:String? = nil  //底部按钮文字
  
  public init(delegate: TYImagePickerDelegate?, handlerViewController: UIViewController? = nil) {
    self.delegate = delegate
    self.handlerViewController = handlerViewController ?? (delegate as! UIViewController)
    super.init()
  }
  
  /******************************************************************************
   *  public Method Implementation
   ******************************************************************************/
  //MARK: - public Method Implementation
  
  open func start() {
    
    guard let _handlerViewController = handlerViewController else { return }
    
//    if resourceOption == .video {
//      maxSelectedCount = 1
//    }
    
    if maxSelectedCount <= 0 {
      maxSelectedCount = 1
    }
    
    if maxSelectedCount > 1 {
      isCrop = false
    }
    
    PhotosManager.sharedInstance.prepare(self)
    
    if type == .camera {
      
      if resourceOption.contains(.image) {
        cameraHelper = CameraHelper(handlerViewController: _handlerViewController)
        cameraHelper.isCrop = isCrop
        cameraHelper.space = space
        cameraHelper.cropViewControllerTranlateType = CameraHelper.cropViewControllerTranlateType_Present
        cameraHelper.openCamera()
      } else if resourceOption.contains(.video) {
        
      }
      
    }
    else{

        switch PHPhotoLibrary.authorizationStatus(){
            
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ (status: PHAuthorizationStatus) in
                if status == PHAuthorizationStatus.authorized {
                    DispatchQueue.main.async {
                        self.showAblum()
                    }
                }else{
                    self.delegate?.pickedPhoto(self)
                }
            })
        case .restricted,.denied:
            
            let alert = UIAlertController(title: self.GetLocalizableText(key: "TYImagePickerNoAuthTitle"), message: self.GetLocalizableText(key: "TYImagePickerNoAuthMessage"), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: self.GetLocalizableText(key: "TYImagePickerCancelText"), style: .default, handler: nil))
            alert.addAction(UIAlertAction(title: self.GetLocalizableText(key: "TYImagePickerSureText"), style: .default, handler: { (action) in
              if let openUrl = URL(string: UIApplication.openSettingsURLString) {
                if UIApplication.shared.canOpenURL(openUrl) {
                    UIApplication.shared.open(openUrl, options: [:], completionHandler: nil)
                }
              }
            }))
            UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
          
        case .authorized:
            showAblum()
        @unknown default:
            break
        }
    }
  }
  
  func onComplete(_ resource: TYResourceType?) {
    
    if let resource = resource {
      
      guard shouldPick(resource: resource) else { return }
      
      finish(with: resource)
      return
    }
    
    if let _ = PhotosManager.sharedInstance.selectedVideo  {
      fetchVideo()
      return
    }
    
    if resourceOption.contains(.data) && PhotosManager.sharedInstance.selectedImages.count == 1 {
      fetchImageDatas()
    } else {
      fetchImages()
    }
  }
  
  private func shouldPick(resource: TYResourceType) -> Bool {
    
    let should = delegate?.pickedPhoto(self, shouldPickResource: resource) ?? true
    
    if !should {
      PhotosManager.sharedInstance.removeSelectionIfMaxCountIsOne()
    }
    
    return should
  }
  
  private func finish(with resource: TYResourceType) {
//    handlerViewController?.dismiss(animated: true, completion: <#T##(() -> Void)?##(() -> Void)?##() -> Void#>)
    PhotosManager.sharedInstance.clearData()
    self.delegate?.pickedPhoto(self, didPickResource: resource)
  }
  
  private func fetchVideo() {
    
    PhotosManager.sharedInstance.fetchSelectedVideo(handleCompletion: { (avAsset, _) in
      
      let resource: TYResourceType = .video(video: avAsset)
      
      guard self.shouldPick(resource: resource) else { return }
      
      self.finish(with: resource)
      
    })
  }
  
  private func fetchImageDatas() {
    
    PhotosManager.sharedInstance.fetchSelectedImageData({ (data, isGIF) in
      
      var resource: TYResourceType!
      
      //在选了.data的情况下，是gif时，一定返回data
      //如果不是gif，若选了.image则返回image, 否则返回data
      
      if !isGIF && self.resourceOption.contains(.image) {
        guard let data = data, let image = UIImage(data: data) else { return }
        
        var images: [UIImage] = [image]
        
        if self.isCrop {
          images = [PhotosManager.sharedInstance.cropImage(image)]
        }
        
        resource = .image(images: images)
        
      } else {
        
        resource = .rawImageData(imageData: data)
        
      }
      
      guard self.shouldPick(resource: resource) else { return }
      
      self.finish(with: resource)
      
    })
  }
  
  private func fetchImages() {
    
    PhotosManager.sharedInstance.fetchSelectedImages({ (images) in
      var images: [UIImage] = images
      
      if self.isCrop && images.count == 1 {
        images = [PhotosManager.sharedInstance.cropImage(images[0])]
      }
      
      let resource: TYResourceType = .image(images: images)
      
      guard self.shouldPick(resource: resource) else { return }
      
      self.finish(with: resource)
    })
  }
  
  private func showAblum() {
    
    let viewController = PhotoColletionViewController()
    viewController.canOpenCamera = self.type != .album
    viewController.rowCountH = self.rowCountH
    viewController.rowCountV = self.rowCountV
    viewController.maskEnable = self.maskEnable
    viewController.bottomLabelTitle = self.bottomLabelTitle
    viewController.bottomButtonTitle = self.bottomButtonTitle
    viewController.space = self.space
    let navigationController = UINavigationController(rootViewController: viewController)
    navigationController.navigationBar.barTintColor = .black
    navigationController.navigationBar.barStyle = .black
    self.handlerViewController?.present(navigationController, animated: true, completion: nil)
    
  }
}
extension NSObject {
    func ImageResourcePath(_ fileName: String) -> UIImage? {
        let bundle = Bundle(for: TYImagePickerHelper.self)
        let image  = UIImage(named: fileName, in: bundle, compatibleWith: nil)
        return image
    }
  
    public func GetLocalizableText(key: String) -> String {
        let bundle = Bundle(for: TYImagePickerHelper.self)
        return bundle.localizedString(forKey: key, value: "", table: "TYImagePickerLocalize")
    }
}

