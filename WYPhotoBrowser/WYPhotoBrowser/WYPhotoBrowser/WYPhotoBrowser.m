//
//  WYPhotoBrowser.m
//  WYPhotoBrowser
//  简书地址：http://www.jianshu.com/u/8f8143fbe7e4
//  GitHub地址：https://github.com/unseim
//  QQ：9137279
//

#import "WYPhotoBrowser.h"
#import "WYWebImageManager.h"

static Class imageManagerClass = nil;

@interface WYPhotoBrowser()<UIScrollViewDelegate>
{
    UILabel  *_countLabel;
    CGPoint  _startLocation;
}

@property (nonatomic, strong, readwrite) UIView *contentView;

@property (nonatomic, strong, readwrite) NSArray *photos;
@property (nonatomic, assign, readwrite) NSInteger currentIndex;
@property (nonatomic, assign, readwrite) BOOL       isLandspace;
@property (nonatomic, assign, readwrite) UIDeviceOrientation currentOrientation;

@property (nonatomic, strong) UIScrollView *photoScrollView;

@property (nonatomic, strong) NSMutableArray *visiblePhotoViews;
@property (nonatomic, strong) NSMutableSet *reusablePhotoViews;

@property (nonatomic, strong) UIViewController *fromVC;

@property (nonatomic, assign) BOOL isShow;

@property (nonatomic, strong) NSArray *coverViews;
@property (nonatomic, copy) layoutBlock layoutBlock;

/** 记录上一次的设备方向 */
@property (nonatomic, assign) UIDeviceOrientation originalOrientation;

/** 正在发生屏幕旋转 */
@property (nonatomic, assign) BOOL isRotation;

/** 状态栏正在发生变化 */
@property (nonatomic, assign) BOOL isStatusBarChanged;
/** 状态栏是否显示 */
@property (nonatomic, assign) BOOL isStatusBarShowing;

@property (nonatomic, assign) BOOL isPortraitToUp;

@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;

@property (nonatomic, strong) id<WYWebImageProtocol> imageProtocol;

@end

@implementation WYPhotoBrowser

