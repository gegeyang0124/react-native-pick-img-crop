//
//  RNPickImgCrop.m
//  RNPickImgCrop
//
//  Created by BZ-IMac on 2019/8/2.
//  Copyright © 2019年 BZ-IMac. All rights reserved.
//

#import "RNPickImgCrop.h"
#import "XG_AssetPickerController.h"

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
 @param options NSDictionary,//设置js版本相关数据
 options : {
 versionCode : '', //NSString,//js版本号
 bundleJsPath : '', //NSString,//js代码路径
 build : 122, //int,//构建值（数字），只可增大，不可重复，用于比对版本是否升级
 }
 **/
RCT_EXPORT_METHOD(openPicker:(NSDictionary *)options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject){
    [[XG_AssetPickerManager manager] handleAuthorizationWithCompletion:^(XG_AuthorizationStatus aStatus) {
        if (aStatus == XG_AuthorizationStatusAuthorized)
        {
            XG_AssetPickerOptions *options = [[XG_AssetPickerOptions alloc]init];
            options.maxAssetsCount = 9;
            //    options.videoPickable = YES;
            //    NSMutableArray<XG_AssetModel *> *array = [self.assets mutableCopy];
            //    [array removeLastObject];//去除占位model
            //    options.pickedAssetModels = array;
            XG_AssetPickerController *photoPickerVc = [[XG_AssetPickerController alloc] initWithOptions:options delegate:self];
            UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:photoPickerVc];
            [[self getRootVC] presentViewController:nav animated:YES completion:nil];
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"未开启相册权限，是否去设置中开启？" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"去设置", nil];
            [alert show];
        }
    }];
    
    resolve(@{});
}


@end
