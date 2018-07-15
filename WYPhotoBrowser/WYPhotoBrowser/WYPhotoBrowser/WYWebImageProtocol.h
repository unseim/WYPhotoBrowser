//
//  WYWebImageProtocol.h
//  WYPhotoBrowser
//  简书地址：http://www.jianshu.com/u/8f8143fbe7e4
//  GitHub地址：https://github.com/unseim
//  QQ：9137279
//

typedef void (^wyWebImageProgressBlock)(NSInteger receivedSize, NSInteger expectedSize);

typedef void (^wyWebImageCompletionBlock)(UIImage *_Nullable image, NSURL * _Nullable url, BOOL success, NSError * _Nullable error);

@protocol WYWebImageProtocol<NSObject>

- (void)setImageWithImageView:(nullable UIImageView *)imageView
                          url:(nullable NSURL *)url
                  placeholder:(nullable UIImage *)placeholder
                     progress:(nullable wyWebImageProgressBlock)progress
                   completion:(nullable wyWebImageCompletionBlock)completion;

- (void)cancelImageRequestWithImageView:(nullable UIImageView *)imageView;

- (UIImage *_Nullable)imageFromMemoryForURL:(nullable NSURL *)url;

@end
