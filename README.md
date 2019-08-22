# react-native-pick-img-crop
目前此库正在开发中....<BR/>
暂时不支持手动自定义裁剪，只支持批量后台裁剪<BR/>
ios目前只能选取照片，不能裁剪；<BR/>
android还没有调试好，还无法使用，有兴趣的童靴可以先自己修改，代码可用<BR/>
高新能实用的相册图片选择器，可以多张图片选择和裁剪，也可以单张图片选择

### 展示ui图
<p>
    <img src ="./showImg/select.png" 
          height="auto" width="200" />
    <img src ="./showImg/filter.png"
          height="auto" width="200"/>
    <img src ="./showImg/crop1.png"
         height="auto" width="200"/>
    <img src ="./showImg/crop2.png"
         height="auto" width="200"/>
</p>

<!--![选择图片](./showImg/select.png)
  ![筛选图片](./showImg/filter.png)
  ![裁剪图片1](./showImg/crop1.png)
  ![裁剪图片2](./showImg/crop2.png)
  源码 https://github.com/huxinguang/XGImagePickerController?tdsourcetag=s_pcqq_aiomsg
  -->
  
  ###  安装组件：
  npm i --save react-native-pick-img-crop
  
  #### 传统链接
    react-native link react-native-pick-img-crop
  
  ### ios链接原生
  #### pod 链接
  将 pod 'RNPickImgCrop', :path => '../node_modules/react-native-pick-img-crop' 拷贝进Podfile即可；
  
  #### Android
	### `settings.gradle`
    ```gradle
    include ':react-native-pick-img-crop'
    project(':react-native-pick-img-crop').projectDir = new File(rootProject.projectDir, '../node_modules/react-native-pick-img-crop/android')
    ```
	### `build.gradle`
    ```gradle
    dependencies {
        compile project(':react-native-pick-img-crop')
    }
    ```

	###`MainApplication.java`
    ```java
   import com.luck.picture.lib.PhotoCropPickerPackage;

    public class MainApplication extends Application implements ReactApplication {
     @Override
       protected List<ReactPackage> getPackages() {
         return Arrays.<ReactPackage>asList(
             new MainReactPackage(),
               new PhotoCropPickerPackage()
         );
       }
    }
    ```
  
#### 使用
  ```javascript
  import PickImgCroper from "react-native-pick-img-crop";
  PickImgCroper.openPicker({
                                       cropping:false,//bool 可不传,//是否剪辑图片 默认是false;flase时打开大图，true时进入裁剪控件
                                       multiple:true,//bool 可不传,//是否图片多选 默认是false；多选时显示先后选中顺序，取消其中任意一个选中按顺序缩减，单选只显示1，选中另一个则取消上一个选中
                                       maxCount:-1,//number 可不传,//最大可选数量，multiple为true此字段有效；不传或为-1时，选择数量不受限制
                                       cropWidth:600,//number 可不传,//裁剪宽度 cropping为true并且cropWidth和cropHeight同时为正整数时有效，不传或为小于0时，以最短边为准进行居中裁剪
                                       cropHeight:450,//number 可不传,//裁剪高度 cropping为true并且cropWidth和cropHeight同时为正整数时有效，不传或为小于0时，以最短边为准进行居中裁剪
                                   })
  .then(res=>{
      console.info("res",res)
  });

  ```
  
  
### 欢迎交流
欢迎提问交流；若有bug，请添加bug截图或代码片段，以便更快更好的解决问题。<br>
欢迎大家一起交流

### [我的博客](http://blog.sina.com.cn/s/articlelist_6078695441_0_1.html)
