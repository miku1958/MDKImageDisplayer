//
//  File.swift
//  MDKImageCollection
//
//  Created by mikun on 2018/8/8.
//  Copyright © 2018年 mdk. All rights reserved.
//

@_exported import UIKit
@_exported import MDKTools

public protocol MDKImageProtocol:NSObjectProtocol{
	var imageView:UIImageView{get}
}

public enum SavePhotoFailType {
	case restricted
	case denied
	case saveingFail(NSError)
}
public enum SavePhotoResult {
	case success
	case fail(SavePhotoFailType)
}

@objc public enum LoadingPhotoQuality:Int{

	case thumbnail = -1
	case large = 1
	case original = 2
}



public typealias SavePhotoClose = (SavePhotoResult)->()
public typealias QRCodeHandlerClose = ([String:CGRect],CGPoint?)->()

typealias IndexClose = (Int) -> ()
public typealias intRtSelfClose = (Int) -> (MDKImageCollectionView)

public typealias IndexRtIntClose = (Int) -> (Int)

public typealias imageClose = (UIImage?)->()

public typealias OptionImgClose =  (CloseOption,@escaping imageClose)->()
public typealias OptionImgRtStringClose =  (CloseOption,@escaping imageClose)->(String?)

public typealias OptionImgRtBoolClose =  (CloseOption,@escaping imageClose)->(Bool)

