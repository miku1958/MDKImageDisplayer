# MDKImageCollection

### 一套结合iOS原生相册和微信等app优点的图片展示方案



#### 特性：

1. 支持动态加载

```swift
imageCollection.thumbnailForIndexUseCheck(close: { (option, handler) in
	handler(UIImage(named: "\(option.index%3)"))
	return true//这里返回true就能不停的添加新的cell
})
```

![](https://github.com/miku1958/MDKImageCollection/raw/master/photo/1.gif)

1. 支持3DTouch打开

```swift
imageCollection.registerFor3DTouchPreviewing(self)//self为ViewController
```

如果不是在ViewController中创建imageCollection，可以：

```swift
imageCollection.quickRegister3DTouchPreviewing()
```

1. 手势下滑关闭

<!--dismiss手势的时候毛玻璃模糊度变化只支持iOS10以后-->

![](https://github.com/miku1958/MDKImageCollection/raw/master/photo/2.gif)

1. 上滑呼出菜单

1. 二维码识别,多个二维码的时候会弹出选择

![](https://github.com/miku1958/MDKImageCollection/raw/master/photo/3.gif)



1. 支持在IM等聊天页面中跨信息切换原图

截图，示例代码



#### 计划中特性：

1. webview嵌入
2. 读取时的占位提示（圆圈）
3. gif支持
4. ~~视频支持~~
5. live photo 支持？（不确定能不能做，可能和视频一样做不了）





简单入门：

pod ‘MDKImageCollection’



#### 创建imageCollection

```swift
let flow = UICollectionViewFlowLayout()//目前只支持UICollectionViewFlowLayout，后续会修改
flow.itemSize = CGSize(width: 100, height: 100)
let imageCollection = MDKImageCollectionView(frame: CGRect(), flowLayout: flow)
```



#### 注册缩略图

直到图片数量的时候：

```
imageCollection.thumbnailForIndex(count: 40, close: { (option, handler) in

	{//异步下载UIImage
		handler(<#下载UIImage#>)
    }

    if option.index == 39{
        self.imageCollection.updateCount(80)//updateCount用来更新图片数量
    }
})

```

如果不确定图片数量可以：

```
imageCollection.thumbnailForIndexUseCheck(close: { (option, handler) in
    {//异步下载UIImage
        handler(<#下载UIImage#>)
    }
    return true
})
```



#### 注册原图

```
imageCollection.largeForIndex { (option, handler) in
    {//异步下载UIImage
        handler(<#下载UIImage#>)
    }
}
```



#### 链式支持

```
imageCollection.thumbnailForIndexUseCheck(close: { (option, handler) in
    handler(UIImage(named: "\(option.index%3)"))
    return true
}).largeForIndex { (option, handler) in
    handler(UIImage(named: "\(option.index%3)"))
}
```





跨信息切换原图

```
imageCollection.largeIdentifierClose { (option, handler) in
	let lastIdentifier = option.lastIdentifier
	if option.index>0{
        lastIdentifier对应cell的下一个
	}else{
		lastIdentifier对应cell的上一个
	}
	
	根据option.lastIdentifier和option.index获取下一个/前一个cell的identifier
	let identifier = ...
	
    {//异步下载UIImage
        handler(<#下载UIImage#>)
    }
    return identifier//这个identifier是用来定位的,
}
```

同时，这个identifier也是原图浏览器的Transition动画标识符，如果想要实现跨cell 的dismiss动画：



需要把这个identifier设置为imageCollection.customTransitionID替换默认的Transition动画标识符

完整代码查看DemoCtr
