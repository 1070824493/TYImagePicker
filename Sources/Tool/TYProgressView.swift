//
//  TYProgressView.swift
//  TYImagePicker
//
//  Created by ty on 2018/3/15.
//

import UIKit

class TYProgressView: UIView {

  var circlesSize = CGRect.zero
  //背景圆环
  var backCircle: CAShapeLayer!
  //前面圆环
  var foreCircle: CAShapeLayer!
  var bottomView: UILabel!
  //
  var loadingView: UIView!//进度条

  init() {
    super.init(frame: UIScreen.main.bounds)
    initView()
    NotificationCenter.default.addObserver(self, selector: #selector(self.didReceiveOrientNoti), name: UIDevice.orientationDidChangeNotification, object: nil)
    
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  deinit {
  
    NotificationCenter.default.removeObserver(self)
  }
  
  func initView() {
    frame = UIScreen.main.bounds
    circlesSize = CGRect(x: 30, y: 5, width: 30, height: 4)
    backgroundColor = UIColor.clear
    addLoadingView()
    addBackCircle(withSize: circlesSize.origin.x, lineWidth: circlesSize.origin.y)
    addForeCircleWidthSize(circlesSize.size.width, lineWidth: circlesSize.size.height)
    addTopLabel()
    //正在下载文字提示
    addBottomPercent()
    //百分比
  }
  
  func addLoadingView() {
    loadingView = UIView(frame: CGRect(x: 0, y: 0, width: 150, height: 150))
    loadingView.layer.cornerRadius = 10
    loadingView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.8)
    addSubview(loadingView)
    loadingView.center = center
  }
  
  ///添加百分比Label
  func addBottomPercent() {
    bottomView = UILabel(frame: CGRect(x: 10, y: loadingView.frame.size.height - 30 - 10, width: loadingView.frame.size.width - 20, height: 30))
    bottomView.text = "0%"
    bottomView.textAlignment = .center
    bottomView.textColor = UIColor.white
    bottomView.font = UIFont.systemFont(ofSize: 13)
    loadingView.addSubview(bottomView)
  }
  
  func addTopLabel() {
    let top = UILabel(frame: CGRect(x: 10, y: 10, width: loadingView.frame.size.width - 20, height: 30))
    top.text = GetLocalizableText(key: "TYProgressSyncing")
    top.textAlignment = .center
    top.textColor = UIColor.white
    top.font = UIFont.systemFont(ofSize: 12)
    loadingView.addSubview(top)
  }
  
  //添加背景的圆环
  func addBackCircle(withSize radius: CGFloat, lineWidth: CGFloat) {
    backCircle = createShapeLayer(withSize: radius, lineWith: lineWidth, color: UIColor.gray)
    backCircle.strokeStart = 0
    backCircle.strokeEnd = 1
    backCircle.strokeColor = UIColor(red: CGFloat((80 / 255.0)), green: CGFloat((80 / 255.0)), blue: CGFloat((80 / 255.0)), alpha: 0.3).cgColor
    loadingView.layer.addSublayer(backCircle)
  }
  
  //前面的圆环
  
  func addForeCircleWidthSize(_ radius: CGFloat, lineWidth: CGFloat) {
    foreCircle = createShapeLayer(withSize: radius, lineWith: lineWidth, color: UIColor.green)
    foreCircle.path = UIBezierPath(arcCenter: CGPoint(x: radius, y: radius), radius: radius - lineWidth / 2, startAngle: CGFloat((-Float.pi / 2)), endAngle: .pi / 180 * 270, clockwise: true).cgPath
    foreCircle.strokeStart = 0
    foreCircle.strokeEnd = 0
    foreCircle.strokeColor = UIColor.white.cgColor
    loadingView.layer.addSublayer(foreCircle)
  }
  
  //创建圆环
  
  func createShapeLayer(withSize radius: CGFloat, lineWith lineWidth: CGFloat, color: UIColor?) -> CAShapeLayer? {
    let foreCircle_frame = CGRect(x: loadingView.bounds.size.width / 2 - radius, y: loadingView.bounds.size.height / 2 - radius, width: radius * 2, height: radius * 2)
    let layer = CAShapeLayer()
    layer.frame = foreCircle_frame
    let path = UIBezierPath(arcCenter: CGPoint(x: radius, y: radius), radius: radius - lineWidth / 2, startAngle: 0, endAngle: CGFloat((Float.pi * 2)), clockwise: true)
    layer.path = path.cgPath
    layer.fillColor = UIColor.clear.cgColor
    layer.backgroundColor = UIColor.clear.cgColor
    layer.strokeColor = color?.cgColor
    layer.lineWidth = lineWidth
    layer.lineCap = convertToCAShapeLayerLineCap("round")
    return layer
  }
  
  var progressValue: CGFloat = 0 {
    didSet{
      foreCircle.strokeEnd = progressValue
      bottomView.text = String(format: "%.0f%%", progressValue * 100)
    }
  }
  
    @objc func didReceiveOrientNoti() {
    frame = UIScreen.main.bounds
    loadingView.center = center
  }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToCAShapeLayerLineCap(_ input: String) -> CAShapeLayerLineCap {
	return CAShapeLayerLineCap(rawValue: input)
}
