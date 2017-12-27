//
//  PhotoColletionViewController.swift
//  PhotoBrowserProject
//
//  Created by ty on 15/11/25.
//  Copyright © 2015年 ty. All rights reserved.
//

import UIKit
import Photos
import SnapKit

class PhotoColletionViewController: UIViewController {
  
  private(set) var collectionView: UICollectionView!
  private var selectedCountLabel: UILabel!
  private var completionLabel: UILabel!
  private var completionButton: UIControl!
  private var ablumButton: UIControl!
  private var titleLabel: UILabel!
  private var indicatorImageView: UIImageView!
  private var ablumView: UIView!
  
  fileprivate var selectItemNum = 0
  fileprivate var cellFadeAnimation = false
  fileprivate var imageWidth: CGFloat!
  fileprivate var popViewHelp: PopViewHelper!

  fileprivate let thumbIdentifier = "PhotoThumbCell"
  fileprivate let previewIdentifier = "CameraPreviewCell"

  fileprivate let midSpace: CGFloat = 2
  fileprivate let rowCount = 3
  fileprivate let ablumButtonWidth: CGFloat = 120
  fileprivate let selectedCountLabelWidth: CGFloat = 20
  fileprivate let indicatorWidth: CGFloat = 15
  
  var canOpenCamera = true
  var cameraHelper: CameraHelper!

  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupUI()
    
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    updateUI()
    collectionView.reloadData()
  }
  
  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    
    imageWidth = (view.frame.width - midSpace * CGFloat(rowCount - 1)) / CGFloat(rowCount)
    
    let scale = UIScreen.main.scale
    PhotosManager.assetGridThumbnailSize = CGSize(width: imageWidth * scale, height: imageWidth * scale)
    
  }
  
  @objc func completeButtonClick() {
    
    completionButton.removeFromSuperview()

    PhotosManager.sharedInstance.didFinish()
    
  }
  
  @objc func albumButtonClick() {
    
    if popViewHelp.isShow {
      popViewHelp.hidePoppingView()
    } else {
      popViewHelp.showPoppingView()
    }
    
  }
  
  @objc func onCancel() {
    
    completionButton.removeFromSuperview()

    dismiss(animated: true) {
      PhotosManager.sharedInstance.cancel()
    }
  }
  
  func goToPhotoBrowser() {
    
    let photoBrowser = PreviewPhotoViewController(delegate: self, quitBlock: { () -> Void in
      _ = self.navigationController?.popViewController(animated: true)
    })
    photoBrowser.delegate = self
    navigationController?.pushViewController(photoBrowser, animated: true)
    
  }
  
  func updateUI() {
    
    let selectedImageCount = PhotosManager.sharedInstance.selectedImages.count
    let selectedVideoCount = PhotosManager.sharedInstance.selectedVideo == nil ? 0 : 1
    let selectedCount = max(selectedImageCount, selectedVideoCount)
    let countString = selectedCount == 0 ? "" : "\(selectedCount)"
    
    selectedCountLabel.isHidden = selectedCount == 0
    selectedCountLabel.text = countString
    
    completionLabel.isEnabled = selectedCount != 0
    completionButton.isEnabled = selectedCount != 0
    
    for cell in collectionView.visibleCells {
      
      (cell as? PhotoThumbCell)?.updateSelectedStatus()
      (cell as? PhotoThumbCell)?.updateIsSelectable()

    }
  }
  
  /******************************************************************************
   *  private  Implements
   ******************************************************************************/
   //MARK: - private Implements
  
  private func setupUI() {
    
    initAblum()
    initNavigationBarButton()
    
    let collectionViewFlowLayout = UICollectionViewFlowLayout()
    collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: collectionViewFlowLayout)
    collectionView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    collectionView.backgroundColor = UIColor.white
    collectionView.register(UINib(nibName: thumbIdentifier, bundle: Bundle(for: PhotoColletionViewController.self)), forCellWithReuseIdentifier: thumbIdentifier)
    collectionView.register(UINib(nibName: previewIdentifier, bundle: Bundle(for: PhotoColletionViewController.self)), forCellWithReuseIdentifier: previewIdentifier)

    collectionView.dataSource = self
    collectionView.delegate = self
    view.addSubview(collectionView)
    
    initCompletionButton()

    navigationItem.leftBarButtonItem = UIBarButtonItem(title: "取消", style: .plain, target: self, action: #selector(PhotoColletionViewController.onCancel))
    
    navigationItem.leftBarButtonItem?.setTitleTextAttributes([NSAttributedStringKey.foregroundColor : UIColor.red,NSAttributedStringKey.font : UIFont.systemFont(ofSize: 14)], for: .normal)
    
  }
  
  private func initNavigationBarButton() {
    
    ablumButton = UIControl(frame: CGRect(x: 0 , y: 0, width: ablumButtonWidth, height: 44))
    navigationItem.titleView = ablumButton
    
    ablumButton.addTarget(self, action: #selector(PhotoColletionViewController.albumButtonClick), for: .touchUpInside)
    
    titleLabel = UILabel()
    ablumButton.addSubview(titleLabel)
    
    titleLabel.textColor = .jx_main
    titleLabel.font = UIFont.systemFont(ofSize: 18)
    titleLabel.textAlignment = .center
    updateTitle()
    titleLabel.sizeToFit()
    titleLabel.center = CGPoint(x: ablumButton.frame.midX, y: ablumButton.frame.midY)
    
    indicatorImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: indicatorWidth, height: indicatorWidth))
    ablumButton.addSubview(indicatorImageView)
    indicatorImageView.center.y = titleLabel.center.y
    indicatorImageView.frame.origin.x = titleLabel.frame.maxX
    
    indicatorImageView.contentMode = .scaleAspectFit
    let image = UIImage(named: "ic_down_arrow", in: Bundle(for: PreviewPhotoViewController.self), compatibleWith: nil)
    indicatorImageView.image = image
    
  }
  
  private func initAblum() {
  
    ablumView = PhotoAlbumView(frame: view.bounds, delegate: self)
    popViewHelp = PopViewHelper(superView: view, targetView: ablumView, viewPopDirection: .above, maskStatus: .normal)
    popViewHelp.showAnimateDuration = 0.35
    popViewHelp.hideAnimateDuration = 0.35
    popViewHelp.alpha = [0, 1, 1]
    popViewHelp.delegate = self
    
  }
  
  private func initCompletionButton() {
  
    completionButton = UIControl(frame: CGRect(x: view.frame.width - 60, y: 0, width: 60, height: 44))
    completionButton.addTarget(self, action: #selector(PhotoColletionViewController.completeButtonClick), for: .touchUpInside)
    navigationController?.navigationBar.addSubview(completionButton)
    
    selectedCountLabel = UILabel(frame: CGRect(x: 0, y: (completionButton.frame.height - selectedCountLabelWidth) / 2, width: selectedCountLabelWidth, height: selectedCountLabelWidth))
    selectedCountLabel.backgroundColor = UIColor(hex: 0x03AC00)
    selectedCountLabel.font = UIFont.systemFont(ofSize: 14)
    selectedCountLabel.textColor = UIColor.white
    selectedCountLabel.textAlignment = .center
    selectedCountLabel.layer.cornerRadius = selectedCountLabel.frame.size.height / 2
    selectedCountLabel.layer.masksToBounds = true
  
    completionButton.addSubview(selectedCountLabel)
    
    completionLabel = UILabel(frame: CGRect(x: selectedCountLabelWidth, y: 0, width: completionButton.frame.width - selectedCountLabelWidth, height: 44))
    completionLabel.textColor = UIColor(hex: 0x03AC00)
    completionLabel.text = "完成"
    completionLabel.font = UIFont.systemFont(ofSize: 14)
    completionLabel.textAlignment = .center
    completionButton.addSubview(completionLabel)
    
  }
  
  private func checkCamera(){
    
    let authStatus : AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
    if (AVAuthorizationStatus.denied == authStatus || AVAuthorizationStatus.restricted == authStatus){
      
      let alertController = UIAlertController(title: "相机被禁用", message: "请在设置－隐私－相机中开启", preferredStyle: .alert)
      let okAction = UIAlertAction(title: "确定", style: .default, handler: nil)
      alertController.addAction(okAction)
      present(alertController, animated: true, completion: nil)
    }
  }
  
  fileprivate func getPhotoFromCamera(){
    
    if cameraHelper == nil {
      cameraHelper = CameraHelper(handlerViewController: self)
    }
    
    cameraHelper.cropViewControllerTranlateType = CameraHelper.cropViewControllerTranlateType_Push
    cameraHelper.isCrop = PhotosManager.sharedInstance.isCrop
    cameraHelper.openCamera()
  }

  fileprivate func updateTitle() {
    
    if let currentAlbumIndex = PhotosManager.sharedInstance.currentAlbumIndex {
      let title = PhotosManager.sharedInstance.getAlbumWith(currentAlbumIndex)?.localizedTitle ?? "相册"
      titleLabel.text = title
      
    }
  }
  
  fileprivate func animateIndicator(_ isIndicatShowing: Bool) {
    
    UIView.animate(withDuration: 0.3, animations: { 
      
      let transform = CGAffineTransform(rotationAngle: isIndicatShowing ? CGFloat(Double.pi) : 0)
      self.indicatorImageView.transform = transform
      
    }) 
  }
}

