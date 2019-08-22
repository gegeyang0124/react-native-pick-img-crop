import {
    Platform,
    Linking,
    NativeModules,
    Dimensions,
} from 'react-native';

const PickImgCroper = NativeModules.RNPickImgCrop;
// const PickImgCroper = NativeModules.RNPickImgCropTest;

/**
 * 原生底层模块名字
 * PhotoCropPicker
 * **/
export default class PickImgCrop {

    /**
     * 原生底层模块名字
     * PhotoCropPicker
     * **/
    /** *
     * @param {
            cropping:false,//bool 可不传,//是否剪辑图片 默认是false;flase时打开大图，true时进入裁剪控件
            multiple:false,//bool 可不传,//是否图片多选 默认是false；多选时显示先后选中顺序，取消其中任意一个选中按顺序缩减，单选只显示1，选中另一个则取消上一个选中
            maxCount:-1,//number 可不传,//最大可选数量，multiple为true此字段有效；不传或为-1时，选择数量不受限制
            cropWidth:200,//number 可不传,//裁剪宽度 cropping为true并且cropWidth和cropHeight同时为正整数时有效，不传或为小于0时，以最短边为准进行居中裁剪
            cropHeight:200,//number 可不传,//裁剪高度 cropping为true并且cropWidth和cropHeight同时为正整数时有效，不传或为小于0时，以最短边为准进行居中裁剪
        }
     * 上传预览按钮未有选中皆为灰色
     *
     * 未选中状态下，
     * cropping为true时：
     ** 点击图片缩略图右上角以外的任何区域时，进入裁剪控件，显示到点击的当前图片；
     * 由右上角打钩按钮控制是否选中；
     *‘预览’灰色不可点击
     * '上传' 灰色不可点击
     * cropping为false时：
     ** 点击图片缩略图右上角以外的任何区域时，显示原图大图，
     * 由右上角打钩按钮控制是否选中；
     *‘预览’灰色不可点击
     * '上传' 灰色不可点击

     * 选中状态下，
     ** cropping为true时：
     ** 点击图片缩略图右上角以外的任何区域时，进入裁剪控件，显示到点击的当前图片；
     * 由右上角打钩按钮控制是否选中；
     ** 点击‘预览’进入裁剪控件（加载所有需要裁剪的选中图片），显示第一个选中的图片裁剪，
     * '上传'按钮，若选中图片未裁剪，默认以最短边为准进行居中裁剪上传。
     * cropping为false时：
     ** 点击图片缩略图右上角以外的任何区域时，显示原图大图，
     * 由右上角打钩按钮控制是否选中；
     ** 点击‘预览’显示原图大图
     * '上传'按钮，上传原图
     *
     *
     *
     * return Array;
      [
           {
                path: "file:///storage/emulated/0/Pictures/d8c74bd1-a39e-4cf8-bf6d-c05115e4928f.jpg",//图片路径
                mime: "image/jpeg",//图片类型
                filename: "filename.jpg",//图片名
                size: 1216097,//片大小
                width: 2000//图片宽
                height: 2000,//图片高
                creationDate:"1564452233000",//图片创建时间
            }
     ];

     * **/
    static openPicker(options={}){
        options = Object.assign({},{
            cropping:false,//bool 可不传,//是否剪辑图片 默认是false;flase时打开大图，true时进入裁剪控件
            multiple:true,//bool 可不传,//是否图片多选 默认是false；多选时显示先后选中顺序，取消其中任意一个选中按顺序缩减，单选只显示1，选中另一个则取消上一个选中
            maxCount:-1,//number 可不传,//最大可选数量，multiple为true此字段有效；不传或为-1时，选择数量不受限制
            cropWidth:Dimensions.get('window').width,//number 可不传,//裁剪宽度 cropping为true并且cropWidth和cropHeight同时为正整数时有效，不传或为小于0时，以最短边为准进行居中裁剪
            cropHeight:Dimensions.get('window').width * 3 / 4,//number 可不传,//裁剪高度 cropping为true并且cropWidth和cropHeight同时为正整数时有效，不传或为小于0时，以最短边为准进行居中裁剪
        },options);
        console.info("openPickeropenPicker",options);
       /* let d = [
            {
                cropRect:
                    {
                        height: 750,//裁剪高度
                        width: 750,//裁剪宽度
                        x: 0,//裁剪X坐标
                        y: 188//裁剪Y坐标
                    },
                height: 2000,//原图片高
                mime: "image/jpeg",//图片类型
                modificationDate: "1564452233000",//裁剪时间
                createTime:"1564452233000",//原图片创建时间
                path: "file:///storage/emulated/0/Pictures/d8c74bd1-a39e-4cf8-bf6d-c05115e4928f.jpg",//图片路径
                size: 1216097,//图片大小
                width: 2000//原图片宽
            }
        ];*/
        return PickImgCroper.openPicker(options);
    }
}
