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
