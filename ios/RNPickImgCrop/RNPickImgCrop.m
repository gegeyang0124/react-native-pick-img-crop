//
//  RNPickImgCrop.m
//  RNPickImgCrop
//
//  Created by BZ-IMac on 2019/8/2.
//  Copyright © 2019年 BZ-IMac. All rights reserved.
//

#import "RNPickImgCrop.h"

@implementation RNPickImgCrop

RCT_EXPORT_MODULE()

- (UIViewController*) getRootVC {
    UIViewController *root = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    while (root.presentedViewController != nil) {
        root = root.presentedViewController;
    }
    
    return root;
}

/**
 打开相册选择器
 @param params NSDictionary,//设置js版本相关数据
 options : {
 cropping:false,//bool 可不传,//是否剪辑图片 默认是false;flase时打开大图，true时进入裁剪控件
 multiple:false,//bool 可不传,//是否图片多选 默认是false；多选时显示先后选中顺序，取消其中任意一个选中按顺序缩减，单选只显示1，选中另一个则取消上一个选中
 maxCount:-1,//number 可不传,//最大可选数量，multiple为true此字段有效；不传或为-1时，选择数量不受限制
 cropWidth:200,//number 可不传,//裁剪宽度 cropping为true并且cropWidth和cropHeight同时为正整数时有效，不传或为小于0时，以最短边为准进行居中裁剪
 cropHeight:200,//number 可不传,//裁剪高度 cropping为true并且cropWidth和cropHeight同时为正整数时有效，不传或为小于0时，以最短边为准进行居中裁剪
 }
 **/
RCT_EXPORT_METHOD(openPicker:(NSDictionary *)params
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject){
    [[XG_AssetPickerManager manager] handleAuthorizationWithCompletion:^(XG_AuthorizationStatus aStatus) {
        if (aStatus == XG_AuthorizationStatusAuthorized)
        {
            self.params = params;
            self.resolve = resolve;
            self.reject = reject;
            
            XG_AssetPickerOptions *options = [[XG_AssetPickerOptions alloc]init];
            if([RCTConvert BOOL:params[@"multiple"]]){
                options.maxAssetsCount = [RCTConvert NSInteger:params[@"maxCount"]];
            }
            else {
                options.maxAssetsCount = 1;
            }
            
            //    options.videoPickable = YES;
            //    NSMutableArray<XG_AssetModel *> *array = [self.assets mutableCopy];
            //    [array removeLastObject];//去除占位model
            //    options.pickedAssetModels = array;
            XG_AssetPickerController *photoPickerVc = [[XG_AssetPickerController alloc] initWithOptions:options delegate:self];
            photoPickerVc.didSelectPhotoBlock = ^(NSMutableArray<XG_AssetModel *> * assets){
                self.assets = assets;
                
                if([RCTConvert BOOL:params[@"cropping"]]){
                    [self getCropedPic];
                }
                else
                {
                    [self getCheckedPic];
                }
            };
            
            UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:photoPickerVc];
            [[self getRootVC] presentViewController:nav animated:YES completion:nil];
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"未开启相册权限，是否去设置中开启？" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"去设置", nil];
            [alert show];
        }
    }];
}


// at the moment it is not possible to upload image by reading PHAsset
// we are saving image and saving it to the tmp location where we are allowed to access image later
- (NSString*) persistFile:(NSData*)data {
    // create temp file
    NSString *tmpDirFullPath = [self getTmpDirectory];
    NSString *filePath = [tmpDirFullPath stringByAppendingString:[[NSUUID UUID] UUIDString]];
    filePath = [filePath stringByAppendingString:@".jpg"];
    
    // save cropped file
    BOOL status = [data writeToFile:filePath atomically:YES];
    if (!status) {
        return nil;
    }
    
    return filePath;
}