#pragma mark - 懒加载
- (UIScrollView *)photoScrollView {
    if (!_photoScrollView) {
        CGRect frame = self.view.bounds;
        frame.origin.x   -= kPhotoViewPadding;
        frame.size.width += (2 * kPhotoViewPadding);
        _photoScrollView = [[UIScrollView alloc] initWithFrame:frame];
        _photoScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _photoScrollView.pagingEnabled  = YES;
        _photoScrollView.delegate       = self;
        _photoScrollView.showsVerticalScrollIndicator   = NO;
        _photoScrollView.showsHorizontalScrollIndicator = NO;
        _photoScrollView.backgroundColor                = [UIColor clearColor];
        if (self.showStyle == WYPhotoBrowserShowStylePush) {
            _photoScrollView.wy_gestureHandleDisabled = NO;
        }else {
            _photoScrollView.wy_gestureHandleDisabled = YES;
        }
        
        if (@available(iOS 11.0, *)) {
            _photoScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    return _photoScrollView;
}

- (UIPanGestureRecognizer *)panGesture {
    if (!_panGesture) {
        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    }
    return _panGesture;
}

- (WYPhoto *)currentPhoto {
    return self.photos[self.currentIndex];
}

- (WYPhotoView *)currentPhotoView {
    return [self photoViewForIndex:self.currentIndex];
}

+ (instancetype)photoBrowserWithPhotos:(NSArray<WYPhoto *> *)photos currentIndex:(NSInteger)currentIndex {
    return [[self alloc] initWithPhotos:photos currentIndex:currentIndex];
}

- (instancetype)initWithPhotos:(NSArray<WYPhoto *> *)photos currentIndex:(NSInteger)currentIndex {
    if (self = [super init]) {
        
        self.photos       = photos;
        self.currentIndex = currentIndex;
        
        self.isStatusBarShow  = NO;
        self.isHideSourceView = YES;
        
        _visiblePhotoViews  = [NSMutableArray new];
        _reusablePhotoViews = [NSMutableSet new];
        
        if (!imageManagerClass) {
            imageManagerClass = [WYWebImageManager class];
        }
        self.imageProtocol = [imageManagerClass new];
    }
    return self;
}

- (instancetype)init {
    NSAssert(NO, @"Use initWithPhotos:currentIndex: instead.");
    return nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 设置UI
    [self setupUI];
    
    // 手势和监听
    [self addGestureAndObserver];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    WYPhoto *photo          = [self currentPhoto];
    WYPhotoView *photoView  = [self currentPhotoView];
    
    if ([_imageProtocol imageFromMemoryForURL:photo.url] || photo.image) {
        [photoView setupPhoto:photo];
    }else {
        photoView.imageView.image = photo.placeholderImage;
        [photoView adjustFrame];
    }
    
    switch (self.showStyle) {
        case WYPhotoBrowserShowStyleNone:
            [self browserNoneShow];
            break;
        case WYPhotoBrowserShowStylePush:
            [self browserPushShow];
            break;
        case WYPhotoBrowserShowStyleZoom:{
            [self browserZoomShow];
        }
            break;
            
        default:
            break;
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    if (!self.isStatusBarChanged) {
        [self layoutSubviews];
    }
}

- (void)setupUI {
    
    [self.navigationController setNavigationBarHidden:YES];
    
    self.view.backgroundColor   = [UIColor blackColor];
    
    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height;
    BOOL isLandspace = width > height;
    if (isLandspace) {
        width -= (kSaveTopSpace + kSaveBottomSpace);
    }else {
        height -= (kSaveTopSpace + kSaveBottomSpace);
    }
    
    self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    self.contentView.center = [UIApplication sharedApplication].keyWindow.center;
    self.contentView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.contentView];
    
    [self.contentView addSubview:self.photoScrollView];
    
    if (self.coverViews) {
        [self.coverViews enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self.contentView addSubview:obj];
        }];
    }else {
        _countLabel                 = [UILabel new];
        _countLabel.textColor       = [UIColor whiteColor];
        _countLabel.font            = [UIFont systemFontOfSize:18.0];
        _countLabel.textAlignment   = NSTextAlignmentCenter;
        _countLabel.bounds          = CGRectMake(0, 0, 80, 30);
        [self.contentView addSubview:_countLabel];
        
        _countLabel.center = CGPointMake(self.contentView.bounds.size.width * 0.5, 30);
        
        [self updateLabel];
    }
    
    CGRect frame = self.photoScrollView.bounds;
    
    CGSize contentSize = CGSizeMake(frame.size.width * self.photos.count, frame.size.height);
    self.photoScrollView.contentSize = contentSize;
    
    CGPoint contentOffset = CGPointMake(frame.size.width * self.currentIndex, 0);
    [self.photoScrollView setContentOffset:contentOffset animated:NO];
    
    if (self.photoScrollView.contentOffset.x == 0) {
        [self scrollViewDidScroll:self.photoScrollView];
    }
}

- (void)addGestureAndObserver {
    [self addGestureRecognizer];
    
    if (!self.isScreenRotateDisabled) {
        [self addDeviceOrientationObserver];
    }
}

#pragma mark - Setter
- (void)setShowStyle:(WYPhotoBrowserShowStyle)showStyle {
    _showStyle = showStyle;
    
    if (showStyle == WYPhotoBrowserShowStylePush) {
        //        self.photoScrollView.wy_gestureHandleDisabled = NO;
    }else {
        self.modalPresentationStyle = UIModalPresentationCustom;
        self.modalTransitionStyle   = UIModalTransitionStyleCoverVertical;
    }
}

- (void)setIsStatusBarShow:(BOOL)isStatusBarShow {
    _isStatusBarShow = isStatusBarShow;
    
    /**这一行代码打开，在有些情况下会出现pageControl位置不正确的bug */
//    self.isStatusBarChanged = YES;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.isStatusBarChanged = NO;
    });
    
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)setIsScreenRotateDisabled:(BOOL)isScreenRotateDisabled {
    _isScreenRotateDisabled = isScreenRotateDisabled;
    
    if (isScreenRotateDisabled) {
        [self delDeviceOrientationObserver];
    } else {
        [self addDeviceOrientationObserver];
    }
}

#pragma mark - BrowserShow
- (void)browserNoneShow {
    WYPhotoView *photoView = [self currentPhotoView];
    WYPhoto *photo = [self currentPhoto];
    
    self.view.alpha = 0;
    
    [UIView animateWithDuration:kAnimationDuration animations:^{
        self.view.alpha = 1.0;
    }completion:^(BOOL finished) {
        self.isShow = YES;
        
        [photoView setupPhoto:photo];
        
        [self deviceOrientationDidChange];
    }];
}

