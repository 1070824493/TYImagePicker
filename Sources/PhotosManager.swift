//
//  AssetsManager.swift
//  PhotoBrowserProject
//
//  Created by ty on 15/11/25.
//  Copyright © 2015年 ty. All rights reserved.
//

import Photos
import MobileCoreServices
import SVProgressHUD

enum PhotoSizeType {
  case thumbnail
  case preview
  case export
}

struct ImageRectScale {
  
  var xScale: CGFloat
  var yScale: CGFloat
  var widthScale: CGFloat
  var heighScale: CGFloat
  
}

class PhotosManager: NSObject {
  
  static let sharedInstance = PhotosManager()
  static var assetGridThumbnailSize = CGSize(width: 50, height: 50)
  static var assetPreviewImageSize = UIScreen.main.bounds.size
  static var assetExportImageSize = UIScreen.main.bounds.size
  
  private var assetCollectionList: [PHAssetCollection] = []
  private lazy var imageManager: PHCachingImageManager = self.initImageManager()
  private var currentAlbumFetchResult: PHFetchResult<PHAsset>!
  private(set) var currentImageAlbumFetchResult: PHFetchResult<PHAsset>!
  private(set) var selectedImages: Array<PHAsset> = []
  private(set) var selectedVideo: PHAsset?
  var HUD:TYProgressView!
  
  var currentAlbumIndex: Int? {
    didSet{
      
      guard let _currentAlbumIndex = currentAlbumIndex else { return }
      
      guard let assetCollection = getAlbumWith(_currentAlbumIndex) else { return }
      guard let imagePicker = imagePicker else { return }
      
      currentAlbumFetchResult = getFetchResult(with: assetCollection, resourceOption: imagePicker.resourceOption)
      currentImageAlbumFetchResult = getFetchResult(with: assetCollection, resourceOption: [.image])
    }
  }
  
  //裁剪图片用的比例
  var rectScale: ImageRectScale?
  
  var imagePicker: TYImagePickerHelper!
  
  var lastCount:Int = 0
  
  var maxSelectedCount: Int {
    return imagePicker.maxSelectedCount
  }
  
  var isCrop: Bool {
    return imagePicker.isCrop
  }
  
  var resourceOption: TYResourceOption {
    return imagePicker.resourceOption
  }
  
  override init() {
    
    super.init()
    
  }
  
  func initImageManager() -> PHCachingImageManager {
    
    let imageManager = PHCachingImageManager()
    imageManager.allowsCachingHighQualityImages = false
    
    return imageManager
  }
  
  //start是调用，保存当前imagePicker
  func prepare(_ imagePicker: TYImagePickerHelper) {
    
    self.imagePicker = imagePicker
    
  }
  
  //onCompletion是调用，重置数据
  func didFinish(_ resource: TYResourceType? = nil) {
    
    imagePicker?.onComplete(resource)
    
  }
  
  //未选择图片但dismiss时调用，重置数据
  func cancel() {
    
    clearData()
    
  }
  
  fileprivate func getPhotoAlbum() -> [PHAssetCollection] {
    
    guard assetCollectionList.isEmpty else {
      
      return assetCollectionList
    }

    let defaultAlbum = PHAssetCollectionSubtype.smartAlbumUserLibrary //默认为相机胶卷
    
    let albumFetchSmartResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
    let albumFetchAlbumResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
    assetCollectionList.removeAll()
    
    albumFetchSmartResult.enumerateObjects({ (object, index, point) -> Void in
      
      let assetCollection = object
      
      let title = assetCollection.localizedTitle
      
      if title != nil && assetCollection.assetCollectionSubtype != .smartAlbumAllHidden {//这个if和微信一致
//      if title != nil && assetCollection.assetCollectionSubtype != .smartAlbumAllHidden && assetCollection.estimatedAssetCount > 0{
        if assetCollection.assetCollectionSubtype == defaultAlbum {
          self.assetCollectionList.insert(assetCollection, at: 0)
          self.currentAlbumIndex = 0
        }else{
          self.assetCollectionList += [assetCollection]
        }
      }
    })
    albumFetchAlbumResult.enumerateObjects({ (object, index, point) -> Void in
      
      let assetCollection = object
      
      let title = assetCollection.localizedTitle
      
      if title != nil && assetCollection.estimatedAssetCount > 0{
          self.assetCollectionList += [assetCollection]
      }
    })
    
    return assetCollectionList
  }
  
