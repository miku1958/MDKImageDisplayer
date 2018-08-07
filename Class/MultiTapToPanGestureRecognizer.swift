//
//  File.swift
//  MDKImageCollection
//
//  Created by mikun on 2018/7/19.
//  Copyright © 2018 mdk. All rights reserved.
//

import UIKit.UIGestureRecognizerSubclass

class MultiTapToPanGestureRecognizer: UIPanGestureRecognizer {

	private var tapToPanCount = 2
	public var maxTimeTimeInterval:TimeInterval = 0.3
	public var miniTimeTimeInterval:TimeInterval = 0.1

	public var tapingCount = 0
	private var lastTapTime:TimeInterval = 0

	public var isPanning:Bool = false
	private var isSingleTap:Bool = false

	override func shouldRequireFailure(of otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		return super.shouldBeRequiredToFail(by: otherGestureRecognizer) || isPanning
	}
	open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {



		isSingleTap = false;




	}

	open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
		let trans = translation(in: nil)
		let now = Date().timeIntervalSince1970

		isPanning = isPanning || ((fabs(trans.x) > 1 || fabs(trans.y) > 1) && now - lastTapTime > maxTimeTimeInterval)

		if tapingCount == tapToPanCount {
			state = .changed
			super.touchesMoved(touches, with: event)
		}
	}

	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
		let now = Date().timeIntervalSince1970

		isPanning = false
		if (lastTapTime<miniTimeTimeInterval) {
			DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(maxTimeTimeInterval)) {


				self.state = .possible
				if self.isSingleTap , self.state == .possible{
					if (self.delegate?.gestureRecognizerShouldBegin?(self) ?? true) {
						self.isPanning = false
						self.state = .ended
					}
				}
				super.touchesEnded(touches, with: event)
				self.state = .possible
				self.reset()
				self.lastTapTime = 0;
			}

			finishTapPress()
			tapingCount = 1
			lastTapTime = NSDate().timeIntervalSince1970;
			isSingleTap = true;
			return;
		}
		if  now-lastTapTime > miniTimeTimeInterval && now-lastTapTime < maxTimeTimeInterval {
			isSingleTap = false;
			lastTapTime = 0;
			tapingCount += 1
			state = .began
			super.touchesBegan(touches, with: event)
		}
		if !isPanning ,tapingCount == tapToPanCount, now - lastTapTime < maxTimeTimeInterval {
			state = .ended
			super.touchesEnded(touches, with: event)
			state = .possible
		}else{
			let _isPanning = isPanning
			isPanning = true
			state = .possible
			super.touchesEnded(touches, with: event)
			state = .possible
			isPanning = _isPanning
		}
	}
	open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
		super.touchesCancelled(touches, with: event)
		self.finishTapPress()
	}
	private func finishTapPress() -> () {
		tapingCount = 0
		lastTapTime = 0
		isPanning = false
		self.reset()
	}

}