- (void)browserPushShow {
    self.view.backgroundColor = [UIColor blackColor];
    self.isShow = YES;
    
    [[self currentPhotoView] setupPhoto:[self currentPhoto]];
    
    [self deviceOrientationDidChange];
}

- (void)browserZoomShow {
    WYPhoto *photo          = [self currentPhoto];
    WYPhotoView *photoView  = [self currentPhotoView];
    
    CGRect endRect    = photoView.imageView.frame;
    CGRect sourceRect = photo.sourceFrame;
    
    if (CGRectEqualToRect(sourceRect, CGRectZero)) {
        float systemVersion = [UIDevice currentDevice].systemVersion.floatValue;
        if (systemVersion >= 8.0 && systemVersion < 9.0) {
            sourceRect = [photo.sourceImageView.superview convertRect:photo.sourceImageView.frame toCoordinateSpace:photoView];
        }else {
            sourceRect = [photo.sourceImageView.superview convertRect:photo.sourceImageView.frame toView:photoView];
        }
    }
    
    photoView.imageView.frame = sourceRect;
    
    [UIView animateWithDuration:kAnimationDuration animations:^{
        photoView.imageView.frame = endRect;
        self.view.backgroundColor = [UIColor blackColor];
    }completion:^(BOOL finished) {
        self.isShow = YES;
        [photoView setupPhoto:photo];
        
        [self deviceOrientationDidChange];
    }];
}

- (void)updateLabel {
    _countLabel.text = [NSString stringWithFormat:@"%zd/%zd", self.currentIndex + 1, self.photos.count];
}

- (void)layoutSubviews {
    CGRect frame = self.contentView.bounds;
    
    frame.origin.x   -= kPhotoViewPadding;
    frame.size.width += kPhotoViewPadding * 2;
    
    CGFloat photoScrollW = frame.size.width;
    CGFloat photoScrollH = frame.size.height;
    
    CGFloat pointX = photoScrollW * 0.5 - kPhotoViewPadding;
    
    self.photoScrollView.frame  = frame;
    self.photoScrollView.center = CGPointMake(pointX, photoScrollH * 0.5);
    
    self.photoScrollView.contentOffset = CGPointMake(self.currentIndex * photoScrollW, 0);
    
    self.photoScrollView.contentSize = CGSizeMake(photoScrollW * self.photos.count, 0);
    
    // 调整所有显示的photoView的frame
    CGFloat w = photoScrollW - kPhotoViewPadding * 2;
    CGFloat h = photoScrollH;
    CGFloat x = 0;
    CGFloat y = 0;
    
    for (WYPhotoView *photoView in _visiblePhotoViews) {
        x = kPhotoViewPadding + photoView.tag * (kPhotoViewPadding * 2 + w);
        
        photoView.frame = CGRectMake(x, y, w, h);
        
        [photoView resetFrame];
    }
    
    if (self.coverViews) {
        !self.layoutBlock ? : self.layoutBlock(self, self.contentView.bounds);
    }else {
        _countLabel.bounds = CGRectMake(0, 0, 80, 30);

        _countLabel.center = CGPointMake(frame.size.width * 0.5, 30);
    }
    
    if ([self.delegate respondsToSelector:@selector(photoBrowser:willLayoutSubViews:)]) {
        [self.delegate photoBrowser:self willLayoutSubViews:self.currentIndex];
    }
}

- (void)dealloc
{
    [self delDeviceOrientationObserver];
}

#pragma mark - 屏幕旋转
- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

#pragma mark - 状态栏
- (BOOL)prefersStatusBarHidden {
    return !self.isStatusBarShow;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return self.fromVC.preferredStatusBarStyle;
}

#pragma mark - Public Methods
+ (void)setImageManagerClass:(Class<WYWebImageProtocol>)cls {
    imageManagerClass = cls;
}

- (void)setupCoverViews:(NSArray *)coverViews layoutBlock:(layoutBlock)layoutBlock {
    
    self.coverViews  = coverViews;
    
    self.layoutBlock = layoutBlock;
}

