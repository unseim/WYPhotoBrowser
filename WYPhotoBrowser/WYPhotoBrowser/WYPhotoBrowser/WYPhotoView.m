//
//  WYPhotoView.h
//  WYPhotoBrowser
//  简书地址：http://www.jianshu.com/u/8f8143fbe7e4
//  GitHub地址：https://github.com/unseim
//  QQ：9137279
//

#import "WYPhotoView.h"

@interface WYPhotoView()
@property (nonatomic, strong, readwrite) UIScrollView *scrollView;
@property (nonatomic, strong, readwrite) FLAnimatedImageView *imageView;
@property (nonatomic, strong, readwrite) WYLoadingView *loadingView;
@property (nonatomic, strong, readwrite) WYPhoto *photo;
@property (nonatomic, strong) id<WYWebImageProtocol> imageProtocol;
@end

@implementation WYPhotoView

- (instancetype)initWithFrame:(CGRect)frame
                imageProtocol:(nonnull id<WYWebImageProtocol>)imageProtocol
{
    if (self = [super initWithFrame:frame]) {
        _imageProtocol = imageProtocol;
        self.backgroundColor = [UIColor clearColor];
        [self addSubview:self.scrollView];
        [self.scrollView addSubview:self.imageView];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        [self addSubview:self.scrollView];
        [self.scrollView addSubview:self.imageView];
    }
    return self;
}

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView                      = [UIScrollView new];
        _scrollView.frame                = CGRectMake(0, 0, WYScreenW, WYScreenH);
        _scrollView.backgroundColor      = [UIColor clearColor];
        _scrollView.delegate             = self;
        _scrollView.clipsToBounds        = YES;
        _scrollView.multipleTouchEnabled = YES; // 多点触摸开启
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
        if (@available(iOS 11.0, *)) {
            _scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        _scrollView.wy_gestureHandleDisabled = YES;
    }
    return _scrollView;
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView               = [FLAnimatedImageView new];
        _imageView.frame         = CGRectMake(0, 0, WYScreenW, WYScreenH);
        _imageView.clipsToBounds = YES;
    }
    return _imageView;
}

- (WYLoadingView *)loadingView {
    if (!_loadingView) {
        _loadingView = [WYLoadingView loadingViewWithFrame:self.bounds style:(WYLoadingStyle)self.loadStyle];
        _loadingView.lineWidth   = 3;
        _loadingView.radius      = 12;
        _loadingView.bgColor     = [UIColor blackColor];
        _loadingView.strokeColor = [UIColor whiteColor];
    }
    return _loadingView;
}

- (void)setupPhoto:(WYPhoto *)photo {
    _photo = photo;
    
    [self loadImageWithPhoto:photo];
}

#pragma mark - 加载图片
- (void)loadImageWithPhoto:(WYPhoto *)photo {
    // 取消以前的加载
    [_imageProtocol cancelImageRequestWithImageView:self.imageView];
    
    if (photo) {
        // 每次设置数据时，恢复缩放
        [self.scrollView setZoomScale:1.0 animated:NO];
        
        // 已经加载成功，无需再加载
        if (photo.image || photo.animatedImage) {
            [self.loadingView stopLoading];
            
            if (photo.animatedImage) {
                self.imageView.animatedImage = photo.animatedImage;
            }else {
                self.imageView.image = photo.image;
            }
            
            photo.finished = YES; // 加载完成
            
            [self adjustFrame];
            
            return;
        }
        
        // 显示原来的图片
        self.imageView.image          = photo.placeholderImage;
        self.imageView.contentMode    = photo.sourceImageView.contentMode;
        self.scrollView.scrollEnabled = NO;
        // 进度条
        [self addSubview:self.loadingView];
        
        if (!photo.failed) {
            [self.loadingView startLoading];
        }
        
        [self adjustFrame];
        
        __weak typeof(self) weakSelf = self;
        wyWebImageProgressBlock progressBlock = ^(NSInteger receivedSize, NSInteger expectedSize) {
            if (self.loadStyle == WYLoadingStyleDeterminate) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                // 主线程中更新进度
                dispatch_async(dispatch_get_main_queue(), ^{
                    strongSelf.loadingView.progress = (float)receivedSize / expectedSize;
                });
            }
        };
        
        wyWebImageCompletionBlock completionBlock = ^(UIImage *image, NSURL *url, BOOL finished, NSError *error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (finished) {
                if (self.imageView.animatedImage) {
                    photo.animatedImage = self.imageView.animatedImage;
                }else {
                    photo.image = self.imageView.image;
                }
                photo.finished      = YES; // 下载完成
                
                strongSelf.scrollView.scrollEnabled = YES;
                [strongSelf.loadingView stopLoading];
            }else { // 加载失败
                photo.failed = YES;
                
                [strongSelf.loadingView stopLoading];
                
                [strongSelf addSubview:strongSelf.loadingView];
                [strongSelf.loadingView showFailure];
            }
            [strongSelf adjustFrame];
        };
        
        // 加载图片
        [_imageProtocol setImageWithImageView:self.imageView
                                          url:photo.url
                                  placeholder:photo.placeholderImage
                                     progress:progressBlock
                                   completion:completionBlock];
        
    }else {
        self.imageView.image = nil;
        self.imageView.animatedImage = nil;
        
        [self adjustFrame];
    }
}

