//
//  MDKImageWebHocker.swift
//  MDKImageCollection
//
//  Created by mikun on 2018/8/30.
//  Copyright © 2018 mdk. All rights reserved.
//

import UIKit
import WebKit

@objcMembers open class MDKImageWebHocker:NSObject {
	static let share:MDKImageWebHocker = MDKImageWebHocker()
	internal override init() {
		super.init()
	}
	public typealias ImageClickClose = (_ frame:CGRect,_ imageURLArray:[String] ,_ clickedIndex:Int)->()
	public func enableWhenClickImage(_ click:@escaping ImageClickClose) -> () {
		imageClickHandler = click
		enable = true
	}
	public func disable() -> () {
		enable = false
	}

	private var imageClickHandler:ImageClickClose?
	private var enable = false {
		didSet{
			if enable {
				if hockTap == nil {
					hockTap = UITapGestureRecognizer(target: self, action: #selector(self.resourceTap))
					hockTap?.delegate = self
				}
				webView?.addGestureRecognizer(hockTap!)
			}
			else {
				if (hockTap != nil) {
					webView?.removeGestureRecognizer(hockTap!)
				}
			}
		}
	}

	weak var webView: WKWebView?

	private var hockTap: UITapGestureRecognizer?

	private func handleTap(touchPoint:CGPoint , mUrlArray:[String]) -> () {
		let imgJS = "document.elementFromPoint(\(touchPoint.x), \(touchPoint.y))"
		let imgURLJS = "\(imgJS).src"
		let imgRectJS = "\(imgJS).getBoundingClientRect()"

		webView?.evaluateJavaScript(imgURLJS, completionHandler: { (imgUrl, error) in
			if let imgUrl = imgUrl as? String , mUrlArray.contains(imgUrl) {
				let imgIndex: Int = (mUrlArray as NSArray).index(of: imgUrl)
				self.webView?.evaluateJavaScript("\(imgRectJS).left", completionHandler: { (left, error) in self.webView?.evaluateJavaScript("\(imgRectJS).top", completionHandler: { (top, error) in self.webView?.evaluateJavaScript("\(imgRectJS).width", completionHandler: { (width, error) in self.webView?.evaluateJavaScript("\(imgRectJS).height", completionHandler: { (height, error) in

					guard
						let left = left as? CGFloat ,let top = top as? CGFloat ,
						let width = width as? CGFloat , let height = height as? CGFloat
					else {return}

					let imgRect = CGRect(x: left, y: top, width: width, height: height)

					self.imageClickHandler?(imgRect,mUrlArray, imgIndex)

				})})})})
			}
		})
	}
	private func convertUrlResult(urlResult:String,touchPoint:CGPoint) -> () {
		var mUrlArray = urlResult.components(separatedBy: "+")
		if mUrlArray.count >= 2 {
			mUrlArray.removeLast()
		}

		for obj in mUrlArray {
			if obj == webView?.url?.absoluteString || obj.contains(".gif") || obj.contains("wx_fmt=gif") {
				mUrlArray.remove(at: mUrlArray.index(of: obj)!)
				//微信公众号文章会出现图片链接跟文章地址一样的情况
			}
		}
		if mUrlArray.count > 0{
			handleTap(touchPoint: touchPoint,mUrlArray: mUrlArray)
		}
	}
	private let jsGetImages = """
function MDKImageGetAllImages(){\
	var objs = document.getElementsByTagName(\"img\");\
	var imgScr = '';\
	for(var i=0;i<objs.length;i++){\
		var src = objs[i].src;\
		var dataSrc = objs[i].data-src;\
		if(src.length>0 && src.substr(0,4) == \"http\"){\
			imgScr = imgScr + src + '+';\
		}else if(dataSrc.length>0 && dataSrc.substr(0,4) == \"http\"){\
			imgScr = imgScr + dataSrc + '+';\
		}\
	};\
	return imgScr;\
};
MDKImageGetAllImages();
"""
	@objc private func resourceTap(_ tap:UITapGestureRecognizer) -> () {
		let touchPoint: CGPoint = tap.location(in: webView)

		webView?.evaluateJavaScript("MDKImageGetAllImages()", completionHandler: { (urlResult, error) in
			if let urlResult = urlResult as? String {
				self.convertUrlResult(urlResult: urlResult, touchPoint: touchPoint)
			}
			else {
				self.webView?.evaluateJavaScript(self.jsGetImages, completionHandler: { (urlResult, _) in
					if let urlResult = urlResult as? String {
						self.convertUrlResult(urlResult: urlResult, touchPoint: touchPoint)
					}
				})
			}
		})
	}
}

extension MDKImageWebHocker: UIGestureRecognizerDelegate {
	public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		return true
	}

	public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		if let isDecelerating = webView?.scrollView.isDecelerating,isDecelerating {
			return false
		}
		return true
	}

}
