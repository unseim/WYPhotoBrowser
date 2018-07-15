//
//  UIScrollView+WYGestureHandle.m
//  WYPhotoBrowser
//  简书地址：http://www.jianshu.com/u/8f8143fbe7e4
//  GitHub地址：https://github.com/unseim
//  QQ：9137279
//

#import "UIScrollView+WYGestureHandle.h"
#import <objc/runtime.h>

static const void *WYGestureHandleDisabled = @"WYGestureHandleDisabled";

@implementation UIScrollView (WYGestureHandle)

- (void)setWy_gestureHandleDisabled:(BOOL)wy_gestureHandleDisabled{
    objc_setAssociatedObject(self, WYGestureHandleDisabled, @(wy_gestureHandleDisabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)wy_gestureHandleDisabled {
    return [objc_getAssociatedObject(self, WYGestureHandleDisabled) boolValue];
}

#pragma mark - 解决全屏滑动

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    
    if (self.wy_gestureHandleDisabled) {
        return YES;
    }
    
    if ([self panBack:gestureRecognizer]) {
        return NO;
    }
    
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (self.wy_gestureHandleDisabled) {
        return NO;
    }
    
    if ([self panBack:gestureRecognizer]) {
        return YES;
    }
    
    return NO;
}

- (BOOL)panBack:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer == self.panGestureRecognizer) {
        CGPoint point = [self.panGestureRecognizer translationInView:self];
        UIGestureRecognizerState state = gestureRecognizer.state;
        
        // 设置手势滑动的位置距屏幕左边的区域
        CGFloat locationDistance = [UIScreen mainScreen].bounds.size.width;
        
        if (state == UIGestureRecognizerStateBegan || state == UIGestureRecognizerStatePossible) {
            CGPoint location = [gestureRecognizer locationInView:self];
            if (point.x > 0 && location.x < locationDistance && self.contentOffset.x <= 0) {
                return YES;
            }
        }
    }
    return NO;
}

@end