- (void)resetFrame {
    self.scrollView.frame  = self.bounds;
    self.loadingView.frame = self.bounds;
    
    [self adjustFrame];
}

#pragma mark - 调整frame
- (void)adjustFrame {
    CGRect frame = self.scrollView.frame;
    
    if (self.imageView.image || self.imageView.animatedImage) {
        CGSize imageSize = self.imageView.animatedImage ? self.imageView.animatedImage.size : self.imageView.image.size;
        CGRect imageF = (CGRect){{0, 0}, imageSize};
        
        // 图片的宽度 = 屏幕的宽度
        CGFloat ratio = frame.size.width / imageF.size.width;
        imageF.size.width  = frame.size.width;
        imageF.size.height = ratio * imageF.size.height;
        
        // 默认情况下，显示出的图片的宽度 = 屏幕的宽度
        // 如果kIsFullWidthForLandSpace = NO，需要把图片全部显示在屏幕上
        // 此时由于图片的宽度已经等于屏幕的宽度，所以只需判断图片显示的高度>屏幕高度时，将图片的高度缩小到屏幕的高度即可
        
        if (!kIsFullWidthForLandSpace) {
            // 图片的高度 > 屏幕的高度
            if (imageF.size.height > frame.size.height) {
                CGFloat scale = imageF.size.width / imageF.size.height;
                imageF.size.height = frame.size.height;
                imageF.size.width  = imageF.size.height * scale;
            }
        }
        
        // 设置图片的frame
        self.imageView.frame = imageF;
                
        self.scrollView.contentSize = self.imageView.frame.size;
        
//        self.imageView.center = [self centerOfScrollViewContent:self.scrollView];
        
        if (imageF.size.height <= self.scrollView.bounds.size.height) {
            self.imageView.center = CGPointMake(self.scrollView.bounds.size.width * 0.5, self.scrollView.bounds.size.height * 0.5);
        }else {
            self.imageView.center = CGPointMake(self.scrollView.bounds.size.width * 0.5, imageF.size.height * 0.5);
        }
        
        // 根据图片大小找到最大缩放等级，保证最大缩放时候，不会有黑边
        CGFloat maxScale = frame.size.height / imageF.size.height;

        maxScale = frame.size.width / imageF.size.width > maxScale ? frame.size.width / imageF.size.width : maxScale;
        // 超过了设置的最大的才算数
        maxScale = maxScale > kMaxZoomScale ? maxScale : kMaxZoomScale;
        // 初始化
        self.scrollView.minimumZoomScale = 1.0;
        self.scrollView.maximumZoomScale = maxScale;
        self.scrollView.zoomScale        = 1.0;
    }else {
        frame.origin     = CGPointZero;
        CGFloat width  = frame.size.width;
        CGFloat height = width * 2.0 / 3.0;
        _imageView.bounds = CGRectMake(0, 0, width, height);
        _imageView.center = CGPointMake(frame.size.width * 0.5, frame.size.height * 0.5);
        // 重置内容大小
        self.scrollView.contentSize = self.imageView.frame.size;
    }
    self.scrollView.contentOffset = CGPointZero;
    
    // frame调整完毕，重新设置缩放
    if (self.photo.isZooming) {
        [self zoomToRect:self.photo.zoomRect animated:NO];
    }
}

- (CGPoint)centerOfScrollViewContent:(UIScrollView *)scrollView {
    CGFloat offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width) ? (scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5 : 0;
    CGFloat offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height) ? (scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5 : 0;
    CGPoint actualCenter = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX, scrollView.contentSize.height * 0.5 + offsetY);
    return actualCenter;
}

- (CGRect)frameWithWidth:(CGFloat)width height:(CGFloat)height center:(CGPoint)center {
    CGFloat x = center.x - width * 0.5;
    CGFloat y = center.y - height * 0.5;
    
    return CGRectMake(x, y, width, height);
}

- (void)zoomToRect:(CGRect)rect animated:(BOOL)animated {
    [self.scrollView zoomToRect:rect animated:YES];
}

- (void)layoutSubviews {
    
    [super layoutSubviews];
}

#pragma mark - UIScrollViewDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    self.imageView.center = [self centerOfScrollViewContent:scrollView];
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    !self.zoomEnded ? : self.zoomEnded(scrollView.zoomScale);
}

#pragma mark - UIGestureRecognizerDelegate

- (void)cancelCurrentImageLoad {
    [self.imageView sd_cancelCurrentImageLoad];
}

- (void)dealloc {
    [self cancelCurrentImageLoad];
}

@end
