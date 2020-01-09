package com.luck.picture.lib;

import android.app.Activity;
import android.content.Intent;
import android.util.Base64;
import android.util.Log;

import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.BaseActivityEventListener;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableNativeArray;
import com.facebook.react.bridge.WritableNativeMap;
import com.luck.picture.lib.config.PictureConfig;
import com.luck.picture.lib.config.PictureMimeType;
import com.luck.picture.lib.entity.LocalMedia;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;

public class PhotoCropPicker extends ReactContextBaseJavaModule {
    private ReactApplicationContext mContext;
    private Promise mPromise;
    private final int REQUEST_ECODE_SCAN = 1;
    private final int RESULT_OK = -1;
    private boolean cropping = false;
    private boolean multiple = false;
    private boolean isCamera = true;
    private int cropWidth=200;
    private int cropHeight=200;
    private int maxCount = 1;
    private boolean includeBase64 = false;//是否包含Base64编码

    private final ActivityEventListener mActivityEventListener = new BaseActivityEventListener() {
        @Override
        public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent data) {
            Log.e("requestCode" + requestCode, resultCode + "resultCode");
            if (resultCode == RESULT_OK && requestCode == PictureConfig.CHOOSE_REQUEST) {
//                // 图片、视频、音频选择结果回调
                List<LocalMedia> selectList = PictureSelector.obtainMultipleResult(data);
                if(!multiple && selectList.size() > 1){
                    List<LocalMedia> lst = new ArrayList<>();
                    lst.add(selectList.get(0));
                }

//                // 例如 LocalMedia 里面返回三种path
//                // 1.media.getPath(); 为原图path
//                // 2.media.getCutPath();为裁剪后path，需判断media.isCut();是否为true  注意：音视频除外
//                // 3.media.getCompressPath();为压缩后path，需判断media.isCompressed();是否为true  注意：音视频除外
//                // 如果裁剪并压缩了，以取压缩路径为准，因为是先裁剪后压缩的
                WritableArray writableArray = new WritableNativeArray();
                WritableMap image;
                for (LocalMedia localMedia : selectList) {
                    image = new WritableNativeMap();
                    String path;
                    if (localMedia.isCut()) {
                        path = localMedia.getCutPath();
                    } else if (localMedia.isCompressed()) {
                        path = localMedia.getCompressPath();
                    } else {
                        path = localMedia.getPath();
                    }

                    image.putString("path", "file://" + path);
                    if(includeBase64){
                        image.putString("data", getBase64StringFromFile(path));
                    }
                    writableArray.pushMap(image);
                }
                mPromise.resolve(writableArray);
            }
        }
    };

    public PhotoCropPicker(ReactApplicationContext reactContext) {
        super(reactContext);
        mContext = reactContext;
        mContext.addActivityEventListener(mActivityEventListener);
    }

    private void readOption(ReadableMap option) {
        cropping = option.hasKey("cropping") ? option.getBoolean("cropping") : false;
        multiple = option.hasKey("multiple") ? option.getBoolean("multiple") : false;
        isCamera = option.hasKey("isCamera") ? option.getBoolean("isCamera") : true;
        includeBase64 = option.hasKey("includeBase64") ? option.getBoolean("includeBase64") : false;
        cropWidth= option.hasKey("cropWidth") ? option.getInt("cropWidth") : 200;
        cropHeight=option.hasKey("cropHeight") ? option.getInt("cropHeight") : 200;
        if (multiple) {
            maxCount = option.hasKey("maxCount") ? option.getInt("maxCount") : -1;
            if (maxCount == -1) {
                maxCount = 99;
            }
        } else {
            maxCount = 1;
        }
    }

    @Override
    public String getName() {
        return "RNPickImgCrop";
    }

    @ReactMethod
    public void openPicker(ReadableMap option, Promise promise) {
        mPromise = promise;
        readOption(option);
        PictureSelector.create(getCurrentActivity())
                .openGallery(PictureMimeType.ofImage())//全部.PictureMimeType.ofAll()、图片.ofImage()、视频.ofVideo()、音频.ofAudio()
                .maxSelectNum(maxCount)// 最大图片选择数量 int
                .minSelectNum(1)// 最小选择数量 int
                .imageSpanCount(3)// 每行显示个数 int
                .selectionMode(multiple ? PictureConfig.MULTIPLE : PictureConfig.SINGLE)// 多选 or 单选 PictureConfig.MULTIPLE or PictureConfig.SINGLE
//                .previewImage(true)// 是否可预览图片 true or false
                .isCamera(isCamera)// 是否显示拍照按钮 true or false
                .imageFormat(PictureMimeType.PNG)// 拍照保存图片格式后缀,默认jpeg
                .isZoomAnim(true)// 图片列表点击 缩放效果 默认true
                .sizeMultiplier(0.5f)// glide 加载图片大小 0~1之间 如设置 .glideOverride()无效
                .setOutputCameraPath("/CustomPath")// 自定义拍照保存路径,可不填
                .enableCrop(cropping)// 是否裁剪 true or false
                .compress(true)// 是否压缩 true or false
//                .glideOverride()// int glide 加载宽高，越小图片列表越流畅，但会影响列表图片浏览的清晰度
                .withAspectRatio(cropWidth, cropHeight)// int 裁剪比例 如16:9 3:2 3:4 1:1 可自定义
                .hideBottomControls(true)// 是否显示uCrop工具栏，默认不显示 true or false
                .isGif(false)// 是否显示gif图片 true or false
//                .compressSavePath(getPath())//压缩图片保存地址
                .freeStyleCropEnabled(false)// 裁剪框是否可拖拽 true or false
//                .circleDimmedLayer()// 是否圆形裁剪 true or false
                .showCropFrame(true)// 是否显示裁剪矩形边框 圆形裁剪时建议设为false   true or false
                .showCropGrid(true)// 是否显示裁剪矩形网格 圆形裁剪时建议设为false    true or false
//                .selectionMedia()// 是否传入已选图片 List<LocalMedia> list
//                .previewEggs()// 预览图片时 是否增强左右滑动图片体验(图片滑动一半即可看到上一张是否选中) true or false
//                .cropCompressQuality()// 裁剪压缩质量 默认90 int
//                .minimumCompressSize(100)// 小于100kb的图片不压缩
//                .synOrAsy(true)//同步true或异步false 压缩 默认同步
//                .cropWH()// 裁剪宽高比，设置如果大于图片本身宽高则无效 int
                .rotateEnabled(true) // 裁剪是否可旋转图片 true or false
                .scaleEnabled(false)// 裁剪是否可放大缩小图片 true or false
                .isDragFrame(true)// 是否可拖动裁剪框(固定)
                .forResult(PictureConfig.CHOOSE_REQUEST);//结果回调onActivityResult code
    }


    /***
     * 读取图片的Base64编码
     * ***/
    private String getBase64StringFromFile(String absoluteFilePath) {
        InputStream inputStream;

        try {
            inputStream = new FileInputStream(new File(absoluteFilePath));
        } catch (FileNotFoundException e) {
            e.printStackTrace();
            return null;
        }

        byte[] bytes;
        byte[] buffer = new byte[8192];
        int bytesRead;
        ByteArrayOutputStream output = new ByteArrayOutputStream();

        try {
            while ((bytesRead = inputStream.read(buffer)) != -1) {
                output.write(buffer, 0, bytesRead);
            }
        } catch (IOException e) {
            e.printStackTrace();
        }

        bytes = output.toByteArray();
        return Base64.encodeToString(bytes, Base64.NO_WRAP);
    }
}
