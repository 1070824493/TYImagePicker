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
  
}

public extension TYImagePickerDelegate {
  
  func pickedPhoto(_ imagePickerHelper: TYImagePickerHelper, didPickResource resource: TYResourceType) {}
  func pickedPhoto(_ imagePickerHelper: TYImagePickerHelper, shouldPickResource resource: TYResourceType) -> Bool { return true }
  
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
  private weak var handlerViewController: UIViewController?
  
  public weak var delegate: TYImagePickerDelegate?
  public var maxSelectedCount: Int = 9
  public var isCrop: Bool = false
  public var type: TYImagePickerType = .albumAndCamera
  public var rowCount: Int = 4
  public var maskEnable:Bool = false
  public var resourceOption: TYResourceOption = .image
  
  public init(delegate: TYImagePickerDelegate?, handlerViewController: UIViewController? = nil) {
    self.delegate = delegate
    self.handlerViewController = handlerViewController ?? (delegate as! UIViewController)
    self.maxSelectedCount = 1
    super.init()
    
  }
  
  /******************************************************************************
   *  public Method Implementation
   ******************************************************************************/
  //MARK: - public Method Implementation
  
  open func start() {
    
    guard let _handlerViewController = handlerViewController else { return }
    
    if resourceOption == .video {
      maxSelectedCount = 1
    }
    
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
        cameraHelper.cropViewControllerTranlateType = CameraHelper.cropViewControllerTranlateType_Present
        cameraHelper.openCamera()
      } else if resourceOption.contains(.video) {
        
      }
      
    } else {
      
      showAblum()
      
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
    
    handlerViewController?.dismiss(animated: true, completion: {
      
      PhotosManager.sharedInstance.clearData()
      
      self.delegate?.pickedPhoto(self, didPickResource: resource)
      
    })
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
    
    PhotosManager.sharedInstance.fetchSelectedImages { (images) -> Void in
      
      var images: [UIImage] = images
      
      if self.isCrop && images.count == 1 {
        images = [PhotosManager.sharedInstance.cropImage(images[0])]
      }
      
      let resource: TYResourceType = .image(images: images)
      
      guard self.shouldPick(resource: resource) else { return }
      
      self.finish(with: resource)
    }
  }
  
  private func showAblum() {
    
    let viewController = PhotoColletionViewController()
    viewController.canOpenCamera = self.type != .album
    viewController.rowCount = self.rowCount
    viewController.maskEnable = self.maskEnable
    let navigationController = UINavigationController(rootViewController: viewController)
    navigationController.navigationBar.barTintColor = .black
    navigationController.navigationBar.barStyle = .black
    self.handlerViewController?.present(navigationController, animated: true, completion: nil)
    
  }
}
extension NSObject {
//    NSBundle *bundle = [NSBundle bundleForClass:[SVProgressHUD class]];
//    NSURL *url = [bundle URLForResource:@"SVProgressHUD" withExtension:@"bundle"];
//    NSBundle *imageBundle = [NSBundle bundleWithURL:url];
//
//    UIImage* infoImage = [UIImage imageWithContentsOfFile:[imageBundle pathForResource:@"info" ofType:@"png"]];
//    UIImage* successImage = [UIImage imageWithContentsOfFile:[imageBundle pathForResource:@"success" ofType:@"png"]];
//    UIImage* errorImage = [UIImage imageWithContentsOfFile:[imageBundle pathForResource:@"error" ofType:@"png"]];
    func ImageResourcePath(_ fileName: String, className:Swift.AnyClass) -> UIImage? {
        let bundle = Bundle(for: className)
        let image = UIImage(named: fileName, in: bundle, compatibleWith: nil)
//        if let url = bundle.url(forResource: "TYImagePicker", withExtension: "bundle") {
//            if let imageBundle = Bundle(url: url) {
//                let image  = UIImage(contentsOfFile: imageBundle.path(forResource: fileName, ofType: "png")!)
        
                return image
//            }
//        }
//        return nil
    }
}
