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
    
    //先设置全屏半透明
    ctx.setFillColor(UIColor(hex: 0x000000, alpha: 0.5).cgColor)
    ctx.fill(rect);
    ctx.strokePath();
    
    if UIApplication.shared.statusBarOrientation.isPortrait {
      //清掉中间的颜色
      ctx.clear(CGRect(x: space, y: (rect.height - rect.width) / 2 + space, width: rect.width - space*2, height: rect.width - space*2))
      
      //加白色边框
      ctx.setStrokeColor(red: 1, green: 1.0, blue: 1.0, alpha: 1.0)
      ctx.setLineWidth(1.0)
      ctx.addRect(CGRect(x: space, y: (rect.height - rect.width) / 2 + space, width: rect.width - space*2, height: rect.width - space*2));
      ctx.strokePath()
      
      
      if space > 3 {
        //加四个角那玩意
        let lineLength:CGFloat = 15
        ctx.setLineWidth(3.0)
        //左上
        ctx.addLines(between: [CGPoint(x: space-2, y: (rect.height - rect.width) / 2 + space + lineLength + 3),
                               CGPoint(x: space-2, y: (rect.height - rect.width) / 2 + space - 2),
                               CGPoint(x: space + lineLength, y: (rect.height - rect.width) / 2 + space - 2)])
        //右上
        ctx.addLines(between: [CGPoint(x: rect.width - space - lineLength, y: (rect.height - rect.width) / 2 + space - 2),
                               CGPoint(x: rect.width - space + 2, y: (rect.height - rect.width) / 2 + space - 2),
                               CGPoint(x: rect.width - space + 2, y: (rect.height - rect.width) / 2 + space + lineLength + 3)])
        //左下
        ctx.addLines(between: [CGPoint(x: space-2, y: (rect.height - rect.width) / 2 + rect.width - space - lineLength - 3),
                               CGPoint(x: space-2, y: (rect.height - rect.width) / 2 + rect.width - space + 2),
                               CGPoint(x: space + lineLength, y: (rect.height - rect.width) / 2 + rect.width - space + 2)])
        //右下
        ctx.addLines(between: [CGPoint(x: rect.width - space + 2, y: (rect.height - rect.width) / 2 + rect.width - space - lineLength - 3),
                               CGPoint(x: rect.width - space + 2, y: (rect.height - rect.width) / 2 + rect.width - space + 2),
                               CGPoint(x: rect.width - space - lineLength, y: (rect.height - rect.width) / 2 + rect.width - space + 2)])
        ctx.strokePath()
      }
    }else{
      //横屏-iPad状态栏不会隐藏,需求目前仅适配iPad横屏
      let chang = max(rect.height, rect.width)
      let duan = min(rect.height, rect.width)
      //清掉中间的颜色
      let clearW = duan - space*2 - 50 - tySafeAreaInset().bottom - 20
      ctx.clear(CGRect(x: (chang - clearW) / 2, y: space + kStatusBarHeight , width: clearW, height: clearW))
      
      //加白色边框
      ctx.setStrokeColor(red: 1, green: 1.0, blue: 1.0, alpha: 1.0)
      ctx.setLineWidth(1.0)
      ctx.addRect(CGRect(x: (chang - clearW) / 2, y: space + kStatusBarHeight, width: clearW, height: clearW));
      ctx.strokePath()
      
      let minx = (chang - clearW) / 2
      let miny = space + kStatusBarHeight
      let maxx = minx + clearW
      let maxy = miny + clearW
      
      if space > 3 {
        //加四个角那玩意
        let lineLength:CGFloat = 15
        ctx.setLineWidth(3.0)
        //左上
        ctx.addLines(between: [CGPoint(x: minx-2, y: miny + lineLength + 3),
                               CGPoint(x: minx-2, y: miny - 2),
                               CGPoint(x: minx + lineLength, y: miny - 2)])
        //右上
        ctx.addLines(between: [CGPoint(x: maxx - lineLength, y: miny - 2),
                               CGPoint(x: maxx + 2, y: miny - 2),
                               CGPoint(x: maxx + 2, y: miny + lineLength + 3)])
        //左下
        ctx.addLines(between: [CGPoint(x: minx-2, y: maxy - lineLength - 3),
                               CGPoint(x: minx-2, y: maxy + 2),
                               CGPoint(x: minx + lineLength, y: maxy + 2)])
        //右下
        ctx.addLines(between: [CGPoint(x: maxx + 2, y: maxy - lineLength - 3),
                               CGPoint(x: maxx + 2, y: maxy + 2),
                               CGPoint(x: maxx - lineLength, y: maxy + 2)])
        ctx.strokePath()
      }

    }
    
    
    
  }
  
  
}
