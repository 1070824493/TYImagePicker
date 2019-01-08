//
//  CropImageScrollView.swift
//  PhotoBrowserProject
//
//  Created by ty on 15/12/22.
//  Copyright © 2015年 ty. All rights reserved.
//

import UIKit

class CropImageScrollView: UIScrollView {

  fileprivate var imageView: UIImageView!
  
  fileprivate var originImage: UIImage
  
  fileprivate var space: CGFloat = 0
  
  
  
  
  init(frame: CGRect, image: UIImage, space: CGFloat){
    
    self.originImage = image
    self.space = space
    
    super.init(frame: frame)

    configUI()
    setImage(image)
  }

  required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
  }
  
  
  func setImage(_ image: UIImage?) {
    
    if image == nil {
      return
    }
    
    imageView.image = image
    //这里设置imageview的size为imagesize在当前缩放比例下的size
    imageView.frame = CGRect(x: 0, y: 0, width: image!.size.width * zoomScale, height: image!.size.height * zoomScale)
    contentSize = imageView.frame.size
    calculateZoomScale()  //计算初始缩放比率

  }
  

  
  func getSelectedRectScale() -> (xScale: CGFloat, yScale: CGFloat, sizeScalse: CGFloat){
    
    let pointXScale = contentOffset.x / imageView.frame.width
    let pointYScale = contentOffset.y / imageView.frame.height
    let sizeScalse = frame.width / imageView.frame.width
    
    return (pointXScale, pointYScale, sizeScalse)
    
  }
  
  fileprivate func configUI() {
    if #available(iOS 11.0, *) {
        contentInsetAdjustmentBehavior = .never
    }
    
    
    delegate = self
    backgroundColor = UIColor.black
    showsHorizontalScrollIndicator = false
    showsVerticalScrollIndicator = false
    decelerationRate = UIScrollView.DecelerationRate.fast
    alwaysBounceVertical = true
    alwaysBounceHorizontal = true
    bounces = true
    clipsToBounds = false
    //imageview
    imageView = UIImageView(frame: CGRect.zero)
    imageView.backgroundColor = UIColor.black
    imageView.contentMode = .scaleAspectFill

    addSubview(imageView)
  }
  
  fileprivate func calculateZoomScale() {
    
      let boundsSize = bounds.size
      let imageSize = imageView.image!.size
      
      let scaleX = boundsSize.width / imageSize.width
      let scaleY = boundsSize.height / imageSize.height
      
      let minScale = max(scaleX, scaleY)
      let maxScale = CGFloat(3)
      
      maximumZoomScale = minScale > 1 ? minScale : maxScale
      minimumZoomScale = minScale
      zoomScale = minimumZoomScale
      setNeedsLayout()
    
    let x = max(0, (imageView.frame.width - boundsSize.width) / 2)
    let y = max(0, (imageView.frame.height - boundsSize.height) / 2)
    contentOffset = CGPoint(x: x, y: y)
    
  }

  
}

extension CropImageScrollView: UIScrollViewDelegate {
  
  func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    return imageView
  }
}
