//
//  WYPhotoBrowser.h
//  WYPhotoBrowser
//  简书地址：http://www.jianshu.com/u/8f8143fbe7e4
//  GitHub地址：https://github.com/unseim
//  QQ：9137279
//

#import <UIKit/UIKit.h>
#import "WYPhotoView.h"

NS_ASSUME_NONNULL_BEGIN

// 判断iPhone X
#define KIsiPhoneX ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO)
#define kSaveTopSpace       (KIsiPhoneX ? 24.0f : 0)   // iPhone X顶部多出的距离（刘海）
#define kSaveBottomSpace    (KIsiPhoneX ? 34.0f : 0)   // iPhone X底部多出的距离

@class WYPhotoBrowser;

typedef void(^layoutBlock)(WYPhotoBrowser *photoBrowser, CGRect superFrame);

@protocol WYPhotoBrowserDelegate <NSObject>

@optional

// 滚动到一半时索引改变
- (void)photoBrowser:(WYPhotoBrowser *)browser didChangedIndex:(NSInteger)index;

// 滚动结束时索引改变
- (void)photoBrowser:(WYPhotoBrowser *)browser scrollEndedIndex:(NSInteger)index;

// 单击事件
- (void)photoBrowser:(WYPhotoBrowser *)browser singleTapWithIndex:(NSInteger)index;

// 长按事件
- (void)photoBrowser:(WYPhotoBrowser *)browser longPressWithIndex:(NSInteger)index;

// 旋转事件
- (void)photoBrowser:(WYPhotoBrowser *)browser onDeciceChangedWithIndex:(NSInteger)index isLandspace:(BOOL)isLandspace;

// 上下滑动消失
// 开始滑动时
- (void)photoBrowser:(WYPhotoBrowser *)browser panBeginWithIndex:(NSInteger)index;

// 结束滑动时 disappear：是否消失
- (void)photoBrowser:(WYPhotoBrowser *)browser panEndedWithIndex:(NSInteger)index willDisappear:(BOOL)disappear;


- (void)photoBrowser:(WYPhotoBrowser *)browser willLayoutSubViews:(NSInteger)index;

@end

@interface WYPhotoBrowser : UIViewController

/** 底部内容试图 */
@property (nonatomic, strong, readonly) UIView        *contentView;
/** 图片模型数组 */
@property (nonatomic, strong, readonly) NSArray       *photos;
/** 当前索引 */
@property (nonatomic, assign, readonly) NSInteger     currentIndex;
/** 是否是横屏 */
@property (nonatomic, assign, readonly) BOOL          isLandspace;
/** 当前设备的方向 */
@property (nonatomic, assign, readonly) UIDeviceOrientation currentOrientation;
/** 显示方式 */
@property (nonatomic, assign) WYPhotoBrowserShowStyle showStyle;
/** 隐藏方式 */
@property (nonatomic, assign) WYPhotoBrowserHideStyle hideStyle;
/** 图片加载方式 */
@property (nonatomic, assign) WYPhotoBrowserLoadStyle loadStyle;
/** 代理 */
@property (nonatomic, weak) id<WYPhotoBrowserDelegate> delegate;

/** 是否禁止屏幕旋转监测 */
@property (nonatomic, assign) BOOL isScreenRotateDisabled;

/** 是否禁用默认单击事件 */
@property (nonatomic, assign) BOOL isSingleTapDisabled;

/** 是否显示状态栏，默认NO：不显示状态栏 */
@property (nonatomic, assign) BOOL isStatusBarShow;

/** 滑动消失时是否隐藏原来的视图：默认YES */
@property (nonatomic, assign) BOOL isHideSourceView;

/** 滑动切换图片时，是否恢复上（下）一张图片的缩放程度，默认是NO */
@property (nonatomic, assign) BOOL isResumePhotoZoom;

// 初始化方法

/**
 创建图片浏览器

 @param photos 包含WYPhoto对象的数组
 @param currentIndex 当前的页码
 @return 图片浏览器对象
 */
+ (instancetype)photoBrowserWithPhotos:(NSArray<WYPhoto *> *)photos currentIndex:(NSInteger)currentIndex;

- (instancetype)initWithPhotos:(NSArray<WYPhoto *> *)photos currentIndex:(NSInteger)currentIndex;

/**
 为浏览器添加自定义遮罩视图

 @param coverViews  视图数组
 @param layoutBlock 布局
 */
- (void)setupCoverViews:(NSArray *)coverViews layoutBlock:(layoutBlock)layoutBlock;

/**
 显示图片浏览器

 @param vc 控制器
 */
- (void)showFromVC:(UIViewController *)vc;

+ (void)setImageManagerClass:(Class<WYWebImageProtocol>)cls;

@end

NS_ASSUME_NONNULL_END