- (void)showFromVC:(UIViewController *)vc {
    
    self.fromVC = vc;
    
    if (self.showStyle == WYPhotoBrowserShowStylePush) {
        [vc.navigationController pushViewController:self animated:YES];
    }else {
        self.modalPresentationCapturesStatusBarAppearance = YES;
        [vc presentViewController:self animated:NO completion:nil];
    }
}

- (void)dismissAnimated:(BOOL)animated {
    WYPhoto *photo = self.photos[self.currentIndex];
    if (animated) {
        [UIView animateWithDuration:kAnimationDuration animations:^{
            photo.sourceImageView.alpha = 1.0;
        }];
    }else {
        photo.sourceImageView.alpha = 1.0;
    }
    
    [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait animated:NO];
    
    [self dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark - Private Methods

- (void)addGestureRecognizer {
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    singleTap.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:singleTap];
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleTap.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:doubleTap];
    [singleTap requireGestureRecognizerToFail:doubleTap];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [self.view addGestureRecognizer:longPress];
    
    // 拖拽手势
    [self addPanGesture:YES];
}

- (void)addPanGesture:(BOOL)isFirst {
    if (self.showStyle == WYPhotoBrowserShowStylePush) {
        [self removePanGesture];
    }else {
        if (isFirst) {
            [self.view addGestureRecognizer:self.panGesture];
        }else {
            UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
            
            if (UIDeviceOrientationIsPortrait(orientation) || self.isPortraitToUp) {
                [self.view addGestureRecognizer:self.panGesture];
            }
        }
    }
}

- (void)removePanGesture {
    if ([self.view.gestureRecognizers containsObject:self.panGesture]) {
        [self.view removeGestureRecognizer:self.panGesture];
    }
}

#pragma mark - Gesture Handle
- (void)handleSingleTap:(UITapGestureRecognizer *)tap {
    
    WYPhotoView *photoView = [self currentPhotoView];
    photoView.isLayoutSubViews = YES;
    
    if ([self.delegate respondsToSelector:@selector(photoBrowser:singleTapWithIndex:)]) {
        [self.delegate photoBrowser:self singleTapWithIndex:self.currentIndex];
    }
    
    if (self.isSingleTapDisabled) return;
    
    // 状态栏恢复到竖屏
    [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait animated:NO];
    
    if (self.showStyle == WYPhotoBrowserShowStylePush) {
        [self.navigationController popViewControllerAnimated:YES];
    }else {
        // 显示状态栏
        self.isStatusBarShow = YES;
        
        // 防止返回时跳动
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self recoverAnimation];
        });
    }
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)tap {
    WYPhotoView *photoView = [self photoViewForIndex:self.currentIndex];
    WYPhoto *photo = self.photos[self.currentIndex];
    
    if (!photo.finished) return;
    
    if (photoView.scrollView.zoomScale > 1.0) {
        [photoView.scrollView setZoomScale:1.0 animated:YES];
        photo.isZooming = NO;
        
        // 默认情况下有滑动手势
        [self addPanGesture:YES];
    }else {
        CGPoint location = [tap locationInView:self.contentView];
        CGFloat wh       = 1.0;
        CGRect zoomRect  = [self frameWithWidth:wh height:wh center:location];
        
        [photoView zoomToRect:zoomRect animated:YES];
        
        photo.isZooming = YES;
        photo.zoomRect  = zoomRect;
        
        // 放大情况下移除滑动手势
        [self removePanGesture];
    }
}

- (CGRect)frameWithWidth:(CGFloat)width height:(CGFloat)height center:(CGPoint)center {
    CGFloat x = center.x - width * 0.5;
    CGFloat y = center.y - height * 0.5;
    
    return CGRectMake(x, y, width, height);
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)longPress {
    switch (longPress.state) {
        case UIGestureRecognizerStateBegan:{
            if ([self.delegate respondsToSelector:@selector(photoBrowser:longPressWithIndex:)]) {
                [self.delegate photoBrowser:self longPressWithIndex:self.currentIndex];
            }
        }
            break;
        case UIGestureRecognizerStateEnded:
            
            break;
            
        default:
            break;
    }
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)panGesture {
    
    // 放大时候禁止滑动返回
    WYPhotoView *photoView = [self currentPhotoView];
    if (photoView.scrollView.zoomScale > 1.0f) {
        return;
    }
    
    switch (self.hideStyle) {
        case WYPhotoBrowserHideStyleZoomScale:
            [self handlePanZoomScale:panGesture];
            break;
        case WYPhotoBrowserHideStyleZoomSlide:
            [self handlePanZoomSlide:panGesture];
            break;
            
        default:
            break;
    }
}

