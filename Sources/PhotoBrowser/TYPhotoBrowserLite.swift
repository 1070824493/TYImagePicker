//
//  TYPhotoBrowserLite.swift
//  TYPhotoBrowserLite
//
//  Created by ty on 15/9/2.
//  Copyright © 2015年 ty. All rights reserved.
//

import UIKit
import Photos

protocol TYPhotoBrowserLiteDelegate: NSObjectProtocol {
  
  func numberOfImage(_ photoBrowser: TYPhotoBrowserLite) -> Int
  
  func firstDisplayIndex(_ photoBrowser: TYPhotoBrowserLite) -> Int
  
  func photoBrowser(photoBrowser: TYPhotoBrowserLite, assetForIndex index: Int) -> PHAsset
}

class TYPhotoBrowserLite: UIViewController {
  
  fileprivate var mainCollectionView: UICollectionView!
  
  weak var delegate: TYPhotoBrowserLiteDelegate?
  var quitBlock: (() -> Void)?
  var currentIndex: Int = 0 {
    didSet{
      currentAsset = PhotosManager.sharedInstance.currentImageAlbumFetchResult[currentIndex]
      photoDidChange()
    }
  }
  var currentAsset: PHAsset!
  
  var isDidShow = false //用于标记次VC是否已经呈现
  
  let IDENTIFIER_IMAGE_CELL = "ZoomImageCell"
  let padding: CGFloat = 6
  
  init(delegate: TYPhotoBrowserLiteDelegate, quitBlock: (() -> Void)? = nil) {
    
    self.delegate = delegate
    self.quitBlock = quitBlock
    super.init(nibName: nil, bundle: nil)

  }
  
  required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
  
    initView()
    
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    let photoIndex = delegate?.firstDisplayIndex(self) ?? 0
    mainCollectionView.setContentOffset(CGPoint(x: CGFloat(photoIndex) * mainCollectionView.frame.width, y: 0), animated: false)
    
    //当默认显示第0张时，currentIndex不会被赋值，需要手动赋值，以便调用photoDidChange
    if delegate?.firstDisplayIndex(self) != nil && (delegate?.firstDisplayIndex(self))! == 0 {
      currentIndex = 0
    }
    
    hideNavigationBar()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    hideNavigationBar()
  }
  
  override var prefersStatusBarHidden : Bool {
    return true
  }
  
  fileprivate func initView() {
    
    automaticallyAdjustsScrollViewInsets = false
    view.backgroundColor = UIColor.black
    view.clipsToBounds = true
    
    initMainTableView()
    
  }
  
  fileprivate func initMainTableView() {
    
    let mainCollectionViewFrame = CGRect(x: -padding, y: view.bounds.minY, width: view.bounds.width + padding * 2, height: view.bounds.height)
    
    let mainCollectionViewLayout = UICollectionViewFlowLayout()
    mainCollectionViewLayout.itemSize = mainCollectionViewFrame.size
    mainCollectionViewLayout.minimumInteritemSpacing = 0
    mainCollectionViewLayout.minimumLineSpacing = 0
    mainCollectionViewLayout.scrollDirection = .horizontal
    
    mainCollectionView = UICollectionView(frame: mainCollectionViewFrame, collectionViewLayout: mainCollectionViewLayout)
    mainCollectionView.delegate = self
    mainCollectionView.dataSource = self
    mainCollectionView.isPagingEnabled = true
    mainCollectionView.backgroundColor = UIColor.black
    mainCollectionView.register(PhotoCollectionLiteCell.self, forCellWithReuseIdentifier: "PhotoCollectionLiteCell")
    view.addSubview(mainCollectionView)
    mainCollectionView.snp.makeConstraints { (make) in
      make.left.equalToSuperview().offset(-padding)
      make.top.equalToSuperview()
      make.width.equalToSuperview().offset(padding*2)
      make.height.equalToSuperview()
    }
  }
  
  /**
   收起navigationbar 暂不用
   */
  fileprivate func hideNavigationBar() {
    
    if navigationController == nil {
      return
    }
    
    let isHidden = navigationController!.isNavigationBarHidden
    navigationController!.setNavigationBarHidden(!isHidden, animated: true)
    
  }
  
  @objc func onClickPhoto() {
    
    quitBlock?()
    
  }
  
  func photoDidChange() { }
  
}

extension TYPhotoBrowserLite: UICollectionViewDataSource {
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return delegate?.numberOfImage(self) ?? 0
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionLiteCell", for: indexPath) as! PhotoCollectionLiteCell
    
    cell.zoomImageScrollView.addImageTarget(self, action: #selector(TYPhotoBrowserLite.onClickPhoto))
    
    cell.padding = padding
    
    if let asset = delegate?.photoBrowser(photoBrowser: self, assetForIndex: indexPath.row) {
      cell.asset = asset
    }
    
    return cell
    
  }
}

extension TYPhotoBrowserLite: UICollectionViewDelegateFlowLayout {
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    
    //更新currentIndex
    let cellPoint = view.convert(mainCollectionView.center, to: mainCollectionView)
    let showPhotoIndex = mainCollectionView.indexPathForItem(at: cellPoint)
    
    if let _showPhotoIndex = showPhotoIndex , currentIndex != _showPhotoIndex.row {
      currentIndex = showPhotoIndex!.row
    }
    
  }
  
}
