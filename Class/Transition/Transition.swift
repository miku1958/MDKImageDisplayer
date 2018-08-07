//
//  Transition.swift
//  MDKImageCollection
//
//  Created by mikun on 2018/7/25.
//  Copyright © 2018 mdk. All rights reserved.
//

import UIKit

extension UIView{
	func contain(subview targetView:UIView) -> Bool {
		for view in subviews {
			if view == targetView {
				return true
			}
			if view.contain(subview: targetView) {
				return true
			}
		}

		return false
	}
}

class Transition: NSObject{
	static private weak var instance:Transition?
	class func global() -> Transition {
		var strongInstance = instance
		if strongInstance == nil {
			strongInstance = Transition()
			instance = strongInstance
		}
		return strongInstance!
	}
	

	var ImageCornerRadius:CGFloat = 0

	private static let lock:DispatchSemaphore = DispatchSemaphore(value: 1)
	static let syncQueue = DispatchQueue(label: "MDKImageFlushQueue",attributes: [])

	static func synchronized(_ close:(()->())) -> () {
		Transition.lock.wait()
		defer { Transition.lock.signal() }
		close()
	}

	var  isPresented:Bool = true
	static let duration:TimeInterval = 0.35


	weak var _transitionContext:UIViewControllerContextTransitioning?