- (void)handlePanZoomScale:(UIPanGestureRecognizer *)panGesture {
    CGPoint point       = [panGesture translationInView:self.view];
    CGPoint location    = [panGesture locationInView:self.view];
    CGPoint velocity    = [panGesture velocityInView:self.view];
    
    WYPhotoView *photoView = [self photoViewForIndex:self.currentIndex];
    
    switch (panGesture.state) {
        case UIGestureRecognizerStateBegan:
            _startLocation = location;
            [self handlePanBegin];
            break;
        case UIGestureRecognizerStateChanged: {
            double percent = 1 - fabs(point.y) / self.view.frame.size.height;
            percent  = MAX(percent, 0);
            double s = MAX(percent, 0.5);
            CGAffineTransform translation = CGAffineTransformMakeTranslation(point.x / s, point.y / s);
            CGAffineTransform scale = CGAffineTransformMakeScale(s, s);
            photoView.imageView.transform = CGAffineTransformConcat(translation, scale);
            self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:percent];
        }
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:{
            if (fabs(point.y) > 200 || fabs(velocity.y) > 500) {
                [self showDismissAnimation];
            }else {
                [self showCancelAnimation];
            }
        }
            break;
        default:
            break;
    }
}

- (void)handlePanZoomSlide:(UIPanGestureRecognizer *)panGesture {
    CGPoint point    = [panGesture translationInView:self.view];
    CGPoint location = [panGesture locationInView:self.view];
    CGPoint velocity = [panGesture velocityInView:self.view];
    
    WYPhotoView *photoView = [self currentPhotoView];
    switch (panGesture.state) {
        case UIGestureRecognizerStateBegan:
            _startLocation = location;
            [self handlePanBegin];
            break;
        case UIGestureRecognizerStateChanged:{
            photoView.imageView.transform = CGAffineTransformMakeTranslation(0, point.y);
            double percent = 1 - fabs(point.y) / self.view.frame.size.height * 0.5;
            self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:percent];
        }
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            if (fabs(point.y) > 200 || fabs(velocity.y) > 500) {
                [self showSlideDismissAnimationWithPoint:point];
            }else {
                [self showCancelAnimation];
            }
        }
            break;
            
        default:
            break;
    }
}

- (void)handlePanBegin {
    WYPhoto *photo = [self currentPhoto];
    
    if (self.isHideSourceView) {
        photo.sourceImageView.alpha = 0;
    }
    
    _isStatusBarShowing = self.isStatusBarShow;
    
    // 显示状态栏
    self.isStatusBarShow = YES;
    
    if ([self.delegate respondsToSelector:@selector(photoBrowser:panBeginWithIndex:)]) {
        [self.delegate photoBrowser:self panBeginWithIndex:self.currentIndex];
    }
}

- (void)recoverAnimation {
    
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    
    if (UIDeviceOrientationIsLandscape(orientation)) {
        [UIView animateWithDuration:kAnimationDuration animations:^{
            // 旋转view
            self.contentView.transform = CGAffineTransformIdentity;
            
            // 设置frame
            self.contentView.bounds = CGRectMake(0, 0, MIN(screenBounds.size.width, screenBounds.size.height), MAX(screenBounds.size.width, screenBounds.size.height) - kSaveTopSpace - kSaveBottomSpace);
            
            self.contentView.center = [UIApplication sharedApplication].keyWindow.center;
            
            [self layoutSubviews];
            
            [self.view setNeedsLayout];
            [self.view layoutIfNeeded];
        }completion:^(BOOL finished) {
            [self showDismissAnimation];
        }];
    }else {
        [self showDismissAnimation];
    }
}

