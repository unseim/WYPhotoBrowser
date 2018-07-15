//
//  WYPhotoBrowserConfigure.h
//  WYPhotoBrowser
//  简书地址：http://www.jianshu.com/u/8f8143fbe7e4
//  GitHub地址：https://github.com/unseim
//  QQ：9137279
//

#ifndef WYPhotoBrowserConfigure_h
#define WYPhotoBrowserConfigure_h

#import "UIScrollView+WYGestureHandle.h"
#import "FLAnimatedImage.h"

#if __has_include(<SDWebImage/UIImageView+WebCache.h>)
#import <SDWebImage/UIView+WebCache.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/SDWebImageManager.h>
#else
#import "UIView+WebCache.h"
#import "UIImageView+WebCache.h"
#import "SDWebImageManager.h"
#endif


#define WYScreenW [UIScreen mainScreen].bounds.size.width
#define WYScreenH [UIScreen mainScreen].bounds.size.height

#define kMaxZoomScale               2.0f

#define kIsFullWidthForLandSpace    YES

#define kPhotoViewPadding           10

#define kAnimationDuration          0.25f

// 图片浏览器的显示方式
typedef NS_ENUM(NSUInteger, WYPhotoBrowserShowStyle) {
    WYPhotoBrowserShowStyleNone,       // 直接显示，默认方式
    WYPhotoBrowserShowStyleZoom,       // 缩放显示，动画效果
    WYPhotoBrowserShowStylePush        // push方式展示
};

// 图片浏览器的隐藏方式
typedef NS_ENUM(NSUInteger, WYPhotoBrowserHideStyle) {
    WYPhotoBrowserHideStyleZoom,           // 缩放
    WYPhotoBrowserHideStyleZoomScale,      // 缩放和滑动缩小
    WYPhotoBrowserHideStyleZoomSlide       // 缩放和滑动平移
};

// 图片浏览器的加载方式
typedef NS_ENUM(NSUInteger, WYPhotoBrowserLoadStyle) {
    WYPhotoBrowserLoadStyleIndeterminate,        // 不明确的加载方式
    WYPhotoBrowserLoadStyleIndeterminateMask,    // 不明确的加载方式带阴影
    WYPhotoBrowserLoadStyleDeterminate           // 明确的加载方式带进度条
};

#endif /* WYPhotoBrowserConfigure_h */
