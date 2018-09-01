# MDKImageCollection

### 一套结合iOS原生相册和微信等app优点的图片展示方案



#### 特性：

手势下滑关闭

dismiss手势的时候毛玻璃模糊度变化只支持iOS10以后

![](https://github.com/miku1958/MDKImageCollection/raw/master/photo/2.gif)

上滑呼出菜单

二维码识别,多个二维码的时候会弹出选择

![](https://github.com/miku1958/MDKImageCollection/raw/master/photo/3.gif)



支持在IM等聊天页面中跨信息切换原图

```
MDKImageDisplayController *display = [[MDKImageDisplayController alloc]initWithLargeClose:^NSString * _Nullable(MDKImageCloseOption * option, void (^ handler)(UIImage *)) {
	利用option.index和option.lastIdentifier来返回一个identifer
        
    异步加载image
    handler(image);
}];
```

![](https://github.com/miku1958/MDKImageCollection/raw/master/photo/4.gif)

webview嵌入（只支持了WKWebView，以下用swift展示）

![](https://github.com/miku1958/MDKImageCollection/raw/master/photo/5.gif)

```
webView.MDKImage.enableWhenClickImage {[weak self] (frame,imageURLArray,clickIndex)  in
    let display = MDKImageDisplayController(photoCount: imageURLArray.count, largeClose: {  (option, handler) in
        //下载图片image
        handler(image)
    })
    display.setDisplayIndex(clickIndex)
    if let nav = self?.navigationController{
        display.transition.sourceScreenInset = UIEdgeInsets(top: nav.navigationBar.frame.maxY, left: 0, bottom: 0, right: 0)
    }

    display.registerAppearSourecFrame({ () -> (CGRect) in
        return frame
    })
    display.registerDismissTargetFrame({ (option) -> (CGRect) in
        if option.index == clickIndex{
            return frame
        }
        return CGRect()//代表进行渐变过度
    })

    self?.present(display, animated: true, completion: nil)
}
```



#### 计划中特性：

1. ~~webview嵌入~~（完成）
2. 读取时的占位提示（圆圈）
3. gif支持
4. ~~视频支持~~
5. live photo 支持？（不确定能不能做，可能和视频一样做不了）
6. 用metal改写模糊特效提高性能





简单入门：

pod ‘MDKImageCollection’



#### 创建MDKImageDisplayController

方法1，通过index来管理内容

```
MDKImageDisplayController *display = [[MDKImageDisplayController alloc]initWithPhotoCount:imageArr.count largeClose:^(MDKImageCloseOption * option, void (^ handler)(UIImage *)) {
	handler(imageArr[option.index]);	
}];
```



方法2，通过identifer来管理内容，如假设imageView.image就是打开的大图：

```swift
__weak typeof(self) _self = self;
MDKImageDisplayController *display = [[MDKImageDisplayController alloc]initWithLargeClose:^NSString * (MDKImageCloseOption * option, void (^ handler)(UIImage * image)) {
    if (!option.lastIdentifier) {//首张打开的图片是没有lastIdentifier的
        handler(view.image);
        return identifer;
    }else{
        NSInteger lastIndex = [_self indexWithIdentifer:option.lastIdentifier];
        if (option.index>0) {
            if (lastIndex == 3) {
                return nil;
            }
            lastIndex += 1;
            handler([_self imageViewWithIndex:lastIndex].image);
            return [_self identiferWithWithIndex:lastIndex];
        }else{
            if (lastIndex == 0) {
                return nil;
            }
            lastIndex -= 1;
            handler([_self imageViewWithIndex:lastIndex].image);
            return [_self identiferWithWithIndex:lastIndex];
        }
    }
}];
```



注册缩放动画的来源view：

```
__weak typeof(self) _self = self;
display.registerAppearSourecView = ^UIView *{
//获取出现时的来源view
	return view;
};
display.registerDismissTargetView = ^UIView * (MDKImageCloseOption * option) {
//获取消失时的目标view
	return [_self imageViewWithIndex:[_self indexWithIdentifer:option.lastIdentifier]];
};
```



关闭高斯模糊背景：

```
display.disableBlurBackgroundWithBlack = true;
```



由于从3Dtouchpresent出来不会走transition动画，如果要实现3Dtouch，以下是临时解决办法：

在

```
- (nullable UIViewController *)previewingContext:(id <UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location NS_AVAILABLE_IOS(9_0);
```

中创建MDKImageDisplayController *display;后，设置

```
display.isFrom3DTouch = true;
```

以解决动画错误



完整代码查看DemoCtr