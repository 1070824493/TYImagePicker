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

let kScreenH = UIScreen.main.bounds.height
let kScreenW = UIScreen.main.bounds.width
let longer = ((kScreenW > kScreenH) ? kScreenW : kScreenH)
let shorter = ((kScreenW < kScreenH) ? kScreenW : kScreenH)
let isIPhoneX = (longer == 812 ? true : false)
let kStatusBarOffset:CGFloat = (isIPhoneX ? 24 : 0)
let kHomeIndicator: CGFloat = (isIPhoneX ? 34 : 0)
let kBottomBarHeight: CGFloat = 50
let completionBgColorDisable = #colorLiteral(red: 0.006263995543, green: 0.1826446056, blue: 0.3904125094, alpha: 1)
let completionBgColorEnable = #colorLiteral(red: 0, green: 0.364348799, blue: 0.7843860388, alpha: 1)

class PhotoColletionViewController: UIViewController {

  private(set) var collectionView: UICollectionView!
  private var completionButton: UIButton!
  private var bottomBarLabel:UILabel!
  private var bottomBarBaseView:UIView!
  private var ablumButton: UIControl!
  private var titleLabel: UILabel!

  lazy private var backButton : UIButton = { [unowned self] in
    let back = UIButton(frame: CGRect(x: 0, y: 0, width: 60, height: 30))
    back.setAttributedTitle(NSAttributedString(string: self.GetLocalizableText(key: "TYImagePickerBackText") , attributes: [NSAttributedStringKey.foregroundColor : UIColor.white ,NSAttributedStringKey.font : UIFont.systemFont(ofSize: 16)]), for: .normal)

    back.setImage(self.ImageResourcePath("back_white_arrow"), for: .normal)
    back.contentMode = .scaleAspectFill
    back.addTarget(self, action: #selector(PhotoColletionViewController.albumButtonClick), for: .touchUpInside)
    return back
    }()
  private var ablumView: UIView!
  
  fileprivate var selectItemNum = 0
  fileprivate var cellFadeAnimation = false
  fileprivate var imageWidth: CGFloat!
  fileprivate var popViewHelp: PopViewHelper!

  fileprivate let thumbIdentifier = "PhotoThumbCell"
  fileprivate let previewIdentifier = "CameraPreviewCell"

  fileprivate let midSpace: CGFloat = 2
  fileprivate let ablumButtonWidth: CGFloat = 120
  fileprivate let selectedCountLabelWidth: CGFloat = 20
  fileprivate let indicatorWidth: CGFloat = 15

  
  var canOpenCamera = true
  var cameraHelper: CameraHelper!
  var rowCountH = 6 //横屏显示列数
  var rowCountV = 4 //竖屏显示列数
  var maskEnable = false
    

  override func viewDidLoad() {
    super.viewDidLoad()
    
    initAblum()
    NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    self.view.backgroundColor = .white
    setupUI()
    
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
  }
  
  @available(iOS 11.0, *)
  override func viewSafeAreaInsetsDidChange() {
    super.viewSafeAreaInsetsDidChange()
    updateSafeAreaLayout(edg: view.safeAreaInsets)
  }
  
    
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    updateUI()
    collectionView.reloadData()
  }
  
  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    

    let count = UIApplication.shared.statusBarOrientation == .landscapeRight || UIApplication.shared.statusBarOrientation == .landscapeLeft ? rowCountH : rowCountV

