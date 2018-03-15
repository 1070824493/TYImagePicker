//
//  TYProgressView.m
//  ProgressViewTest
//
//  Created by ty on 16/1/7.
//  Copyright © 2016年 ty. All rights reserved.
//

#import "TYProgressView.h"

@interface TYProgressView ()

@property (nonatomic, assign) CGRect circlesSize;
//背景圆环
@property (nonatomic, strong) CAShapeLayer *backCircle;
//前面圆环
@property (nonatomic, strong) CAShapeLayer *foreCircle;

@property (nonatomic, strong) UILabel *bottomView;  //

//@property (nonatomic, strong) UIControl *maskView;  //遮罩
@property (nonatomic, strong) UIView *loadingView;  //进度条
@end

@implementation TYProgressView

- (instancetype)init
{
  self = [super init];
  if (self) {
    [self initView];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveOrientNoti) name:UIDeviceOrientationDidChangeNotification object:nil];
  }
  return self;
}

- (void)dealloc
{
  NSLog(@"%s",__func__);
  [NSNotificationCenter.defaultCenter removeObserver:self];
}

-(void)initView{

  self.frame = [UIScreen mainScreen].bounds;
  self.circlesSize = CGRectMake(30, 5, 30, 4);
  self.backgroundColor = [UIColor clearColor];
  
  [self addLoadingView];
  [self addBackCircleWithSize:self.circlesSize.origin.x lineWidth:self.circlesSize.origin.y];
  [self addForeCircleWidthSize:self.circlesSize.size.width lineWidth:self.circlesSize.size.height];
  [self addTopLabel]; //正在下载文字提示
  [self addBottomPercent];  //百分比
}

- (void)addLoadingView{
  self.loadingView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 150, 150)];
  self.loadingView.layer.cornerRadius = 10;
  self.loadingView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
  [self addSubview:self.loadingView];
  self.loadingView.center = self.center;
}

///添加百分比Label
- (void)addBottomPercent{
  self.bottomView = [[UILabel alloc]initWithFrame:CGRectMake(10, self.loadingView.frame.size.height-30-10, self.loadingView.frame.size.width-20, 30)];
  self.bottomView.text = @"0%";
  self.bottomView.textAlignment = NSTextAlignmentCenter;
  self.bottomView.textColor = [UIColor whiteColor];
  self.bottomView.font = [UIFont systemFontOfSize:13];
  [self.loadingView addSubview:self.bottomView];
}

//添加top Label
- (void)addTopLabel {
  UILabel *top = [[UILabel alloc]initWithFrame:CGRectMake(10, 10, self.loadingView.frame.size.width-20, 30)];
  
  top.text = [self getLocalizeText:@"TYProgressSyncing"];
  top.textAlignment = NSTextAlignmentCenter;
  top.textColor = [UIColor whiteColor];
  top.font = [UIFont systemFontOfSize:12];
  [self.loadingView addSubview:top];
}

- (NSString *)getLocalizeText:(NSString *)key{
  NSBundle *bundle = [NSBundle bundleForClass:NSClassFromString(@"TYImagePickerHelper")];
  return [bundle localizedStringForKey:key value:@"" table:@"TYImagePickerLocalize"];
}

//添加背景的圆环
-(void)addBackCircleWithSize:(CGFloat)radius lineWidth:(CGFloat)lineWidth{
  self.backCircle = [self createShapeLayerWithSize:radius lineWith:lineWidth color:[UIColor grayColor]];
  self.backCircle.strokeStart = 0;
  self.backCircle.strokeEnd = 1;
  self.backCircle.strokeColor = [UIColor colorWithRed:80/255.0 green:80/255.0 blue:80/255.0 alpha:0.3].CGColor;
  [self.loadingView.layer addSublayer:self.backCircle];
}

//前面的圆环
-(void)addForeCircleWidthSize:(CGFloat)radius lineWidth:(CGFloat)lineWidth{
  self.foreCircle = [self createShapeLayerWithSize:radius lineWith:lineWidth color:[UIColor greenColor]];
  
  self.foreCircle.path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(radius, radius)
                                                       radius:radius-lineWidth/2
                                                   startAngle:-M_PI/2
                                                     endAngle:M_PI/180*270
                                                    clockwise:YES].CGPath;
  self.foreCircle.strokeStart = 0;
  self.foreCircle.strokeEnd = 0;
  self.foreCircle.strokeColor = [UIColor whiteColor].CGColor;
  [self.loadingView.layer addSublayer:self.foreCircle];
}

//创建圆环
-(CAShapeLayer *)createShapeLayerWithSize:(CGFloat)radius lineWith:(CGFloat)lineWidth color:(UIColor *)color{
  CGRect foreCircle_frame = CGRectMake(self.loadingView.bounds.size.width/2-radius,
                                      self.loadingView.bounds.size.height/2-radius,
                                      radius*2,
                                      radius*2);
  
  CAShapeLayer *layer = [CAShapeLayer layer];
  layer.frame = foreCircle_frame;
  UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(radius, radius)
                                                      radius:radius-lineWidth/2
                                                  startAngle:0
                                                    endAngle:M_PI*2
                                                   clockwise:YES];
  layer.path = path.CGPath;
  layer.fillColor = [UIColor clearColor].CGColor;
  layer.backgroundColor = [UIColor clearColor].CGColor;
  layer.strokeColor = color.CGColor;
  layer.lineWidth = lineWidth;
  layer.lineCap = @"round";
  
  return layer;
}

-(void)setProgressValue:(CGFloat)progressValue{
    if (self.foreCircle) {
        self.foreCircle.strokeEnd = progressValue;
      self.bottomView.text = [NSString stringWithFormat:@"%.0f%%",progressValue * 100];
    }
}

- (void)didReceiveOrientNoti{
  self.frame = [UIScreen mainScreen].bounds;
  self.loadingView.center = self.center;
}
@end


