	func forceTransitionContextCompleteTransition() -> () {
		print(#function)
		_transitionContext?.completeTransition(true)
		transitingView?.layer.mask = nil
		animatingCtr?.view.isUserInteractionEnabled = true
	}
	weak var transitingView:UIView?
	var transitingViewGravity:String?

	static var viewMap:[String:NSHashTable<UIView>] = [:]
	static func register(view:UIView , for key:String) -> () {
		antiRegistr(view: view)
		if Transition.viewMap[key] == nil {
			Transition.viewMap[key] = NSHashTable.weakObjects()
		}
		Transition.viewMap[key]?.add(view)
	}

	static func antiRegistr(view:UIView) -> () {
		for (mapKey,views) in Transition.viewMap {
			views.remove(view)
			if views.count == 0{
				Transition.viewMap.removeValue(forKey: mapKey)
			}
		}
	}

	weak var sourceCtr:UIViewController?
	weak var animatingCtr:MDKImageDisplayController?
	func dismiss(viewController : MDKImageDisplayController) {
		print(#function)
		animatingCtr = viewController
		transitingView?.layer.beginTime = CACurrentMediaTime()
		didViewAnimation(to: nil, from: viewController.view)
		transitingView?.layer.masksToBounds = false
	}

	var process:CGFloat?{
		didSet{

			if var process = process{
				process = max(0, min(1, process))
				if let transitingView = transitingView {
					transitingView.layer.speed = 0.0;
					transitingView.layer.timeOffset = CFTimeInterval(process) * Transition.duration
				}
//				if let blurLayer = dismissingCtr?.blurView.layer {
//					blurLayer.speed = 0.0;
//					blurLayer.timeOffset = 0.2//CFTimeInterval(process) * Transition.duration
//				}
	
			}
		}
	}
	var animationTargetPosition:CGPoint?
	func controlTransitionView(position:CGPoint) -> () {
		print(#function)

		guard let transitingView = transitingView	 , let sourcePosition = transitingView.layer.value(forKey: "position") as? CGPoint , let targetPosition = animationTargetPosition else { return }

		let ratio = CGFloat(transitingView.layer.timeOffset / Transition.duration)
		let currentPosition = CGPoint(x: (sourcePosition.x - targetPosition.x) * ratio , y: (sourcePosition.y - targetPosition.y) * ratio)
		transitingView.transform.tx = position.x + (currentPosition.x/max(transitingView.layer.transform.m11, 1))
		transitingView.transform.ty = position.y + (currentPosition.y/max(transitingView.layer.transform.m22, 1))
	}
	
	func cancelDismiss() {
		print(#function)
		guard let view = transitingView else { return }
		if finishingDismiss { return }
		animatingCtr?.view.isUserInteractionEnabled = false
		finishingDismiss = true
		rollbackTransformT = CGPoint(x: view.transform.tx, y: view.transform.ty)
		rollbackBeginOffset = view.layer.timeOffset
		dismissingTimeInterval = (rollbackBeginOffset)/(Transition.duration*60)
		commitLayerAnimation(view ,rollback: true)
	}

	var finishingDismiss:Bool = false
	func commitDismiss() {
		print(#function)
		guard let view = transitingView else {
			forceTransitionContextCompleteTransition()
			animatingCtr?.dismiss(animated: true, completion: nil)
			return
		}
		
		if finishingDismiss { return }
		finishingDismiss = true
		
		animatingCtr?.view.isUserInteractionEnabled = false

		view.layer.contentsGravity = kCAGravityResizeAspectFill
		view.layer.masksToBounds = true
		rollbackTransformT = CGPoint(x: view.transform.tx, y: view.transform.ty)
		rollbackBeginOffset = view.layer.timeOffset
		dismissingTimeInterval = (Transition.duration-rollbackBeginOffset)/(Transition.duration*60)
		commitLayerAnimation(view ,rollback: false)



	}
	var rollbackTransformT:CGPoint = CGPoint()
	var rollbackBeginOffset:TimeInterval = 0
	var dismissingTimeInterval:TimeInterval = 0
	func commitLayerAnimation(_ view:UIView , rollback:Bool){
		print(#function)
		let layer = view.layer
		var timeOffset = layer.timeOffset
		print("timeOffset : \(timeOffset)")
		if dismissingTimeInterval == 0 {
			dismissingTimeInterval = 0.000000001
		}
		rollback ? (timeOffset -= dismissingTimeInterval) : (timeOffset += dismissingTimeInterval)
		if rollback ? (timeOffset < 0) : (timeOffset > Transition.duration) {
			if rollback{
				layer.removeAllAnimations()
//				layer.speed = 1.0
				layer.timeOffset = 0
//				layer.beginTime = CACurrentMediaTime()
				forceTransitionContextCompleteTransition()
				print("removeAllAnimations")
			}else if let animKey = layer.animationKeys()?.first , let anim = layer.animation(forKey: animKey){
				animationDidStop(anim, finished: true)
				print("animationDidStop")
			}

			view.transform.tx = 0
			view.transform.ty = 0
			finishingDismiss = false
			animatingCtr?.view.isUserInteractionEnabled = true
			return
		}

		var reduce:CGFloat = 0
		if rollback {
			if rollbackBeginOffset == 0{
				reduce = 0
			}else{
				reduce = CGFloat(timeOffset / rollbackBeginOffset)
			}
		}else{
			if Transition.duration == rollbackBeginOffset{
				reduce = 0
			}else{
				reduce = CGFloat((Transition.duration - timeOffset) / (Transition.duration - rollbackBeginOffset))
			}
		}
		print("timeOffset:\(timeOffset)  rollbackBeginOffset: \(rollbackBeginOffset)   reduce :\(reduce)")
		view.transform.tx = rollbackTransformT.x * reduce
		view.transform.ty = rollbackTransformT.y * reduce

		layer.timeOffset = min(max(timeOffset, 0), Transition.duration)

		DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(1/60.0)) {
			self.commitLayerAnimation(view, rollback: rollback)
		}
	}


	func resetLayer(_ layer:CALayer) -> () {

	}
}
extension Transition : UIViewControllerTransitioningDelegate{
	func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
		return TransitionController(presentedViewController: presented, presenting: presenting)
	}
	func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		self.isPresented = true
		return self
	}

	func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		self.isPresented = false
		return self
	}
}

extension Transition :  UIViewControllerAnimatedTransitioning{

	func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
		return Transition.duration
	}

	func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
		print(#function)
		finishingDismiss = false
		_transitionContext = transitionContext
		if (isPresented) {
			guard let toView = transitionContext.view(forKey: .to) else {return}
			animatingCtr = transitionContext.viewController(forKey: .to) as? MDKImageDisplayController
			sourceCtr = transitionContext.viewController(forKey: .from)
			didViewAnimation(to: toView, from: nil)
		} else {
			guard let fromView = transitionContext.view(forKey: .from) else {return}
			animatingCtr = transitionContext.viewController(forKey: .from) as? MDKImageDisplayController
			sourceCtr = transitionContext.viewController(forKey: .to)
			didViewAnimation(to: nil, from: fromView)
		}
	}

	func didViewAnimation(to:UIView?,from:UIView?) -> () {
		print(#function)

		var containVIew:UIView!
		var isPresent:Bool = false
		if to != nil {
			containVIew = to!
			isPresent = true
		}else if from != nil {
			containVIew = from!
		}
		if containVIew == nil{
			return
		}

		var allTargetViews:[UIView] = []
		var hasViewPair:Bool = false
		for (_,views) in Transition.viewMap {
			let enumerator = views.objectEnumerator()
			var targetViews:[UIView] = []
			var sourceViews:Set<UIView> = Set()
			while let view = enumerator.nextObject() as? UIView {
				
				if let frame = view.superview?.convert(view.frame, to: MDKKeywindow),MDKKeywindow.frame.intersects(frame){
					if containVIew.contain(subview: view) {
						targetViews.append(view)
					}else{
						sourceViews.update(with: view)
					}
				}
				
				if targetViews.count>0,sourceViews.count>0{
					break
				}
			}

			for view in targetViews{
				if let sourceView = sourceViews.first ,
					let sourceSuperView = sourceView.superview{

					hasViewPair = true
					let sourceFrameOri = sourceView.frame
					var sourceFrameMask = sourceFrameOri
					if var sourceCtr = sourceCtr{
						if sourceCtr.isKind(of: UITabBarController.self) , let selected = (sourceCtr as! UITabBarController).selectedViewController{
							sourceCtr = selected
						}
						var navCtr:UINavigationController?
						if sourceCtr.isKind(of: UINavigationController.self){
							navCtr = sourceCtr as? UINavigationController
						}else{
							navCtr = sourceCtr.navigationController
						}
						if let hidden = navCtr?.isNavigationBarHidden,!hidden,let navBar = navCtr?.navigationBar{
							let sourceFrameToKeyWindow = sourceSuperView.convert(sourceFrameOri, to: MDKKeywindow)
							if sourceFrameToKeyWindow.origin.y < navBar.frame.maxY{
								let insert = navBar.frame.maxY-sourceFrameToKeyWindow.origin.y
								sourceFrameMask.size.height -= insert
								sourceFrameMask.origin.y += insert
							}
							print(sourceFrameToKeyWindow)
						}
					}

					let sourceFrameToTarget = sourceSuperView.convert(sourceFrameOri, to: view.superview)
					let maskFrameToTarget = sourceSuperView.convert(sourceFrameMask, to: view.superview)


					updateLayer(from: view, sourceFrame: sourceFrameToTarget ,maskFrame:maskFrameToTarget, isPresent: isPresent)
					animatingCtr?.view.isUserInteractionEnabled = false
				}else{
					allTargetViews.append(contentsOf: targetViews)
				}
			}
		}
		if !hasViewPair {
			if isPresent {
				for view in allTargetViews{
					view.alpha = 0
				}
			}
			
			animatingCtr?.view.isUserInteractionEnabled = false
			UIView.animate(withDuration: Transition.duration, animations: {
				for view in allTargetViews{
					view.alpha = isPresent ? 1 : 0
				}
			}) { (finish) in
				self.forceTransitionContextCompleteTransition()
				
				self.animatingCtr?.view.isUserInteractionEnabled = true
			}
		}
	}


	func updateLayer(from view:UIView , sourceFrame:CGRect , maskFrame:CGRect , isPresent:Bool) -> () {

		print(#function)
		if finishingDismiss {
			forceTransitionContextCompleteTransition()
			return
		}

		if sourceFrame != maskFrame {

			let mask = CALayer()
			mask.backgroundColor = UIColor.white.cgColor

			let sourcebounds = CGRect(origin: CGPoint(), size: CGSize(width: maskFrame.width/view.layer.transform.m11, height: maskFrame.height/view.layer.transform.m22));
			let viewbounds = view.layer.bounds
			mask.bounds = sourcebounds;
			mask.anchorPoint.x = 0
			mask.anchorPoint.y = 0

			mask.position = maskFrame.origin
			mask.position.y += sourceFrame.height - maskFrame.height

			let maskBoundsAnim = CABasicAnimation()
			maskBoundsAnim.keyPath = "bounds"
			isPresent ? (maskBoundsAnim.toValue = viewbounds) : (maskBoundsAnim.fromValue = viewbounds)


			let maskPositionAnim = CABasicAnimation()
			maskPositionAnim.keyPath = "position"

			isPresent ? (maskPositionAnim.toValue = CGPoint()) : (maskPositionAnim.fromValue = CGPoint())


			let maskGroup = CAAnimationGroup()
			maskGroup.animations = [maskBoundsAnim,maskPositionAnim]

			maskGroup.duration = Transition.duration
			maskGroup.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)


			maskGroup.isRemovedOnCompletion = false;
			maskGroup.fillMode = kCAFillModeForwards;

			mask.add(maskGroup, forKey: "animateTransition")
			view.layer.mask = mask

		}


		let boundsAnim = CABasicAnimation()
		boundsAnim.keyPath = "bounds"

		let bounds = CGRect(origin: sourceFrame.origin, size: CGSize(width: sourceFrame.width/view.layer.transform.m11, height: sourceFrame.height/view.layer.transform.m22))

		isPresent ? (boundsAnim.fromValue = bounds) : (boundsAnim.toValue = bounds)

		let positionAnim = CABasicAnimation()
		positionAnim.keyPath = "position"

		animationTargetPosition = CGPoint(x: sourceFrame.origin.x + sourceFrame.width/2, y: sourceFrame.origin.y + sourceFrame.height/2)

		isPresent ? (positionAnim.fromValue = animationTargetPosition) : (positionAnim.toValue = animationTargetPosition)

		let cornerRadiusAnim = CABasicAnimation()

		cornerRadiusAnim.keyPath = "cornerRadius"
		let ImageCornerRadius =  self.ImageCornerRadius/view.layer.transform.m22
		isPresent ? (cornerRadiusAnim.fromValue = ImageCornerRadius) : (cornerRadiusAnim.toValue = ImageCornerRadius)


		let group = CAAnimationGroup()
		group.animations = [boundsAnim,positionAnim,cornerRadiusAnim]

		group.duration = Transition.duration
		group.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)


		group.isRemovedOnCompletion = false;
		group.fillMode = kCAFillModeForwards;
		let delegate = AnimationProxy()
		delegate.delegate = self
		group.delegate = delegate
		for _ in group.animations! {
//			print(anim.debugDescription)
		}

//		view.layer.beginTime = CACurrentMediaTime()//打开会导致3d touch打开后dismiss的动画无效
		view.layer.timeOffset = 0
		view.layer.speed = 1
		view.layer.add(group, forKey: "animateTransition")
		transitingView = view

		transitingViewGravity = view.layer.contentsGravity
		view.layer.contentsGravity = kCAGravityResizeAspectFill
		view.layer.masksToBounds = true



	}
}
class AnimationProxy:NSObject,CAAnimationDelegate {
	weak var delegate:CAAnimationDelegate?
	func animationDidStart(_ anim: CAAnimation) {

	}
	func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
		delegate?.animationDidStop?(anim, finished: flag)
	}
}
extension Transition : CAAnimationDelegate{

	func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {

		print(#function)
		animatingCtr?.view.isUserInteractionEnabled = true
		if isPresented {
			animatingCtr?.didFinishPresent(flag)
		}
		print("animationDidStop")
		if finishingDismiss {
			print("--->finishingDismiss")
			animatingCtr?.dismiss(animated: false, completion: nil)
		}else{
			if transitingViewGravity != nil {
				transitingView?.layer.contentsGravity = transitingViewGravity!
			}
		}
		transitingViewGravity = nil
		forceTransitionContextCompleteTransition()

	}
}

