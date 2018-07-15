//
//  WYLoadingView.h
//  WYPhotoBrowser
//  简书地址：http://www.jianshu.com/u/8f8143fbe7e4
//  GitHub地址：https://github.com/unseim
//  QQ：9137279
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, WYLoadingStyle) {
    WYLoadingStyleIndeterminate,      // 不明确的加载方式
    WYLoadingStyleIndeterminateMask,  // 不明确的加载方式带阴影
    WYLoadingStyleDeterminate         // 明确的加载方式--进度条
};

@interface WYLoadingView : UIView

+ (instancetype)loadingViewWithFrame:(CGRect)frame style:(WYLoadingStyle)style;

@property (nonatomic, strong) UIButton *centerButton;

/** 线条宽度：默认4 */
@property (nonatomic, assign) CGFloat lineWidth;

/** 圆弧半径：默认24 */
@property (nonatomic, assign) CGFloat radius;

/** 圆弧的背景颜色：默认半透明黑色 */
@property (nonatomic, strong) UIColor *bgColor;

/** 进度的颜色：默认白色 */
@property (nonatomic, strong) UIColor *strokeColor;

/** 进度，loadingStyle为WYLoadingStyleDeterminate时使用 */
@property (nonatomic, assign) CGFloat progress;

@property (nonatomic, copy) void (^progressChange)(WYLoadingView *loadingView, CGFloat progress);

@property (nonatomic, copy) void (^tapToReload)(void);

/**
 开始动画方法-loadingStyle为WYLoadingStyleIndeterminate，WYLoadingStyleIndeterminateMask时使用
 */
- (void)startLoading;

/**
 结束动画方法
 */
- (void)stopLoading;

- (void)showFailure;

- (void)hideLoadingView;

// 在duration时间内加载，
- (void)startLoadingWithDuration:(NSTimeInterval)duration
                      completion:(void (^)(WYLoadingView *loadingView, BOOL finished))completion;

@end