  func getAlbumWith(_ index: Int) -> PHAssetCollection? {
    
    guard getAlbumCount() > index else {
      
      return nil
    }
    
    return getPhotoAlbum()[index]
  }
  
  func getAlbumCount() -> Int {
    
    return getPhotoAlbum().count
  }
  
  //通过相册获取照片集合
  func getFetchResult(with album: PHAssetCollection, resourceOption: TYResourceOption) -> PHFetchResult<PHAsset> {
    
    let fetchOptions = PHFetchOptions()
    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
    
    let isContainImage = resourceOption.contains(.image) || resourceOption.contains(.data)
    
    if isContainImage && !resourceOption.contains(.video){
      fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
    }
    
    if !isContainImage && resourceOption.contains(.video) {
      fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
    }
    
    if isContainImage && resourceOption.contains(.video) {
      fetchOptions.predicate = NSPredicate(format: "mediaType = %d OR mediaType = %d", PHAssetMediaType.video.rawValue, PHAssetMediaType.image.rawValue)
    }
    
    let fetchResult = PHAsset.fetchAssets(in: album, options: fetchOptions)
    
    return fetchResult
  }
  
  func getImageCountInCurrentAlbum() -> Int {
    
    guard currentAlbumIndex != nil &&  currentAlbumFetchResult != nil else {
      print("currentAlbumIndex is nil")
      return 0
    }
    
    return currentAlbumFetchResult.count
  }
  
  func getAssetInCurrentAlbum(with index: Int) -> PHAsset? {
    
    guard currentAlbumFetchResult.count > index else {
      return nil
    }
    let asset = currentAlbumFetchResult[index]
    return asset
  }
  
  func fetchImage(with asset: PHAsset, sizeType: PhotoSizeType, handleCompletion: @escaping (_ image: UIImage?, _ isInICloud: Bool) -> Void) {
    
    var imageSize = CGSize.zero
    let imageRequestOptions = getImageRequestOptions(with: sizeType)
    
    switch sizeType {
    case .thumbnail:
      imageSize = PhotosManager.assetGridThumbnailSize
    case .preview:
      imageSize = PhotosManager.assetPreviewImageSize
    case .export:
      imageSize = PHImageManagerMaximumSize
    }
    
    imageManager.requestImage(for: asset, targetSize: imageSize, contentMode: .aspectFill, options: imageRequestOptions) { (image: UIImage?, info) -> Void in
      
      handleCompletion(image, info?[PHImageResultIsInCloudKey] as? Bool ?? false)
    }
  }
  
  
  /// 用于判断是否是云端
  func fetchThumbImage(with asset: PHAsset, handleCompletion: @escaping (_ isInICloud: Bool) -> Void) {
    
    let imageRequestOptions = PHImageRequestOptions()
    imageRequestOptions.isSynchronous = true
    imageRequestOptions.isNetworkAccessAllowed = false

    imageManager.requestImageData(for: asset, options: imageRequestOptions) { (data, str, orient, info) in
      if data != nil {
        handleCompletion(false)
      }else{
        handleCompletion(true)
      }
    }
  }
  
  func fetchImage(with albumIndex: Int, imageIndex: Int, sizeType: PhotoSizeType, handleCompletion: @escaping (_ image: UIImage?, _ isInICloud: Bool) -> Void) {
    
    if currentAlbumIndex != albumIndex {
      currentAlbumIndex = albumIndex
    }
    
    if getAlbumCount() <= albumIndex {
      handleCompletion(nil, false)
    }
    
    if currentAlbumFetchResult.count <= imageIndex {
      handleCompletion(nil, false)
    }
    
    guard let asset = getAssetInCurrentAlbum(with: imageIndex) else {
      handleCompletion(nil, false)
      return
    }
    
    fetchImage(with: asset, sizeType: sizeType, handleCompletion: handleCompletion)
    
  }
  
  func fetchExportImage(with asset: PHAsset, handleCompletion: @escaping (_ image: UIImage?, _ isInICloud: Bool) -> Void, progressHandler: @escaping PHAssetImageProgressHandler){
    
    let imageRequestOptions = PHImageRequestOptions()
    
    imageRequestOptions.isNetworkAccessAllowed = true
    imageRequestOptions.progressHandler = progressHandler
    imageRequestOptions.deliveryMode = .highQualityFormat
    imageRequestOptions.isSynchronous = false
    
    PHImageManager.default().requestImageData(for: asset, options: imageRequestOptions) { (imgData, str, orient, info) in
      
      if let data = imgData, let image = UIImage(data: data) {
        handleCompletion(image, info?[PHImageResultIsInCloudKey] as? Bool ?? false)
      }else{
        handleCompletion(nil,false)
      }
    }
  }
  