extension PhotoColletionViewController: UICollectionViewDataSource {
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    
    var photoNum = PhotosManager.sharedInstance.getImageCountInCurrentAlbum()
    
    if canOpenCamera {
      photoNum += 1
    }
    return photoNum
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
    let showPreview = canOpenCamera && indexPath.row == 0
    
    let identifier = showPreview ? previewIdentifier : thumbIdentifier
    
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
    
    if !showPreview {
      
      let thumbCell = cell as! PhotoThumbCell
      
      thumbCell.photoColletionViewController = self
      
      if let asset = PhotosManager.sharedInstance.getAssetInCurrentAlbum(with: canOpenCamera == true ? indexPath.row - 1 : indexPath.row) {
        
        thumbCell.setAsset(asset)

      }
    }
    
    return cell
  }
}

extension PhotoColletionViewController: UICollectionViewDelegateFlowLayout {
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return CGSize(width: imageWidth, height: imageWidth)
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return midSpace
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
    return midSpace
  }
}

extension PhotoColletionViewController: UICollectionViewDelegate {
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    
    let row = indexPath.row
    
    if canOpenCamera && row == 0 {
      
      getPhotoFromCamera()
      
    } else {
      
      let indexInAblum = canOpenCamera == true ? row - 1 : row
      
      guard let asset = PhotosManager.sharedInstance.getAssetInCurrentAlbum(with: indexInAblum) else { return }
      
      if asset.mediaType == .image && PhotosManager.sharedInstance.selectedVideo == nil {
       
        PhotosManager.sharedInstance.checkImageIsInLocal(with: asset) { isExistInLocal in
          
          guard isExistInLocal else { return }
          
          if PhotosManager.sharedInstance.isCrop {
            
            self.navigationController?.pushViewController(PhotoCropViewController(asset: asset), animated: true)
            
          } else {
            
            
            self.selectItemNum = PhotosManager.sharedInstance.currentImageAlbumFetchResult.index(of: asset)
            self.goToPhotoBrowser()
            
          }
          
        }
      }
      
      if PhotosManager.sharedInstance.resourceOption == .video {
        
        PhotosManager.sharedInstance.checkVideoIsInLocal(with: asset) { isExistInLocal in
          
          guard isExistInLocal else { return }
          
          PhotosManager.sharedInstance.selectVideo(with: asset)
          PhotosManager.sharedInstance.didFinish()
          
        }
      }
    }
  }
}

