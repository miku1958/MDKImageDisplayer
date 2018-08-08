//
//  TappingCheckGesture.swift
//  MDKImageCollection
//
//  Created by mikun on 2018/7/21.
//  Copyright © 2018 mdk. All rights reserved.
//

import UIKit.UIGestureRecognizerSubclass

class DoubleTapThanPanGesture: UIPanGestureRecognizer {
	open var tapCount = 2
	open var tappingCount = 0
	open var maxTimeTimeInterval:TimeInterval = 0.25

	private var lastTapTime:TimeInterval = 0


	var beginPoint:CGPoint = CGPoint()
	var didMoving:Bool = false
	open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
		let now = event.timestamp

		if now - lastTapTime > maxTimeTimeInterval {
			self.finishTapPress()
		}

		lastTapTime = now
		tappingCount = touches.first?.tapCount ?? 0

		if tapCount ==  tappingCount{
			super.touchesBegan(touches, with: event)
		}

		didMoving = false
		if let cPoint = touches.first?.location(in: nil){
			beginPoint = cPoint
		}
		let count = tappingCount
		DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(maxTimeTimeInterval)) {
			if count == self.tappingCount , count == 1 , !self.didMoving{
				self.state = .failed
				self.reset()
			}
		}
	}

	open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
		if touches.first?.tapCount ?? 0 == tapCount {
			super.touchesMoved(touches, with: event)
			if !didMoving , let pPoint = touches.first?.previousLocation(in: nil){
				didMoving = fabs(beginPoint.x - pPoint.x) > 1 ||  fabs(beginPoint.y - pPoint.y) > 1
			}
		}
	}

	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {

		if tappingCount == 1 {
			state = .possible
			let count = tappingCount
			DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(maxTimeTimeInterval)) {
				if count == self.tappingCount{
					self.state = .failed
					self.reset()
				}
			}
		}else if tappingCount == 2{
			state = .ended
			super.touchesEnded(touches, with: event)
		}else{
			super.touchesEnded(touches, with: event)
		}
	}

	open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
		super.touchesCancelled(touches, with: event)
		self.finishTapPress()
	}
	private func finishTapPress() -> () {
		lastTapTime = 0
	}
	
}
