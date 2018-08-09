//
//  CloseOption.swift
//  MDKImageCollection
//
//  Created by mikun on 2018/8/8.
//  Copyright © 2018年 mdk. All rights reserved.
//



@objc public class CloseOption :NSObject{
	@objc public var lastIdentifier:String?
	@objc public var section:Int = 0
	@objc public var item:Int = 0
	@objc public var needQuality:LoadingPhotoQuality = .thumbnail
	@objc public var displayCtr:UIViewController!
}
