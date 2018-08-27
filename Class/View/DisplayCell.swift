//
//  DisplayCell.swift
//  MDKImageCollection
//
//  Created by mikun on 2018/7/14.
//  Copyright © 2018 mdk. All rights reserved.
//

import UIKit


class DisplayCell: UICollectionViewCell,MDKImageProtocol {

	var updatingPhoto:Bool = false
	func setPhoto(_ photo:UIImage?,isThumbnail:Bool) -> () {
		guard let photo = photo else {return}
		updatingPhoto = true

		let size = photo.size
		if imageView.image == nil {
			imageView.image = photo
			contentScroll.zoomScale = 1
			imageView.sizeToFit()
			updateSize(size,resetOffset: true)
		}else{
			imageView.image = photo
			let ratio = size.width / size.height
			let lastRatio = self.imageView.frame.size.width / self.imageView.frame.size.height
			if fabs(ratio-lastRatio) > 0.01 {//防止两张图是因为缩小分辨率后比例稍微有些变化
				UIView.animate(withDuration: MDKImageTransition.duration, animations: {
					self.imageView.frame.size.height = self.imageView.frame.size.width / ratio
					self.scrollViewDidZoom(self.contentScroll)
				}) { (finish) in
					self.contentScroll.zoomScale = 1
					self.imageView.frame.size = size
					self.updateSize(size,resetOffset: isThumbnail)
					self.isScrolling = false
					self.updatingPhoto = false
				}
			}else{
				self.contentScroll.zoomScale = 1
				imageView.sizeToFit()
				updateSize(size,resetOffset: isThumbnail)
			}
		}

		isScrolling = false
		updatingPhoto = false
	}


	func updateSize(_ size:CGSize , resetOffset:Bool) -> () {
		contentScroll.contentSize = size

		fullWidthScale = MDKScreenWidth/size.width
		miniZoomScale = min(0.5, fullWidthScale)
		maxZoomScale = max(2, fullWidthScale)


		contentScroll.minimumZoomScale = miniZoomScale
		contentScroll.maximumZoomScale = maxZoomScale

		if contentScroll.zoomScale !=  fullWidthScale{
			contentScroll.setZoomScale(fullWidthScale, animated: false)
		}

		lastZoomScale = fullWidthScale

		if resetOffset {
			contentScroll.contentOffset = CGPoint()
		}
		stopScrollOffset = nil
		contentScroll.contentInset = UIEdgeInsets();

		scrollViewDidZoom(self.contentScroll)
	}

	var isScrolling:Bool = false {
		didSet{
			if isScrolling {
				
			}
		}
	}



	weak var scrollDelegate:UIScrollViewDelegate?
	let imageView:UIImageView = {
		let view = UIImageView()
		view.contentMode = .scaleAspectFill
		view.clipsToBounds = true
		return view
	}()

	var stopScrollOffset:CGPoint? = nil


	override init(frame: CGRect) {
		super.init(frame: frame)
		
		addSubview(contentScroll)
		contentScroll.addSubview(imageView)
		
		contentScroll.delegate = self
	}

	override func layoutSubviews() {
		contentScroll.frame = self.bounds
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	let contentScroll:UIScrollView = {
		let scroll = UIScrollView()
		
		if #available(iOS 11.0, *) {
			scroll.contentInsetAdjustmentBehavior = .never
		}
		
		return scroll
	}()
	
	
	var fullWidthScale:CGFloat = 0
	var miniZoomScale:CGFloat = 0
	var maxZoomScale:CGFloat = 0
	var lastZoomScale:CGFloat = 0
	func scale(finish:@escaping ()->()) -> () {
		imageView.layer.speed = 1

		UIView.animate(withDuration: 0.3, animations: {
			if self.fullWidthScale == self.miniZoomScale || self.fullWidthScale == self.maxZoomScale{
				if self.contentScroll.zoomScale != self.maxZoomScale{
					self.contentScroll.zoomScale = self.maxZoomScale
				}else{
					self.contentScroll.zoomScale = self.miniZoomScale
				}
				return
			}
			let lastScale = self.lastZoomScale
			self.lastZoomScale = self.contentScroll.zoomScale
			switch (lastScale,self.contentScroll.zoomScale) {

			case (self.fullWidthScale,self.fullWidthScale):
				self.contentScroll.zoomScale = self.maxZoomScale

			case (self.fullWidthScale,self.maxZoomScale):
				self.contentScroll.zoomScale = self.fullWidthScale

			case (self.maxZoomScale,self.fullWidthScale):
				self.contentScroll.zoomScale = self.miniZoomScale

			case (self.fullWidthScale,self.miniZoomScale):
				self.contentScroll.zoomScale = self.fullWidthScale

			case (self.miniZoomScale,self.fullWidthScale):
				self.contentScroll.zoomScale = self.maxZoomScale

			case (self.maxZoomScale,self.miniZoomScale):
				self.contentScroll.zoomScale = self.fullWidthScale

			case (self.miniZoomScale,self.maxZoomScale):
				self.contentScroll.zoomScale = self.fullWidthScale
				
			default:
				if self.contentScroll.zoomScale != self.maxZoomScale{
					self.contentScroll.zoomScale = self.maxZoomScale
				}else{
					self.contentScroll.zoomScale = self.miniZoomScale
				}
			}
		}) { (_) in
			finish()
		}
	}
	func makeScroll(stop:Bool) {
		isUserInteractionEnabled = !stop
		contentScroll.isScrollEnabled = !stop
		contentScroll.panGestureRecognizer.isEnabled = !stop
		if stop {
			stopScrollOffset = contentScroll.contentOffset
		}else{
			stopScrollOffset = nil
		}
	}
}


extension DisplayCell:UIScrollViewDelegate{
	func viewForZooming(in scrollView: UIScrollView) -> UIView? {
		return imageView
	}
	
	func scrollViewDidZoom(_ scrollView: UIScrollView) {
		if !updatingPhoto {
			scrollDelegate?.scrollViewDidZoom?(scrollView)
		}
		let showPicHeight = imageView.frame.size.height;
		let showPicWidth = imageView.frame.size.width;
		contentScroll.contentInset = UIEdgeInsetsMake(
				showPicHeight>MDKScreenHeight ? 0 :
					(MDKScreenHeight-showPicHeight)/2,
				showPicWidth>MDKScreenWidth ? 0 :
					(MDKScreenWidth-showPicWidth)/2,
				0,
				0
		)
	}


	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		if !updatingPhoto {
			scrollDelegate?.scrollViewDidScroll?(scrollView)
		}

		if scrollView == contentScroll{
			if let stopOffset = stopScrollOffset{
				contentScroll.setContentOffset(stopOffset, animated: false)
			}
			isScrolling = true
		}
	}

	func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
		if !decelerate {
			scrollViewDidEndDecelerating(scrollView)
		}
	}
	func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		DispatchQueue.main.asyncAfter(deadline: .now()+0.2) {
			self.isScrolling = false
		}
	}

	func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
		isScrolling = false
	}

	func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
		isScrolling = false
	}
}

