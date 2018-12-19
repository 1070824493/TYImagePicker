//
//  PhotoCropViewController.swift
//  PhotoBrowserProject
//
//  Created by ty on 15/12/22.
//  Copyright © 2015年 ty. All rights reserved.
//

import UIKit
import Photos

class PhotoCropViewController: UIViewController {
  
  var asset: PHAsset?
  var space: CGFloat = 0
    
    
  var originImage: UIImage!
  
  var cropImageScrollView: CropImageScrollView!
  
  var bottomBarContainerView: UIView!
  var bottomBarTransparentView: UIView!
  var completeButton: UIButton!
  var cancelButton: UIButton!
  
  var imageView: UIImageView!
  
  init(asset: PHAsset) {
    
    self.asset = asset
    
    super.init(nibName: nil, bundle: nil)
  }
  
  init(image: UIImage) {
    
    self.originImage = image
    
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.backgroundColor = UIColor.black
    
    guard let asset = asset, originImage == nil else {
      self.setupUI()
      return
    }
    
    PhotosManager.sharedInstance.fetchImage(with: asset, sizeType: .preview, handleCompletion: { (image: UIImage?, _) -> Void in
      
      guard let _image = image else {
        return
      }
      
      self.originImage = _image
      self.setupUI()
      
    })
    
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    hideNavigationBar()
    
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    hideNavigationBar()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  /******************************************************************************
   *  Target-Action
   ******************************************************************************/
  //MARK: - Target-Action
  
  @objc func onComplete() {
    
    let (xScale, yScale, sizeScalse) = cropImageScrollView.getSelectedRectScale()
    
    PhotosManager.sharedInstance.rectScale = ImageRectScale(xScale: xScale, yScale: yScale, widthScale: sizeScalse, heighScale: sizeScalse)
    
    if let imageAsset = asset {
      PhotosManager.sharedInstance.selectPhoto(with: imageAsset)
    } else {
      //如果用相机拍摄的照片需要直接裁剪
      originImage = PhotosManager.sharedInstance.cropImage(originImage)
    }
    
    PhotosManager.sharedInstance.didFinish(asset == nil ? .image(images: [originImage]) : nil)
    
  }
  
  @objc func onCancel() {
    
    if navigationController == nil {
      self.dismiss(animated: true, completion: nil)
    } else {
      navigationController!.popViewController(animated: true)
    }
    
  }
  
  /******************************************************************************
   *  Private Method Implementation
   ******************************************************************************/
  //MARK: - Private Method Implementation
  
  /**
   收起navigationbar 暂不用
   */
  fileprivate func hideNavigationBar() {
    
    if navigationController == nil {
      return
    }
    
    navigationController!.isNavigationBarHidden.toggle()
    
  }
  
  
  
  fileprivate func setupUI() {
    
    automaticallyAdjustsScrollViewInsets = false
    
    cropImageScrollView = CropImageScrollView(frame: CGRect(x: 0, y: 0, width: view.bounds.width - space * 2, height: view.bounds.height - space * 2), image: originImage, space:space)
    view.addSubview(cropImageScrollView)
    
    let maskView = PhotoMaskView(frame: view.bounds, space:space)
    view.addSubview(maskView)
    
    initBottomBar()
    
  }
  
  fileprivate func initBottomBar() {
    
    //bottomBarTransparentView
    bottomBarTransparentView = UIView()
    view.addSubview(bottomBarTransparentView)
    bottomBarTransparentView.snp.makeConstraints { (make) -> Void in
      make.right.bottom.left.equalTo(view)
      make.height.equalTo(60 + kHomeIndicator)
    }
    
    bottomBarTransparentView.alpha = 0.7
    bottomBarTransparentView.backgroundColor = UIColor(hex: 0x111111)
    
    //bottomBarContainer
    bottomBarContainerView = UIView()
    view.addSubview(bottomBarContainerView)
    bottomBarContainerView.snp.makeConstraints { (make) -> Void in
      make.right.bottom.left.equalTo(view)
      make.height.equalTo(60 + kHomeIndicator)
    }
    
    bottomBarContainerView.backgroundColor = UIColor.clear
    
    //completeButton
    completeButton = UIButton()
    bottomBarContainerView.addSubview(completeButton)
    completeButton.snp.makeConstraints { (make) -> Void in
      make.right.bottom.top.equalTo(bottomBarContainerView)
      make.width.equalTo(70)
    }
    
    completeButton.setTitle(self.GetLocalizableText(key: "TYImagePickerChooseText"), for: UIControl.State())
    completeButton.titleLabel?.font = UIFont.systemFont(ofSize: 18)
    completeButton.setTitleColor(UIColor.white, for: UIControl.State())
    completeButton.addTarget(self, action: #selector(PhotoCropViewController.onComplete), for: .touchUpInside)
    
    //selectedCountLabel
    cancelButton = UIButton()
    bottomBarContainerView.addSubview(cancelButton)
    cancelButton.snp.makeConstraints { (make) -> Void in
      make.left.bottom.top.equalTo(bottomBarContainerView)
      make.width.equalTo(60)
    }
    
    cancelButton.setTitle(self.GetLocalizableText(key: "TYImagePickerCancelText"), for: UIControl.State())
    cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 18)
    cancelButton.setTitleColor(UIColor.white, for: UIControl.State())
    cancelButton.addTarget(self, action: #selector(PhotoCropViewController.onCancel), for: .touchUpInside)
    
    imageView = UIImageView()
    view.addSubview(imageView)
    imageView.snp.makeConstraints { (make) -> Void in
      make.centerX.equalTo(view)
      make.bottom.equalTo(view)
      make.width.height.equalTo(140)
    }
  }
  
}
