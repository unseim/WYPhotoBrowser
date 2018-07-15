//
//  WYPhoto.h
//  WYPhotoBrowser
//  简书地址：http://www.jianshu.com/u/8f8143fbe7e4
//  GitHub地址：https://github.com/unseim
//  QQ：9137279
//

#import <UIKit/UIKit.h>
#import "WYPhotoBrowserConfigure.h"

NS_ASSUME_NONNULL_BEGIN

@interface WYPhoto : NSObject

/** 图片地址 */
@property (nonatomic, strong) NSURL *url;

/** 来源imageView */
@property (nonatomic, strong) UIImageView *sourceImageView;

/** 来源frame */
@property (nonatomic, assign) CGRect sourceFrame;

/** 完整的图片 */
@property (nonatomic, strong) UIImage *image;

/** 完整的gif图片 */
@property (nonatomic, strong) FLAnimatedImage *animatedImage;

/** 占位图 */
@property (nonatomic, strong) UIImage *placeholderImage;

/** 图片是否加载完成 */
@property (nonatomic, assign) BOOL finished;

/** 图片是否加载失败 */
@property (nonatomic, assign) BOOL failed;

/** 记录photoView是否缩放 */
@property (nonatomic, assign) BOOL isZooming;

/** 记录photoView缩放时的rect */
@property (nonatomic, assign) CGRect zoomRect;

@end

NS_ASSUME_NONNULL_END
