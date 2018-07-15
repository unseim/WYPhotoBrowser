//
//  WYWebImageManager.m
//  WYPhotoBrowser
//  简书地址：http://www.jianshu.com/u/8f8143fbe7e4
//  GitHub地址：https://github.com/unseim
//  QQ：9137279
//

#import "WYWebImageManager.h"

@implementation WYWebImageManager

- (void)setImageWithImageView:(UIImageView *)imageView url:(NSURL *)url placeholder:(UIImage *)placeholder progress:(wyWebImageProgressBlock)progress completion:(wyWebImageCompletionBlock)completion {
    
    // 进度block
    SDWebImageDownloaderProgressBlock progressBlock = ^(NSInteger receivedSize, NSInteger expectedSize, NSURL *targetURL) {
        !progress ? : progress(receivedSize, expectedSize);
    };
    
    // 图片加载完成block
    SDExternalCompletionBlock completionBlock = ^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        !completion ? : completion(image, imageURL, !error, error);
    };
    
    [imageView sd_setImageWithURL:url placeholderImage:placeholder options:SDWebImageRetryFailed progress:progressBlock completed:completionBlock];
}

- (void)cancelImageRequestWithImageView:(UIImageView *)imageView {
    [imageView sd_cancelCurrentImageLoad];
}

- (UIImage *)imageFromMemoryForURL:(NSURL *)url {
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    NSString *key = [manager cacheKeyForURL:url];
    return [manager.imageCache imageFromCacheForKey:key];
}

@end
