//
//  PhotoMaskView.swift
//  Yuanfenba
//
//  Created by ty on 15/12/21.
//  Copyright © 2015年 Juxin. All rights reserved.
//

import UIKit

class PhotoMaskView: UIView {
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    backgroundColor = UIColor.clear
    isUserInteractionEnabled = false
    
  }

  required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
  }
  
  override func draw(_ rect: CGRect) {
    
    guard let ctx = UIGraphicsGetCurrentContext() else { return }
    
    ctx.setFillColor(UIColor(hex: 0x000000, alpha: 0.5).cgColor)
    ctx.fill(rect);
    ctx.strokePath();
    
    ctx.clear(CGRect(x: 0, y: (rect.height - rect.width) / 2, width: rect.width, height: rect.width))
    
    ctx.setStrokeColor(red: 1, green: 1.0, blue: 1.0, alpha: 1.0)
    ctx.setLineWidth(1.0)
    ctx.addRect(CGRect(x: 1, y: (rect.height - rect.width) / 2, width: rect.width - 2, height: rect.width));
    ctx.strokePath()
  }
  
  
}
