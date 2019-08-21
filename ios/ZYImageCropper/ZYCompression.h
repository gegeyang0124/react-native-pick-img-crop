//
//  ZYCompression.h
//  AFNetworking
//
//  Created by BZ-IMac on 2019/8/21.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImageResult : NSObject

@property NSData *data;
@property NSNumber *width;
@property NSNumber *height;
@property NSString *mime;
@property UIImage *image;

@end

@interface VideoResult : NSObject

@end

@interface ZYCompression : NSObject

- (ImageResult*) compressImage:(UIImage*)image withOptions:(NSDictionary*)options;
- (void)compressVideo:(NSURL*)inputURL
            outputURL:(NSURL*)outputURL
          withOptions:(NSDictionary*)options
              handler:(void (^)(AVAssetExportSession*))handler;

@property NSDictionary *exportPresets;

@end

NS_ASSUME_NONNULL_END