extension PhotoColletionViewController: PhotoAlbumViewDelegate {
  
  func photoAlbumView(_ photoAlbumView: PhotoAlbumView, didSelectAtIndex index: Int) {
    updateTitle()
    popViewHelp.hidePoppingView()
    collectionView.reloadData()
    cellFadeAnimation = true


  }
  
  @objc(collectionView:willDisplayCell:forItemAtIndexPath:) func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {

    guard cellFadeAnimation else { return }
    
    cell.alpha = 0
    
    UIView.animate(withDuration: 0.3, animations: { 
      
      cell.alpha = 1

      }, completion: { finish in
        
      self.cellFadeAnimation = false

    }) 
  }
}

extension PhotoColletionViewController: TYPhotoBrowserLiteDelegate {
  
  func numberOfImage(_ photoBrowser: TYPhotoBrowserLite) -> Int {
    
    return PhotosManager.sharedInstance.currentImageAlbumFetchResult.count
    
  }
  
  func firstDisplayIndex(_ photoBrowser: TYPhotoBrowserLite) -> Int {
    
    return selectItemNum
  }
  
  func photoBrowser(photoBrowser: TYPhotoBrowserLite, assetForIndex index: Int) -> PHAsset {
    return PhotosManager.sharedInstance.currentImageAlbumFetchResult[index]
  }
}

extension PhotoColletionViewController: PopViewHelperDelegate {
  
  func popViewHelper(_ popViewHelper: PopViewHelper, willShowPoppingView targetView: UIView) {
    
    animateIndicator(true)
  }
  
  func popViewHelper(_ popViewHelper: PopViewHelper, willHidePoppingView targetView: UIView) {
    
    animateIndicator(false)
  }
}
