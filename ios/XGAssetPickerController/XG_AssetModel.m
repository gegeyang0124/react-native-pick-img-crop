//
//  XG_AssetModel.m
//  MyApp
//
//  Created by huxinguang on 2018/9/26.
//  Copyright © 2018年 huxinguang. All rights reserved.
//

#import "XG_AssetModel.h"

@implementation XG_AssetModel

+ (instancetype)modelWithAsset:(PHAsset *)asset videoPickable:(BOOL)videoPickable{
    XG_AssetModel *model = [[XG_AssetModel alloc] init];
    model.asset = asset;
    model.picked = NO;
    model.number = 0;
    switch (asset.mediaType) {
        case PHAssetMediaTypeUnknown:
            model.selectable = NO;
            model.mine = @"file/unknown";
            break;
        case PHAssetMediaTypeImage:
            model.selectable = YES;
            model.mine = @"image/jpeg";
            break;
        case PHAssetMediaTypeVideo:
            model.mine = @"video/mp4";
            if (videoPickable) {
                model.selectable = YES;
            }else{
                model.selectable = NO;
            }
            break;
        case PHAssetMediaTypeAudio:
            model.selectable = NO;
            model.mine = @"audio/mp3";
            break;
        default:
            break;
    }
    
    PHImageManager * imageManager = [PHImageManager defaultManager];
    [imageManager requestImageDataForAsset:asset options:nil resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        
        NSURL *url = [info valueForKey:@"PHImageFileURLKey"];
        NSString *str = [url absoluteString];   //url>string
        model.path = [str substringFromIndex:7];//screw all the crap of file://
        NSArray *arr = [str componentsSeparatedByString:@"/"];
        model.imgName = [arr lastObject];  // 图片名字
        model.imgSize = imageData.length;   // 图片大小，单位B
        
//        UIImage * image = [UIImage imageWithData:imageData];
//        CGSize s = image.size;
//        NSURL *url2;
    }];
    
//    [asset requestContentEditingInputWithOptions:nil completionHandler:^(PHContentEditingInput * _Nullable contentEditingInput, NSDictionary * _Nonnull info) {
//        //                    NSLog(@"URL:%@",  contentEditingInput.fullSizeImageURL.absoluteString);
//        model.path = [contentEditingInput.fullSizeImageURL.absoluteString substringFromIndex:7];//screw all the crap of file://
//        //                    NSFileManager *fileManager = [NSFileManager defaultManager];
//        //                    BOOL isExist = [fileManager fileExistsAtPath:path];
//        //                    if (isExist)
//        //                        NSLog(@"oh yeah");
//        //                    else {
//        //                        NSLog(@"damn");
//        //                    }
//    }];

    return model;
}
/*
 如果自定义的类需要实现浅拷贝，则在实现copyWithZone:方法时返回自身，
 而需要深拷贝时，在copyWithZone:方法中创建一个新的实例对象返回即
 */
- (id)copyWithZone:(NSZone *)zone {
    XG_AssetModel *item = [self.class new];
    return item;
}


@end


