//
//  XG_AssetModel.h
//  MyApp
//
//  Created by huxinguang on 2018/9/26.
//  Copyright © 2018年 huxinguang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

@interface XG_AssetModel : NSObject
@property (nonatomic, strong) PHAsset *asset;            // PHAsset
@property (nonatomic, getter=isPicked) BOOL picked;      // 选中状态 默认NO
@property (nonatomic, assign) int number;                // 数字
@property (nonatomic, assign) BOOL isPlaceholder;        // 是否为占位
@property (nonatomic, assign) BOOL selectable;           // 是否可以被选中
@property (nonatomic, strong) NSString* path;   //图片路径
@property (nonatomic, strong) NSString* mine;   //文件类型
@property (nonatomic, strong) NSString *imgName;   //文件名字
@property (nonatomic, assign) NSInteger imgSize;   //文件内容大小 单位B
@property (nonatomic, assign) UIImage *img;   //图片

+ (instancetype)modelWithAsset:(PHAsset *)asset videoPickable:(BOOL)videoPickable;


@end

