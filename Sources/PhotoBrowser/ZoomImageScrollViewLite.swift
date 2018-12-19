//
//  ZoomImageScrollViewLite.swift
//  TYPhotoBrowser
//
//  Created by ty on 15/9/1.
//  Copyright © 2015年 ty. All rights reserved.
//

import UIKit

class ZoomImageScrollViewLite: UIScrollView {
  
  fileprivate var imageView: UIImageView!
  private var imageSize: CGSize!
  private var singleTap: UITapGestureRecognizer!
  private var doubleTap: UITapGestureRecognizer!
  private var initialZoomScale: CGFloat! //保存初始比例，供双击放大后还原使用
  
  let maxScale: CGFloat = 3
  
  init(){
    super.init(frame: CGRect.zero)
    configUI()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    moveFrameToCenter()
    
  }
  
  private func configUI() {
    
    backgroundColor = UIColor.black
    showsHorizontalScrollIndicator = false
    showsVerticalScrollIndicator = false
    decelerationRate = UIScrollView.DecelerationRate.fast
    //    autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
    alwaysBounceHorizontal = false
    delegate = self
    isScrollEnabled = false //使图片开始是不能滑动的，因为当图片宽为600左右，scale为0.533左右时，htable无法滑动，具体原因不明
    
    //imageview
    imageView = UIImageView(frame: CGRect.zero)
    imageView.contentMode = .scaleAspectFill
    imageView.isUserInteractionEnabled = true
    
    singleTap = UITapGestureRecognizer()
    addGestureRecognizer(singleTap)
    
    doubleTap = UITapGestureRecognizer(target: self, action: #selector(ZoomImageScrollViewLite.imageViewDoubleTap(_:)))
    doubleTap.numberOfTapsRequired = 2
    imageView.addGestureRecognizer(doubleTap)
    singleTap.require(toFail: doubleTap)
    
    addSubview(imageView)
    
  }
  
  func setImage(_ image: UIImage?) {
    
    imageView.image = image
    
    guard let image = image else { return }
    
    imageSize = image.size
    //这里设置imageview的size为imagesize在当前缩放比例下的size
    imageView.frame = CGRect(x: 0, y: 0, width: image.size.width * zoomScale, height: image.size.height * zoomScale)
    
    calculateZoomScale()
  }
  
  /**
   图片点击事件
   
   :param: target target
   :param: action action
   */
  func addImageTarget(_ target: AnyObject, action: Selector) {
    singleTap.addTarget(target, action: action)
  }
  
  @objc func imageViewDoubleTap(_ tap: UITapGestureRecognizer) {
    
    guard zoomScale == initialZoomScale else {
      
      setZoomScale(initialZoomScale, animated: true)
      return
    }
    
    let position = tap.location(in: imageView)
    
    let zoomRectScale: CGFloat = 2
    
    // "/ zoomScale"将尺寸还原为zoomscale为1时的尺寸
    let zoomWidth = frame.width / zoomScale / zoomRectScale
    let zoomHeight = frame.height / zoomScale / zoomRectScale
    //position为zoomscale为1时的位置; "* zoomScale":转为当前zoomscale下的position
    //"/ imageView.frame.width * frame.width" 将点击的位置按比例转为scrollview上的位置
    //"/ zoomScale":再将位置还原为zoomscale为1时的位置
    //当zoomScale为1时还是有瑕疵，待改进
    let zoomX = position.x * zoomScale / imageView.frame.width * frame.width / zoomScale - zoomWidth / 2
    let zoomY = position.y * zoomScale / imageView.frame.height * frame.height / zoomScale - zoomHeight / 2
    
    //此值为在zoomscale为1时图片上的尺寸
    //用于表示要把这个以点击位置为center的rect区域缩放zoomRectScale倍
    //此处需要解决：当以zoomRectScale放大后，图片的高超过屏幕的高度，此时不应该再动画的时候执行moveFrameToCenter，而应根据点击位置调整
    let zoomRect = CGRect(x: zoomX, y: zoomY, width: zoomWidth, height: zoomHeight)
    zoom(to: zoomRect, animated: true)
    
  }
  
  private func calculateZoomScale() {
    
    let boundsSize = bounds.size
    
    let scaleX = boundsSize.width / imageSize.width
    let scaleY = boundsSize.height / imageSize.height
    
    var minScale = min(scaleX, scaleY)
    let maxScale = CGFloat(3)
    
    if scaleX > 1.0 && scaleY > 1.0 {
      minScale = 1.0
    }
    
    maximumZoomScale = maxScale
    minimumZoomScale = minScale
    zoomScale = minimumZoomScale
    initialZoomScale = zoomScale
    
    setNeedsLayout()
  }
  
  private func moveFrameToCenter() {
    
    let boundsSize = bounds.size
    var frameToCenter = imageView.frame
    
    if boundsSize.width > frameToCenter.size.width {
      frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / CGFloat(2)
    } else {
      frameToCenter.origin.x = 0
    }
    
    if boundsSize.height > frameToCenter.size.height {
      frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / CGFloat(2)
    } else {
      frameToCenter.origin.y = 0
    }
    
    if !imageView.frame.equalTo(frameToCenter) {
      imageView.frame = frameToCenter
    }
    
  }
  
}

extension ZoomImageScrollViewLite: UIScrollViewDelegate {
  func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    return imageView
  }
  
  func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
    isScrollEnabled = true
  }
  
  //主要是解决先缩小后再松手弹回来时不会执行moveFrameToCenter()的问题
  func scrollViewDidZoom(_ scrollView: UIScrollView) {
    setNeedsLayout()
    layoutIfNeeded()
  }
}