  func checkImageIsInLocal(with asset: PHAsset, completion: @escaping ((Bool) -> Void)) {
    
    fetchThumbImage(with: asset) { (isInICloud) in
      completion(!isInICloud)
    }
  }
  
  func checkVideoIsInLocal(with asset: PHAsset, completion: @escaping ((Bool) -> Void)) {
    
    fetchVideo(videoAsset: asset) { (avAsset, isInICloud) in
      
      if  avAsset == nil {
        
        if isInICloud {
          
          let alertView = UIAlertView(title: self.GetLocalizableText(key: "TYImagePickerCanNotChooseVideo"), message: self.GetLocalizableText(key: "TYImagePickerCanNotChooseMessage"), delegate: nil, cancelButtonTitle: nil, otherButtonTitles: self.GetLocalizableText(key: "TYImagePickerSureText"))
          alertView.show()
          
        } else {
          
          let alertView = UIAlertView(title: "", message: self.GetLocalizableText(key: "TYImagePickerChooseFailedVideo"), delegate: nil, cancelButtonTitle: nil, otherButtonTitles: self.GetLocalizableText(key: "TYImagePickerSureText"))
          alertView.show()
          
        }
        
        return
      }
      
      completion(true)
    }
  }
  
  /**
   选择图片或取消选择图片
   
   - parameter index: 照片index
   
   - returns: 是否成功，如果不成功，则以达到最大数量
   */
  
  @discardableResult
  func selectPhoto(with asset: PHAsset) -> Bool {
    
    let isExist = getPhotoSelectedStatus(with: asset)
    
    if isExist {
      lastCount = selectedImages.count
      let index:Int = selectedImages.index(of: asset)!
      selectedImages.remove(at: index)
    } else {
      
      if imagePicker.maxSelectedCount == selectedImages.count {
        
        return false
        
      } else {
        lastCount = selectedImages.count
        selectedImages.append(asset)
        return true
        
      }
    }
    
    return true
  }
  
  @discardableResult
  func selectVideo(with asset: PHAsset) -> Bool {
    
    guard let videoIndex = selectedVideo else {
      selectedVideo = asset
      return true
    }
    
    selectedVideo = videoIndex == asset ? nil : asset
    
    return selectedVideo != nil
  }
  
  /**
   获取该照片的选中状态
   
   - parameter index: 照片index
   
   - returns: true为已被选中，false为未选中
   */
  func getPhotoSelectedStatus(with asset: PHAsset) -> Bool {
    return selectedImages.contains(asset)
  }
  
  func clearData() {
    
    imagePicker = nil
    
    rectScale = nil
    selectedImages.removeAll()
    selectedVideo = nil
    assetCollectionList.removeAll()
    
  }
  
  func removeSelectionIfMaxCountIsOne() {
    if imagePicker.maxSelectedCount == 1 {
      selectedImages.removeAll()
    }
    selectedVideo = nil
  }
  
  func fetchSelectedImages(_ handleCompletion: @escaping (_ images: [UIImage]) -> Void) {

    self.HUD = TYProgressView()
    UIApplication.shared.keyWindow?.addSubview(self.HUD)
    self.HUD.center = (self.HUD.superview?.center)!
    self.HUD.isHidden = true
    getAllSelectedImageInCurrentAlbum(with: selectedImages, imageList: [], handleCompletion: handleCompletion)
    
  }
  
  func getAllSelectedImageInCurrentAlbum(with imageAssets: [PHAsset], imageList: [UIImage],  handleCompletion: @escaping (_ images: [UIImage]) -> Void) {
    
    if imageAssets.count == 0 {
      if self.HUD.isHidden == false {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
          handleCompletion(imageList)
          self.HUD.removeFromSuperview()
          self.HUD = nil
        }
      }else{
        handleCompletion(imageList)
        self.HUD.removeFromSuperview()
        self.HUD = nil
      }
      return
    }
    