- (NSString*) getTmpDirectory {
    NSString *TMP_DIRECTORY = @"react-native-pick-img-crop/";
    NSString *tmpFullPath = [NSTemporaryDirectory() stringByAppendingString:TMP_DIRECTORY];
    
    BOOL isDir;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:tmpFullPath isDirectory:&isDir];
    if (!exists) {
        [[NSFileManager defaultManager] createDirectoryAtPath: tmpFullPath
                                  withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return tmpFullPath;
}

/**
 获取选中的图片返回给js层
 **/
-(void) getCheckedPic{
    NSMutableArray *selections = [[NSMutableArray alloc] init];
    
    for (XG_AssetModel *model in self.assets) {
        [selections addObject:@{
                                @"path":model.path,
                                @"mine":model.mine,
                                @"filename":model.imgName,
                                @"size":[NSNumber numberWithUnsignedInteger:model.imgSize],
                                @"width":[NSNumber numberWithFloat:model.img.size.width],
                                @"height":[NSNumber numberWithFloat:model.img.size.height],
//                                @"creationDate":(model.asset.creationDate) ? [NSString stringWithFormat:@"%.0f", [model.asset.creationDate timeIntervalSince1970]] : [NSNull null],
                                @"creationDate":(model.asset.creationDate) ? [NSNumber numberWithLong: (long)([model.asset.creationDate timeIntervalSince1970])] : [NSNull null]
                                }];
    }
    self.resolve(selections);
}

/**
 获取选中的图片
 剪切后返回给js层
 **/
-(void) getCropedPic{
    NSMutableArray *selections = [[NSMutableArray alloc] init];
    
//    int index = 0;
    for (XG_AssetModel *model in self.assets) {
        RSKImageCropViewController *cropCtrl = [[RSKImageCropViewController alloc] initWithImage:model.img cropMode:RSKImageCropModeSquare];
        
        float cropWidth = [RCTConvert float:self.params[@"cropWidth"]];
        float cropHeight = [RCTConvert float:self.params[@"cropHeight"]];
        
//        float scale = 3.0f / 4.0f;
        float scale = cropHeight / cropWidth;
        cropWidth = model.img.size.width;
        cropHeight = cropWidth * scale;
        if(cropHeight > model.img.size.height){
            cropHeight = model.img.size.height;
            cropWidth = cropHeight / scale;
        }
        
        CGRect cropRect = CGRectMake(0.0, 0.0, cropWidth, cropHeight);
        CGRect imageRect = CGRectMake(0.0, 0.0, cropWidth, cropHeight);
        CGFloat rotationAngle = atan2(0, 0);
        CGFloat zoomScale = 1.0;
        
//        @weakify(index)
        [cropCtrl cropImage:cropRect imageRect:imageRect rotationAngle:rotationAngle zoomScale:zoomScale applyMaskToCroppedImage:false didBlock:^(UIImage *croppedImage){
//            @strongify(index)
//            index++;
            
            // we have correct rect, but not correct dimensions
            // so resize image
            CGSize desiredImageSize = CGSizeMake(cropWidth,cropHeight);
            
            UIImage *resizedImage = [croppedImage resizedImageToFitInSize:desiredImageSize scaleIfSmaller:YES];
            ImageResult *imageResult = [[ZYCompression new]
                                        compressImage:resizedImage
                                        withOptions:@{
                                                      @"compressImageMaxWidth":[NSNumber numberWithFloat:model.img.size.width],
                                                      @"compressImageMaxHeight":[NSNumber numberWithFloat:model.img.size.height],
                                                      }];
            
            NSString *filePath = [self persistFile:imageResult.data];
            
            [selections addObject:@{
                                    @"path":filePath,
                                    @"mine":model.mine,
                                    @"filename":model.imgName,
                                    @"size":[NSNumber numberWithUnsignedInteger:model.imgSize],
                                    @"width":[NSNumber numberWithFloat:cropWidth],
                                    @"height":[NSNumber numberWithFloat:cropHeight],
//                                    @"creationDate":[NSString stringWithFormat:@"%ld", (long)([[NSDate date] timeIntervalSince1970] * 1000)],
                                    @"creationDate":[NSNumber numberWithLong:(long)([[NSDate date] timeIntervalSince1970] * 1000)]
                                    }];
            if(selections.count == self.assets.count){
                self.resolve(selections);
            }
            
        }];
    }
}

@end