- (void)showDismissAnimation {
    
    WYPhotoView *photoView = [self photoViewForIndex:self.currentIndex];
    WYPhoto *photo = self.photos[self.currentIndex];
    
    CGRect sourceRect = photo.sourceFrame;
    
    if (CGRectEqualToRect(sourceRect, CGRectZero)) {
        if (photo.sourceImageView == nil) {
            [UIView animateWithDuration:kAnimationDuration animations:^{
                self.view.alpha = 0;
            }completion:^(BOOL finished) {
                [self dismissAnimated:NO];
            }];
            return;
        }
        
        if (self.isHideSourceView) {
            photo.sourceImageView.alpha = 0;
        }
        
        float systemVersion = [UIDevice currentDevice].systemVersion.floatValue;
        if (systemVersion >= 8.0 && systemVersion < 9.0) {
            sourceRect = [photo.sourceImageView.superview convertRect:photo.sourceImageView.frame toCoordinateSpace:photoView];
        }else {
            sourceRect = [photo.sourceImageView.superview convertRect:photo.sourceImageView.frame toView:photoView];
        }
    }else {
        if (self.isHideSourceView && photo.sourceImageView) {
            photo.sourceImageView.alpha = 0;
        }
    }
    
    [UIView animateWithDuration:kAnimationDuration animations:^{
        photoView.imageView.frame = sourceRect;
        self.view.backgroundColor = [UIColor clearColor];
    }completion:^(BOOL finished) {
        [self dismissAnimated:NO];
        
        [self panEndedWillDisappear:YES];
    }];
}

- (void)showSlideDismissAnimationWithPoint:(CGPoint)point {
    WYPhotoView *photoView = [self currentPhotoView];
    BOOL throwToTop = point.y < 0;
    CGFloat toTranslationY = 0;
    if (throwToTop) {
        toTranslationY = - self.view.frame.size.height;
    }else {
        toTranslationY = self.view.frame.size.height;
    }
    
    [UIView animateWithDuration:kAnimationDuration animations:^{
        photoView.imageView.transform = CGAffineTransformMakeTranslation(0, toTranslationY);
        self.view.backgroundColor = [UIColor clearColor];
    }completion:^(BOOL finished) {
        [self dismissAnimated:YES];
        
        [self panEndedWillDisappear:YES];
    }];
}

- (void)showCancelAnimation {
    WYPhotoView *photoView = [self photoViewForIndex:self.currentIndex];
    WYPhoto *photo = self.photos[self.currentIndex];
    photo.sourceImageView.alpha = 1.0;
    
    [UIView animateWithDuration:kAnimationDuration animations:^{
        photoView.imageView.transform = CGAffineTransformIdentity;
        self.view.backgroundColor = [UIColor blackColor];
    }completion:^(BOOL finished) {
        
        if (!self.isStatusBarShowing) {
            // 隐藏状态栏
            self.isStatusBarShow = NO;
        }
        
        [self panEndedWillDisappear:NO];
    }];
}

- (void)panEndedWillDisappear:(BOOL)disappear {
    if ([self.delegate respondsToSelector:@selector(photoBrowser:panEndedWithIndex:willDisappear:)]) {
        [self.delegate photoBrowser:self panEndedWithIndex:self.currentIndex willDisappear:disappear];
    }
}

// 重用页面
- (WYPhotoView *)dequeueReusablePhotoView {
    WYPhotoView *photoView = [self.reusablePhotoViews anyObject];
    if (photoView) {
        [_reusablePhotoViews removeObject:photoView];
    }else {
        photoView = [[WYPhotoView alloc] initWithFrame:self.photoScrollView.bounds imageProtocol:_imageProtocol];
    }
    photoView.tag =  -1;
    return photoView;
}

#pragma mark - 屏幕旋转相关
- (void)addDeviceOrientationObserver {
    
    // 默认设备方向：竖屏
    self.originalOrientation = UIDeviceOrientationPortrait;
    
    //    [self deviceOrientationDidChange];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
}

- (void)delDeviceOrientationObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