    fetchExportImage(with: imageAssets[0], handleCompletion: { (image, isInCloud) in
      if image == nil {
        self.HUD.removeFromSuperview()
        self.HUD = nil
        SVProgressHUD.setDefaultStyle(.dark)
        SVProgressHUD.setMinimumDismissTimeInterval(2)
        SVProgressHUD.showError(withStatus: self.GetLocalizableText(key: "TYImagePickerSyncFailed"))
        return
      }
      let percent:Float = Float(imageList.count) / Float(self.selectedImages.count) + 1 / Float(self.selectedImages.count)
      self.HUD.progressValue = CGFloat(percent)
      self.getAllSelectedImageInCurrentAlbum(with: Array(imageAssets[1..<imageAssets.count]), imageList: imageList + [image!], handleCompletion: handleCompletion)
      
    }) { (progress, error, point, info) in
      DispatchQueue.main.async {
        self.HUD.isHidden = false
      }
      if error == nil {
        let percent:Float = Float(imageList.count) / Float(self.selectedImages.count) + Float(progress) / Float(self.selectedImages.count)
        print(percent)
        DispatchQueue.main.async {
          self.HUD.progressValue = CGFloat(percent)
        }
      }
    }
  }
  
  func fetchVideo(videoAsset: PHAsset, handleCompletion: @escaping (_ avAsset: AVAsset?, _ isInICloud: Bool) -> Void) {
    
    let videoRequestOptions = PHVideoRequestOptions()
    videoRequestOptions.isNetworkAccessAllowed = false
    videoRequestOptions.deliveryMode = .fastFormat
    
    imageManager.requestAVAsset(forVideo: videoAsset, options: videoRequestOptions) { (avAsset, _, info) in
      
      DispatchQueue.main.async {
        handleCompletion(avAsset, info?[PHImageResultIsInCloudKey] as? Bool ?? false)
      }
    }
  }
  
  func fetchSelectedVideo(handleCompletion: @escaping (_ avAsset: AVAsset?, _ isInICloud: Bool) -> Void) {
    
    guard let selectedVideo = selectedVideo else { return }
    
    fetchVideo(videoAsset: selectedVideo, handleCompletion: handleCompletion)
  }
  
  func fetchSelectedImageData(_ handleCompletion: @escaping (_ data: Data?, _ isGIF: Bool) -> Void) {
    
    guard let selectedAsset = selectedImages.first else {
      handleCompletion(nil, false)
      return
    }
    
    fetchRawImageData(with: selectedAsset, handleCompletion: handleCompletion)
    
  }
  
  func fetchRawImageData(with asset: PHAsset, handleCompletion: @escaping (_ imageData: Data?, _ isGIF: Bool) -> Void) {
    
    let imageRequestOptions = getImageRequestOptions(with: .export)
    
    imageManager.requestImageData(for: asset, options: imageRequestOptions) { (data, uti, _, info) in
      
      handleCompletion(data, uti ?? "" == kUTTypeGIF as String)
    }
  }
  
  func cropImage(_ originImage: UIImage) -> UIImage {
    
    guard let _rectScale = rectScale else {
      return originImage
    }
    
    let cropRect = CGRect(x: originImage.size.width * _rectScale.xScale, y: originImage.size.height * _rectScale.yScale, width: originImage.size.width * _rectScale.widthScale, height: originImage.size.width * _rectScale.heighScale)
    
    let orientationRect = originImage.transformOrientationRect(cropRect)
    
    let cropImageRef = originImage.cgImage?.cropping(to: orientationRect)
    
    guard let _cropImageRef = cropImageRef else { return originImage }
    
    let cropImage = UIImage(cgImage: _cropImageRef, scale: 1, orientation: originImage.imageOrientation)
    
    return cropImage
    
  }
  
  private func getImageRequestOptions(with sizeType: PhotoSizeType) -> PHImageRequestOptions {
    
    let imageRequestOptions = PHImageRequestOptions()
    
    switch sizeType {
    case .thumbnail:
      imageRequestOptions.isSynchronous = false
      imageRequestOptions.resizeMode = .fast
      imageRequestOptions.deliveryMode = .fastFormat
      imageRequestOptions.isNetworkAccessAllowed = false
      
    case .preview:
      imageRequestOptions.isSynchronous = false
      imageRequestOptions.resizeMode = .fast
      imageRequestOptions.deliveryMode = .highQualityFormat
      imageRequestOptions.isNetworkAccessAllowed = false
      
    case .export:
      imageRequestOptions.isSynchronous = true
      imageRequestOptions.resizeMode = .none
      imageRequestOptions.deliveryMode = .highQualityFormat
      imageRequestOptions.isNetworkAccessAllowed = false
      
    }
    
    return imageRequestOptions
  }
}
