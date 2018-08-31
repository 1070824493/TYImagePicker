//
//  PhotoMaskView.swift
//  Yuanfenba
//
//  Created by ty on 15/12/21.
//  Copyright © 2015年 Juxin. All rights reserved.
//

import UIKit

class PhotoMaskView: UIView {
  
  var space:CGFloat = 0
  
  
  init(frame: CGRect, space:CGFloat) {
    self.space = space
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
    
    ctx.clear(CGRect(x: space, y: (rect.height - rect.width) / 2 + space, width: rect.width - space*2, height: rect.width - space*2))
    
    ctx.setStrokeColor(red: 1, green: 1.0, blue: 1.0, alpha: 1.0)
    ctx.setLineWidth(1.0)
    ctx.addRect(CGRect(x: space, y: (rect.height - rect.width) / 2 + space, width: rect.width - space*2, height: rect.width - space*2));
    ctx.strokePath()
  }
  
  
}
