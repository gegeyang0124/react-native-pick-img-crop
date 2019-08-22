//
//  RNPickImgCrop.h
//  RNPickImgCrop
//
//  Created by BZ-IMac on 2019/8/2.
//  Copyright © 2019年 BZ-IMac. All rights reserved.
//

#import <React/RCTBridge.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTConvert.h>
#import "XG_AssetPickerController.h"
#import "ZYImageCropper.h"

@interface RNPickImgCrop : NSObject<RCTBridgeModule>

@property (nonatomic, strong) RCTPromiseResolveBlock resolve;//成功回调
@property (nonatomic, strong) RCTPromiseRejectBlock reject;//异常或错误回调
@property (nonatomic, strong) NSDictionary *params;//请求参数
@property (nonatomic, strong) NSMutableArray<XG_AssetModel *> *assets;//选中的图片集合

@end
