//
//  PhotosetViewController.m
//  NetEaseNews
//
//  Created by wangshiyu13 on 15/2/1.
//  Copyright (c) 2015年 wangshiyu13. All rights reserved.
//
#import "WSYNetworkTools.h"
#import "NSString+StringExt.h"
#import "UIImageView+WebCache.h"
#import "UIImage+Scale.h"
#import "StatusBarHUD.h"

#import "PhotosetViewController.h"
#import "PhotosetModel.h"
#import "PhotosetPhotosModel.h"
#import "SingleModel.h"
@interface PhotosetViewController () <UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UIButton *replyBtn;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITextView *descText;
@property (weak, nonatomic) IBOutlet UILabel *countX;
@property (weak, nonatomic) IBOutlet UILabel *countCur;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollview;
@property (nonatomic, strong) PhotosetModel *photosetModel;
@property (nonatomic, assign) NSInteger currentIndex;
@end

@implementation PhotosetViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadData];
    [self setupFirstImageView];
}

- (void)loadData {
    // 发送一个GET请求, 获得新闻的详情数据
    NSString *photosetID =self.singleModel.photosetID;
    photosetID = [[photosetID componentsSeparatedByString:@"|"] lastObject];
    NSString *url = [NSString stringWithFormat:@"http://c.m.163.com/photo/api/set/0096/%@.json", photosetID];
    self.photosetModel = [PhotosetModel objectWithJSONData:[NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]] returningResponse:nil error:nil]];
    NSLog(@"%@", self.photosetModel);
    
    [self.replyBtn setTitle:[NSString stringWithFormat:@"%@跟帖", self.singleModel.replyCount] forState:UIControlStateNormal];
    self.replyBtn.titleLabel.font = [UIFont systemFontOfSize:13];
    UIImage *normalImg = [UIImage imageNamed:@"contentview_commentbacky"];
    UIImage *highlightedImg = [UIImage imageNamed:@"contentview_commentbacky_selected"];
    CGFloat normalW = normalImg.size.width;
    CGFloat normalH = normalImg.size.height;
    CGFloat highW = highlightedImg.size.width;
    CGFloat highH = highlightedImg.size.height;
    // 拉伸图片, 采用平铺的方式来拉伸,防止变形.
    normalImg = [normalImg resizableImageWithCapInsets:UIEdgeInsetsMake(normalH * 0.5, normalW * 0.5, normalH * 0.5, normalW * 0.5)];
    highlightedImg = [highlightedImg resizableImageWithCapInsets:UIEdgeInsetsMake(highH * 0.5, highW * 0.5, highH * 0.5, highW * 0.5)];
    // 设置按钮的背景
    [self.replyBtn setBackgroundImage:normalImg forState:UIControlStateNormal];
    [self.replyBtn setBackgroundImage:highlightedImg forState:UIControlStateHighlighted];
    self.replyBtn.contentEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 15);

    self.titleLabel.text = self.photosetModel.setname;
    self.countX.text = [NSString stringWithFormat:@"/%@",self.photosetModel.imgsum];
    [self setupScrollView];
}

- (void)setupScrollView {
    for (int i = 0; i < self.photosetModel.photos.count; i++) {
        UIImageView *backView = [[UIImageView alloc] initWithFrame:CGRectMake(i * [UIScreen mainScreen].bounds.size.width, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:backView.bounds];
        imageView.multipleTouchEnabled = YES;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        [backView addSubview:imageView];
        [self.scrollview addSubview:backView];
    }
    self.scrollview.contentSize = CGSizeMake(self.photosetModel.photos.count * [UIScreen mainScreen].bounds.size.width, 0);
}

- (void)setupFirstImageView {
    UIImageView *backIV = [self.scrollview.subviews firstObject];
    UIImageView *firstIV = [backIV.subviews firstObject];
    PhotosetPhotosModel *photo = self.photosetModel.photos[0];
    [firstIV sd_setImageWithURL:[NSURL URLWithString:photo.imgurl] placeholderImage:nil options:SDWebImageHighPriority];
    self.countCur.text = @"1";
    self.descText.text = photo.note;
    self.descText.textColor = [UIColor whiteColor];
    self.descText.font = [UIFont systemFontOfSize:13];
    
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *image = [CIImage imageWithContentsOfURL:[NSURL URLWithString:photo.timgurl]];
    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [filter setValue:image forKey:kCIInputImageKey];
    [filter setValue:@10.0f forKey: @"inputRadius"];
    CIImage *result = [filter valueForKey:kCIOutputImageKey];
    CGImageRef outImage = [context createCGImage: result fromRect:[result extent]];
    UIImage *blurImage = [UIImage imageWithCGImage:outImage];
    backIV.image = blurImage;
    backIV.contentMode = UIViewContentModeScaleAspectFill;
    backIV.clipsToBounds = YES;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    NSInteger index = scrollView.contentOffset.x / scrollView.frame.size.width;
    self.currentIndex = index;
    PhotosetPhotosModel *photo = self.photosetModel.photos[index];
    self.countCur.text = [NSString stringWithFormat:@"%ld", (long)index + 1];
    self.descText.text = photo.note;
    self.descText.textColor = [UIColor whiteColor];
    self.descText.font = [UIFont systemFontOfSize:13];
    
    UIImageView *backIV = self.scrollview.subviews[index];
    UIImageView *imageView = [backIV.subviews firstObject];
    [imageView sd_setImageWithURL:[NSURL URLWithString:photo.imgurl] placeholderImage:nil options:SDWebImageHighPriority];
    
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *image = [CIImage imageWithContentsOfURL:[NSURL URLWithString:photo.timgurl]];
    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [filter setValue:image forKey:kCIInputImageKey];
    [filter setValue:@10.0f forKey: @"inputRadius"];
    CIImage *result = [filter valueForKey:kCIOutputImageKey];
    CGImageRef outImage = [context createCGImage: result fromRect:[result extent]];
    UIImage *blurImage = [UIImage imageWithCGImage:outImage];
    backIV.image = blurImage;
    backIV.contentMode = UIViewContentModeScaleAspectFill;
    backIV.clipsToBounds = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.scrollview.pagingEnabled = YES;
}

- (IBAction)backBtnClick {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)replyBtnClick {
}
- (IBAction)favorite {
}
- (IBAction)share {
}
- (IBAction)download {
    PhotosetPhotosModel *photos = self.photosetModel.photos[self.currentIndex];
    [self saveImageToAlbum:photos.imgurl];
}

- (void)saveImageToAlbum:(NSString *)src
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"友情提示" message:@"是否要保存图片到相册?" preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:@"是" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        
        // 保存图片 SDImageCache
        UIImage *image = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:src];
        // 调用HUD
        UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:withError:info:), nil);
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"否" style:UIAlertActionStyleCancel handler:nil]];
    
    // 显示
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)image:(UIImage *)image withError:(NSError *)error info:(void *)contextInfo;
{
    // 提醒用户图片保存成功还是失败
    if (error) { // 图片保存失败
        [StatusBarHUD showError:@"图片保存失败"];
    } else { // 图片保存成功
        [StatusBarHUD showSuccess:@"图片保存成功"];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end