- (void)deviceOrientationDidChange {
    if (self.isScreenRotateDisabled) return;
    
    self.isRotation = YES;
    
    // 恢复当前视图的缩放
    WYPhoto *photo  = [self currentPhoto];
    photo.isZooming = NO;
    photo.zoomRect  = CGRectZero;
    
    WYPhotoView *photoView = [self currentPhotoView];
    
    // 旋转之后当前的设备方向
    UIDeviceOrientation currentOrientation = [UIDevice currentDevice].orientation;
    self.currentOrientation = currentOrientation;
    
    if (UIDeviceOrientationIsPortrait(self.originalOrientation)) {
        if (UIDeviceOrientationIsLandscape(currentOrientation)) {
            [photoView.scrollView setZoomScale:1.0 animated:YES];
        }
    }
    
    if (UIDeviceOrientationIsLandscape(self.originalOrientation)) {
        if (UIDeviceOrientationIsPortrait(currentOrientation)) {
            [photoView.scrollView setZoomScale:1.0 animated:YES];
        }
    }
    
    self.isPortraitToUp = NO;
    
    if (UIDeviceOrientationIsPortrait(self.originalOrientation)) {
        if (currentOrientation == UIDeviceOrientationFaceUp) {
            self.isPortraitToUp = YES;
        }
    }
    
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    
    // 旋转之后是横屏
    if (UIDeviceOrientationIsLandscape(currentOrientation)) {
        self.isLandspace = YES;
        [self deviceOrientationChangedDelegate];
        
        // 横屏移除pan手势
        [self removePanGesture];
        
        NSTimeInterval duration = UIDeviceOrientationIsLandscape(self.originalOrientation) ? 2 * kAnimationDuration : kAnimationDuration;
        
        [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            // 旋转状态栏
            [[UIApplication sharedApplication] setStatusBarOrientation:(UIInterfaceOrientation)currentOrientation animated:YES];
            
            float rotation = currentOrientation == UIDeviceOrientationLandscapeRight ? 1.5 : 0.5;
            
            // 旋转contentView
            self.contentView.transform = CGAffineTransformMakeRotation(M_PI * rotation);
            
            // 设置frame
            self.contentView.bounds = CGRectMake(0, 0, MAX(screenBounds.size.width, screenBounds.size.height) - kSaveTopSpace - kSaveBottomSpace, MIN(screenBounds.size.width, screenBounds.size.height));
            
            self.contentView.center = [UIApplication sharedApplication].keyWindow.center;
            
            [self layoutSubviews];
            
            [self.view setNeedsLayout];
            [self.view layoutIfNeeded];
            
        } completion:^(BOOL finished) {
            // 记录设备方向
            self.originalOrientation = currentOrientation;
            self.isRotation = NO;
            
            // 横屏时隐藏状态栏，这里为了解决一个bug，iPhone X中横屏状态栏隐藏后不能再次显示，暂时的解决办法是这样，如果有更好的方法可随时修改
            if (self.isStatusBarShow) { // 状态栏是显示状态
                self.isStatusBarShowing = self.isStatusBarShow;  // 记录状态栏显隐状态
                self.isStatusBarShow = NO;
            }
        }];
    }else if (currentOrientation == UIDeviceOrientationPortrait) {
        self.isLandspace = NO;
        [self deviceOrientationChangedDelegate];
        
        // 竖屏时添加pan手势
        [self addPanGesture:NO];
        
        NSTimeInterval duration = kAnimationDuration;
        
        [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            // 旋转状态栏
            [[UIApplication sharedApplication] setStatusBarOrientation:(UIInterfaceOrientation)currentOrientation animated:YES];
            
            // 旋转view
            self.contentView.transform = currentOrientation == UIDeviceOrientationPortrait ? CGAffineTransformIdentity : CGAffineTransformMakeRotation(M_PI);
            
            // 设置frame
            self.contentView.bounds = CGRectMake(0, 0, MIN(screenBounds.size.width, screenBounds.size.height), MAX(screenBounds.size.width, screenBounds.size.height) - kSaveTopSpace - kSaveBottomSpace);
            self.contentView.center = [UIApplication sharedApplication].keyWindow.center;
            
            [self layoutSubviews];
            
            [self.view setNeedsLayout];
            [self.view layoutIfNeeded];
            
        } completion:^(BOOL finished) {
            // 记录设备方向
            self.originalOrientation = currentOrientation;
            self.isRotation = NO;
            
            // 切换到竖屏后，如果原来状态栏是显示状态，就再次显示状态栏
            if (self.isStatusBarShowing) {
                self.isStatusBarShow    = YES;
                self.isStatusBarShowing = NO;
            }
        }];
    }else {
        self.isRotation     = NO;
        self.isLandspace    = NO;
        
        [self deviceOrientationChangedDelegate];
    }
}

- (void)deviceOrientationChangedDelegate {
    if ([self.delegate respondsToSelector:@selector(photoBrowser:onDeciceChangedWithIndex:isLandspace:)]) {
        [self.delegate photoBrowser:self onDeciceChangedWithIndex:self.currentIndex isLandspace:self.isLandspace];
    }
}

