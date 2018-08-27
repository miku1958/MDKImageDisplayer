//
//  photoNode.swift
//  MDKImageCollection
//
//  Created by mikun on 2018/7/10.
//  Copyright © 2018 mdk. All rights reserved.
//




struct photoNode {
	var photoQuality:LoadingPhotoQuality = .thumbnail
	var index:Int = 0
	weak var photo:UIImage?
	var identifier:String? {
		didSet{
			if identifier == nil {
				
			}
		}
	}

	var QRCode:[String:CGRect]? = nil
	var needCheckQRCode:Bool = false
	var isCheckingQRCode:Bool = false
	var browsingOffset:CGPoint?
	var browsingScale:CGFloat?
	var isDequeueFromIdentifier:Bool = false
	var updatingCell:Bool = false
	mutating func checkHasQRCode(finish:()->()) -> () {

		if QRCode != nil{
			finish()
			return
		}
		if isCheckingQRCode {
			return
		}
		guard let photo = photo , let cgImage = photo.cgImage else {
			needCheckQRCode = true
			return
		}

		isCheckingQRCode = true

		var ciImage = CIImage(cgImage: cgImage)

		let ciContext = CIContext(options: nil)

		var photoSize = photo.size
		photoSize.width *= photo.scale
		photoSize.height *= photo.scale
		if photoSize.width<640 {
			let sacle = 1080/photoSize.width
			let transform = CGAffineTransform(scaleX: sacle, y: sacle);
			ciImage = ciImage.transformed(by: transform)
			let ratio = photoSize.width/photoSize.height
			photoSize.width = 1080
			photoSize.height = 1080/ratio
		}

		let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: ciContext, options: [CIDetectorAccuracy:CIDetectorAccuracyLow])

		QRCode = [:]
		guard let features = detector?.features(in: ciImage) else {
			isCheckingQRCode = false
			return
		}


		if features.count > 0 {
			for case let feature as CIQRCodeFeature in features {
				if let message = feature.messageString , message.count > 0{
					QRCode?[message] = CGRect(
						origin:
							CGPoint(x: feature.bounds.origin.x , y: photoSize.height - feature.bounds.origin.y - feature.bounds.height),
						size:
							feature.bounds.size
					)
				}
			}
		}
		if photoSize != photo.size , QRCode != nil {
			let ratio = photoSize.width / photo.size.width
			for qc in QRCode!{
				var bounds = qc.value
				bounds.origin.x /= ratio
				bounds.origin.y /= ratio
				bounds.size.width /= ratio
				bounds.size.height /= ratio
				QRCode![qc.key] = bounds
			}
		}
		isCheckingQRCode = false
		finish()
	}

}



