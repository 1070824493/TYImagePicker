//
//  PreviewPhotoViewController.swift
//  PhotoBrowserProject
//
//  Created by ty on 15/11/26.
//  Copyright © 2015年 ty. All rights reserved.
//

import UIKit
import Photos

class PreviewPhotoViewController: TYPhotoBrowserLite {
  
  private var topBarContainerView: UIView!
  private var topBarTransparentView: UIView!
  private var backButton: UIButton!
  private var selectButton: UIControl!
  private var unselectedImageView: UIImageView!
  private var selectedImageView: UIImageView!
  
  private var bottomBarContainerView: UIView!
  private var bottomBarTransparentView: UIView!
  private var completeButton: UIButton!
  private var selectedCountLabel: UILabel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    initTopbar()
    initBottomBar()
    
  }
  
  @available(iOS 11.0, *)
  override func viewSafeAreaInsetsDidChange() {
//    super.viewSafeAreaInsetsDidChange()
    self.updateSafeAreaLayout(edg: view.safeAreaInsets)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    if PhotosManager.sharedInstance.maxSelectedCount == 1 {
      
      selectButton.isHidden = true
      unselectedImageView.isHidden = true
      selectedImageView.isHidden = true
      
    }
    
    updateCount()
  }
  
  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    
    selectedCountLabel.layer.cornerRadius = selectedCountLabel.frame.size.height / 2
    selectedCountLabel.layer.masksToBounds = true

  }
 
  
  @objc func onBack() {
    _ = navigationController?.popViewController(animated: true)
  }
  
  @objc func onSelect() {
    
    PhotosManager.sharedInstance.checkImageIsInLocal(with: currentAsset) { isExistInLocal in
      
      self.setPhotoSelectedStatusWith(self.currentIndex)
      self.updateCount()
    }
  }
  
  @objc func onComplete() {
    
    PhotosManager.sharedInstance.checkImageIsInLocal(with: currentAsset) { isExistInLocal in
      
      guard isExistInLocal else { return }
      
      //如果当前没有被选择的照片，则选择当前照片
//      if PhotosManager.sharedInstance.selectedImages.isEmpty {
//        PhotosManager.sharedInstance.selectPhoto(with: self.currentAsset)
//      }
      
      PhotosManager.sharedInstance.didFinish()
    }
  }
  
  override func onClickPhoto() {
    print(#function)
  }
  
  func updateSafeAreaLayout(edg:UIEdgeInsets) {
    topBarTransparentView.snp.remakeConstraints { (make) in
      make.right.left.equalTo(view)
      make.height.equalTo(44+edg.top)
      make.top.equalTo(view)
    }
    topBarContainerView.snp.remakeConstraints { (make) -> Void in
      make.right.left.equalTo(view)
      make.height.equalTo(44+edg.top)
      make.top.equalTo(view)
    }
    backButton.snp.remakeConstraints { (make) -> Void in
      make.top.equalToSuperview().offset(edg.top)
      make.bottom.equalTo(topBarContainerView)
      make.width.equalTo(50)
      make.left.equalTo(topBarContainerView).offset(edg.left)
    }
    selectButton.snp.remakeConstraints { (make) -> Void in
      make.top.equalToSuperview().offset(edg.top)
      make.bottom.equalTo(topBarContainerView)
      make.right.equalTo(topBarContainerView).offset(-10-edg.right)
      make.width.equalTo(50)
    }
    completeButton.snp.remakeConstraints { (make) -> Void in
      make.top.bottom.equalTo(bottomBarContainerView)
      make.right.equalTo(bottomBarContainerView).offset(-edg.right)
      make.width.greaterThanOrEqualTo(50)
      make.height.equalTo(44)
    }
    view.layoutIfNeeded()
  }
  
  func initTopbar() {
    
    //topBarTransparentView
    topBarTransparentView = UIView()
    view.addSubview(topBarTransparentView)
    topBarTransparentView.snp.makeConstraints { (make) -> Void in
      make.right.left.equalTo(view)
      make.height.equalTo(64+kStatusBarOffset)
      make.top.equalTo(view)
    }
    
    topBarTransparentView.alpha = 0.7
    topBarTransparentView.backgroundColor = UIColor(hex: 0x111111)
    
    //topBarContainer
    topBarContainerView = UIView()
    view.addSubview(topBarContainerView)
    topBarContainerView.snp.makeConstraints { (make) -> Void in
      make.right.left.equalTo(view)
      make.height.equalTo(64+kStatusBarOffset)
      make.top.equalTo(view)
    }
    
    topBarContainerView.backgroundColor = UIColor.clear
    
    //backButton
    backButton = UIButton()
    topBarContainerView.addSubview(backButton)
    backButton.snp.makeConstraints { (make) -> Void in
      make.top.bottom.left.equalTo(topBarContainerView)
      make.width.equalTo(50)
    }
    
    let image = self.ImageResourcePath("back_white_arrow")
    backButton.setImage(image, for: .normal)
    backButton.addTarget(self, action: #selector(PreviewPhotoViewController.onBack), for: .touchUpInside)
    
    //selectButton
    selectButton = UIControl()
    topBarContainerView.addSubview(selectButton)
    selectButton.snp.makeConstraints { (make) -> Void in
      make.right.equalTo(topBarContainerView).offset(-10)
      make.top.bottom.equalTo(topBarContainerView)
      make.width.equalTo(50)
    }
    
    selectButton.addTarget(self, action: #selector(PreviewPhotoViewController.onSelect), for: .touchUpInside)
    
    //unselectedButton
    unselectedImageView = UIImageView()
    selectButton.addSubview(unselectedImageView)
    unselectedImageView.snp.makeConstraints { (make) -> Void in
      make.width.height.equalTo(26)
      make.center.equalTo(selectButton)
    }
    
    unselectedImageView.image = self.ImageResourcePath("imagepick_unchecked")
    
    //selectedButton
    selectedImageView = UIImageView()
    selectButton.addSubview(selectedImageView)
    selectedImageView.snp.makeConstraints { (make) -> Void in
      make.width.height.equalTo(30)
      make.center.equalTo(selectButton)
    }
    
    selectedImageView.image = self.ImageResourcePath("imagepick_checked")
    
  }
  
  func initBottomBar() {
    
    //bottomBarTransparentView
    bottomBarTransparentView = UIView()
    view.addSubview(bottomBarTransparentView)
    bottomBarTransparentView.snp.makeConstraints { (make) -> Void in
      make.right.left.equalTo(view)
      make.height.equalTo(44+tySafeAreaInset().bottom)
      make.bottom.equalTo(view)
    }
    
    bottomBarTransparentView.alpha = 0.7
    bottomBarTransparentView.backgroundColor = UIColor(hex: 0x111111)
    
    //bottomBarContainer
    bottomBarContainerView = UIView()
    view.addSubview(bottomBarContainerView)
    bottomBarContainerView.snp.makeConstraints { (make) -> Void in
      make.right.left.equalTo(view)
      make.height.equalTo(44+tySafeAreaInset().bottom)
      make.bottom.equalTo(view)
    }
    
    bottomBarContainerView.backgroundColor = UIColor.clear
    
    //completeButton
    completeButton = UIButton()
    bottomBarContainerView.addSubview(completeButton)
    completeButton.snp.makeConstraints { (make) -> Void in
      make.right.equalTo(bottomBarContainerView)
        make.top.bottom.equalTo(bottomBarContainerView)
      make.width.greaterThanOrEqualTo(50)
      make.height.equalTo(44)
    }
    
    completeButton.setTitle(self.GetLocalizableText(key: "TYImagePickerCompleteButtonText"), for: UIControl.State())
    completeButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
    completeButton.setTitleColor(UIColor.green, for: UIControl.State())
    completeButton.addTarget(self, action: #selector(PreviewPhotoViewController.onComplete), for: .touchUpInside)
    
    //selectedCountLabel
    selectedCountLabel = UILabel()
    bottomBarContainerView.addSubview(selectedCountLabel)
    selectedCountLabel.snp.makeConstraints { (make) -> Void in
      make.centerY.equalTo(completeButton)
      make.right.equalTo(completeButton.snp.left)
      make.width.height.equalTo(20)
    }
    
    selectedCountLabel.textColor = UIColor.white
    selectedCountLabel.backgroundColor = UIColor(hex: 0x03AC00)
    selectedCountLabel.textAlignment = .center
    selectedCountLabel.font = UIFont.systemFont(ofSize: 14)
    
  }
  
  override func photoDidChange() {
    super.photoDidChange()
    
    let isSelected = PhotosManager.sharedInstance.selectedImages.contains(currentAsset)
    setPhotoSelected(isSelected)
    updateCount()
    
  }
  
  func setPhotoSelectedStatusWith(_ index: Int) {
    
    let isSuccess = PhotosManager.sharedInstance.selectPhoto(with: currentAsset)
    
    if !isSuccess {
//        if PhotosManager.sharedInstance.maxSelectedCount == 9 {
          let alert = UIAlertController(title: nil, message: String(format: self.GetLocalizableText(key: "TYImagePickerMaximumText"), PhotosManager.sharedInstance.maxSelectedCount), preferredStyle: .alert)
          alert.addAction(UIAlertAction(title: self.GetLocalizableText(key: "TYImagePickerSureText"), style: .default, handler: nil))
          UIApplication.shared.keyWindow?.rootViewController?.presentedViewController?.present(alert, animated: true, completion: nil)
//        }
        return
    }
    
    let isSelected = PhotosManager.sharedInstance.getPhotoSelectedStatus(with: currentAsset)
    setPhotoStatusWithAnimation(isSelected)
  }
  
  func setPhotoStatusWithAnimation(_ isSelected: Bool) {
    
    self.setPhotoSelected(!isSelected)
    
    UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: UIView.AnimationOptions(), animations: { () -> Void in
      
      self.setPhotoSelected(isSelected)
      
      }) { _ in
        
    }
    
  }
  
  func setPhotoSelected(_ isSelected: Bool) {
    
    selectedImageView.transform = isSelected == false ? CGAffineTransform(scaleX: 0.5, y: 0.5) : CGAffineTransform.identity
    self.selectedImageView.alpha = isSelected ? 1 : 0
    
  }
  
  private func updateCount() {
    
    guard PhotosManager.sharedInstance.maxSelectedCount > 1 else {
      selectedCountLabel.isHidden = true
      return
    }
    
    let selectedCount = PhotosManager.sharedInstance.selectedImages.count
    let countString = selectedCount == 0 ? "" : "\(selectedCount)"
    
    selectedCountLabel.isHidden = selectedCount == 0
    selectedCountLabel.text = countString
    
  }
  
}