// 更新可复用的图片视图
- (void)updateReusableViews {
    NSMutableArray *viewsForRemove = [NSMutableArray new];
    for (WYPhotoView *photoView in _visiblePhotoViews) {
        if ((photoView.frame.origin.x + photoView.frame.size.width < self.photoScrollView.contentOffset.x - self.photoScrollView.frame.size.width) || (photoView.frame.origin.x > self.photoScrollView.contentOffset.x + 2 * self.photoScrollView.frame.size.width)) {
            [photoView removeFromSuperview];
            WYPhoto *photo = nil;
            
            [photoView setupPhoto:photo];
            
            [viewsForRemove addObject:photoView];
            [_reusablePhotoViews addObject:photoView];
        }
    }
    [_visiblePhotoViews removeObjectsInArray:viewsForRemove];
}

// 设置图片视图
- (void)setupPhotoViews {
    NSInteger index = self.photoScrollView.contentOffset.x / self.photoScrollView.frame.size.width + 0.5;
    
    for (NSInteger i = index - 1; i <= index + 1; i++) {
        if (i < 0 || i >= self.photos.count) {
            continue;
        }
        WYPhotoView *photoView = [self photoViewForIndex:i];
        if (photoView == nil) {
            photoView               = [self dequeueReusablePhotoView];
            photoView.loadStyle     = self.loadStyle;
            
            __typeof(self) __weak weakSelf = self;
            photoView.zoomEnded     = ^(NSInteger scale) {
                if (scale == 1.0f) {
                    [weakSelf addPanGesture:NO];
                }else {
                    [weakSelf removePanGesture];
                }
            };
            
            CGRect frame            = self.photoScrollView.bounds;
            
            CGFloat photoScrollW    = frame.size.width;
            CGFloat photoScrollH    = frame.size.height;
            // 调整当前显示的photoView的frame
            CGFloat w = photoScrollW - kPhotoViewPadding * 2;
            CGFloat h = photoScrollH;
            CGFloat x = kPhotoViewPadding + i * (kPhotoViewPadding * 2 + w);
            CGFloat y = 0;
            
            photoView.frame = CGRectMake(x, y, w, h);
            photoView.tag   = i;
            [self.photoScrollView addSubview:photoView];
            [_visiblePhotoViews addObject:photoView];
            
            [photoView resetFrame];
        }
        
        if (photoView.photo == nil && self.isShow) {
            [photoView setupPhoto:self.photos[i]];
        }
    }
    
    // 更换photoView
    if (index != self.currentIndex && self.isShow && (index >= 0 && index < self.photos.count)) {
        self.currentIndex = index;
        
        WYPhotoView *photoView = [self currentPhotoView];
        
        if (photoView.scrollView.zoomScale != 1.0) {
            [self removePanGesture];
        }else {
            [self addPanGesture:NO];
        }
        
        [self updateLabel];
        
        if ([self.delegate respondsToSelector:@selector(photoBrowser:didChangedIndex:)]) {
            [self.delegate photoBrowser:self didChangedIndex:self.currentIndex];
        }
    }
}

- (WYPhotoView *)photoViewForIndex:(NSInteger)index {
    for (WYPhotoView *photoView in _visiblePhotoViews) {
        if (photoView.tag == index) {
            return photoView;
        }
    }
    return nil;
}

#pragma mark - 代理
#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    if (self.isRotation) return;
    
    [self updateReusableViews];
    
    [self setupPhotoViews];
}

// scrollView结束滚动时调用
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    CGFloat offsetX = scrollView.contentOffset.x;
    CGFloat scrollW = self.photoScrollView.frame.size.width;
    
    NSInteger index = (offsetX + scrollW * 0.5) / scrollW;
    
    if ([self.delegate respondsToSelector:@selector(photoBrowser:scrollEndedIndex:)]) {
        [self.delegate photoBrowser:self scrollEndedIndex:index];
    }
    
    if (self.isResumePhotoZoom) {
        [self.visiblePhotoViews enumerateObjectsUsingBlock:^(WYPhotoView *photoView, NSUInteger idx, BOOL * _Nonnull stop) {
            WYPhoto *photo = self.photos[idx];
            photo.isZooming = NO;
            
            [photoView.scrollView setZoomScale:1.0 animated:NO];
        }];
    }
    
    if ([self currentPhotoView].scrollView.zoomScale > 1.0) {
        [self removePanGesture];
    }else {
        [self addPanGesture:NO];
    }
}

@end
