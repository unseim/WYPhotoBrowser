//
//  WYPhotoView.h
//  WYPhotoBrowser
//  简书地址：http://www.jianshu.com/u/8f8143fbe7e4
//  GitHub地址：https://github.com/unseim
//  QQ：9137279
//

#import <UIKit/UIKit.h>
#import "WYPhoto.h"
#import "WYWebImageProtocol.h"
#import "WYLoadingView.h"

NS_ASSUME_NONNULL_BEGIN

@class WYPhotoView;

@interface WYPhotoView : UIView<UIScrollViewDelegate>

@property (nonatomic, strong, readonly) UIScrollView *scrollView;

@property (nonatomic, strong, readonly) FLAnimatedImageView *imageView;

@property (nonatomic, strong, readonly) WYLoadingView *loadingView;

@property (nonatomic, strong, readonly) WYPhoto *photo;

@property (nonatomic, copy) void(^zoomEnded)(NSInteger scale);

/** 是否重新布局 */
@property (nonatomic, assign) BOOL isLayoutSubViews;

@property (nonatomic, assign) WYPhotoBrowserLoadStyle loadStyle;

- (instancetype)initWithFrame:(CGRect)frame imageProtocol:(id<WYWebImageProtocol>)imageProtocol;

// 设置数据
- (void)setupPhoto:(WYPhoto *)photo;

- (void)adjustFrame;

// 缩放
- (void)zoomToRect:(CGRect)rect animated:(BOOL)animated;

// 重新布局
- (void)resetFrame;

@end

NS_ASSUME_NONNULL_END