    imageWidth = (view.frame.width - midSpace * CGFloat(count - 1)) / CGFloat(count)
    let scale = UIScreen.main.scale
    PhotosManager.assetGridThumbnailSize = CGSize(width: imageWidth * scale, height: imageWidth * scale)
  }
  
  @objc func completeButtonClick() {
    
    PhotosManager.sharedInstance.didFinish()
    
  }
  
  @objc func albumButtonClick() {
    
    if ablumView != nil {
      ablumView.removeFromSuperview()
      ablumView = nil
    }
    initAblum()
    popViewHelp.showPoppingView()
  }
  
  @objc func onCancel() {
    
    PhotosManager.sharedInstance.imagePicker.delegate?.pickedPhoto(PhotosManager.sharedInstance.imagePicker)

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
    let countString = selectedCount == 0 ? self.GetLocalizableText(key: "TYImagePickerShareButtonText") : self.GetLocalizableText(key: "TYImagePickerShareButtonText") + "(\(selectedCount))"
    let bgcolor = selectedCount == 0 ? completionBgColorDisable : completionBgColorEnable
    
    completionButton.setAttributedTitle(NSAttributedString(string: countString, attributes: [NSAttributedStringKey.font : UIFont.systemFont(ofSize: 15) , NSAttributedStringKey.foregroundColor : UIColor.white]), for: .normal)
    
    completionButton.backgroundColor = bgcolor
    completionButton.isEnabled = selectedCount != 0
    
    for cell in collectionView.visibleCells {
      (cell as? PhotoThumbCell)?.updateSelectedStatus()
      (cell as? PhotoThumbCell)?.updateIsSelectable()
    }
    
    //新增遮罩修改
    if maskEnable {
      let lastCount = PhotosManager.sharedInstance.lastCount
      if selectedCount == PhotosManager.sharedInstance.maxSelectedCount || (selectedCount == PhotosManager.sharedInstance.maxSelectedCount - 1 && lastCount > selectedCount){
        collectionView.reloadData()
      }
    }
    
    
  }
  
  /******************************************************************************
   *  private  Implements
   ******************************************************************************/
   //MARK: - private Implements
  private func updateSafeAreaLayout(edg:UIEdgeInsets) {
    completionButton.snp.remakeConstraints { (make) in
      make.top.equalToSuperview().offset(10)
      make.right.equalToSuperview().offset(-10-edg.right)
      make.bottom.equalToSuperview().offset(-10-kHomeIndicator)
      make.width.equalTo(70)
    }
    bottomBarLabel.snp.remakeConstraints { (make) in
      make.left.equalToSuperview().offset(20+edg.left)
      make.top.equalToSuperview().offset(10)
      make.right.equalToSuperview()
      make.bottom.equalToSuperview().offset(-10-kHomeIndicator)
    }
  }
  
  @objc private func orientationChanged() {
    let orient = UIDevice.current.orientation
    switch orient {
    case .portrait :
      if !popViewHelp.isShow {
        self.setupUI()
      }else{
        ablumView.snp.remakeConstraints({ (make) in
          make.top.right.left.bottom.equalToSuperview()
          ablumView.layoutSubviews()
        })
        
      }
      break
    case .landscapeLeft,.landscapeRight:
      if !popViewHelp.isShow {
        self.setupUI()
      }else{
        ablumView.snp.remakeConstraints({ (make) in
          make.top.right.left.bottom.equalToSuperview()
          ablumView.layoutSubviews()
        })
      }
      break
    default:
      break
    }
  }
  
  private func setupUI() {
    initNavigationBarButton(isShow: false)
    initCollectionView()
    initBottomBar()
  }
  
  fileprivate func initCollectionView(){

    guard collectionView == nil else {
      collectionView.reloadData()
      return
    }
    let collectionViewFlowLayout = UICollectionViewFlowLayout()
    collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: collectionViewFlowLayout)
    collectionView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    collectionView.backgroundColor = UIColor.white
    collectionView.register(UINib(nibName: thumbIdentifier, bundle: Bundle(for: PhotoColletionViewController.self)), forCellWithReuseIdentifier: thumbIdentifier)
    collectionView.register(UINib(nibName: previewIdentifier, bundle: Bundle(for: PhotoColletionViewController.self)), forCellWithReuseIdentifier: previewIdentifier)
    
    collectionView.dataSource = self
    collectionView.delegate = self
    
    view.addSubview(collectionView)
    collectionView.snp.makeConstraints { (make) in
        make.top.equalToSuperview()
      make.left.right.equalToSuperview()
      make.bottom.equalToSuperview().offset(-kBottomBarHeight - kHomeIndicator)
    }
  }
  
  fileprivate func initNavigationBarButton(isShow: Bool) {
    
    //导航栏标题
    ablumButton = UIControl(frame: CGRect(x: 0 , y: 0, width: ablumButtonWidth, height: 44))
    navigationItem.titleView = ablumButton
    titleLabel = UILabel()
    ablumButton.addSubview(titleLabel)
    
    titleLabel.textColor = .white
    titleLabel.font = UIFont.systemFont(ofSize: 18)
    titleLabel.textAlignment = .center
    updateTitle()
    titleLabel.sizeToFit()
    titleLabel.center = CGPoint(x: ablumButton.frame.midX, y: ablumButton.frame.midY)
    
    //导航栏右边取消按钮
    navigationItem.rightBarButtonItem = UIBarButtonItem(title: self.GetLocalizableText(key: "TYImagePickerCancelText"), style: .plain, target: self, action: #selector(PhotoColletionViewController.onCancel))
    navigationItem.rightBarButtonItem?.setTitleTextAttributes([[NSAttributedStringKey.foregroundColor : UIColor.white , NSAttributedStringKey.font : UIFont.systemFont(ofSize: 16)], for: .normal)

    
    //导航栏左边返回按钮
    if isShow {
      titleLabel.text = "相册"
      navigationItem.leftBarButtonItem = nil
    }else{
      navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
    }
    self.navigationController?.navigationBar.isTranslucent = false
    
  }
  
  private func initAblum() {
  
    ablumView = PhotoAlbumView(frame: view.bounds, delegate: self)
    popViewHelp = PopViewHelper(superView: view, targetView: ablumView, viewPopDirection: .fromLeft, maskStatus: .normal)
    popViewHelp.showAnimateDuration = 0.35
    popViewHelp.hideAnimateDuration = 0.35
    popViewHelp.alpha = [0, 1, 1]
    popViewHelp.delegate = self
    
  }
  
  private func initBottomBar() {
  
    //创建底部工具栏
    guard bottomBarBaseView == nil else {
      bottomBarBaseView.setNeedsLayout()
      bottomBarBaseView.layoutIfNeeded()
      return
    }
    bottomBarBaseView = UIView()
    bottomBarBaseView.backgroundColor = .black
    self.view.addSubview(bottomBarBaseView)
    bottomBarBaseView.snp.makeConstraints { (make) in
      make.left.right.equalToSuperview()
      make.height.equalTo(kBottomBarHeight + kHomeIndicator)
      make.bottom.equalToSuperview()
    }
    bottomBarLabel = UILabel()

    bottomBarLabel.attributedText = NSAttributedString(string: self.GetLocalizableText(key: "TYImagePickerShareLabelText"), attributes: [NSAttributedStringKey.font : UIFont.systemFont(ofSize: 17) , NSAttributedStringKey.foregroundColor : UIColor.white])

    bottomBarLabel.backgroundColor = .black
    bottomBarLabel.textColor = .white
    bottomBarBaseView.addSubview(bottomBarLabel)
    bottomBarLabel.snp.makeConstraints { (make) in
      make.left.equalToSuperview().offset(20)
      make.top.equalToSuperview().offset(10)
      make.right.equalToSuperview()
      make.bottom.equalToSuperview().offset(-10-kHomeIndicator)
    }
    
    completionButton = UIButton(type: .custom)
    completionButton.setTitleColor(.white, for: .normal)
    completionButton.backgroundColor = completionBgColorDisable
    completionButton.layer.cornerRadius = 5
    completionButton.setAttributedTitle(NSAttributedString(string: self.GetLocalizableText(key: "TYImagePickerShareButtonText"), attributes: [NSAttributedStringKey.font : UIFont.systemFont(ofSize: 15) , NSAttributedStringKey.foregroundColor : UIColor.white]), for: .normal)

    completionButton.isEnabled = false
    completionButton.addTarget(self, action: #selector(PhotoColletionViewController.completeButtonClick), for: .touchUpInside)
    bottomBarBaseView.addSubview(completionButton)
    completionButton.snp.makeConstraints { (make) in
      make.top.equalToSuperview().offset(10)
      make.right.equalToSuperview().offset(-10)
      make.bottom.equalToSuperview().offset(-10-kHomeIndicator)
      make.width.equalTo(70)
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
  
  
  fileprivate func isLandscape() -> Bool {
    if UIDevice.current.orientation == .landscapeRight || UIDevice.current.orientation == .landscapeLeft {
      return true
    }
    return false
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
        if maskEnable {
          thumbCell.updateGrayMaskStatus()
        }
        
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
    
//    animateIndicator(true)
    initNavigationBarButton(isShow: true)
  }
  
  func popViewHelper(_ popViewHelper: PopViewHelper, willHidePoppingView targetView: UIView) {
    initNavigationBarButton(isShow: false)
//    animateIndicator(false)
  }
}
