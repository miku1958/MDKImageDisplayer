//
//  Transition.swift
//  MDKImageCollection
//
//  Created by mikun on 2018/7/25.
//  Copyright © 2018 mdk. All rights reserved.
//




open class MDKImageTransition: NSObject{
	static private weak var instance:MDKImageTransition?
	class func global() -> MDKImageTransition {
		var strongInstance = instance
		if strongInstance == nil {
			strongInstance = MDKImageTransition()
			instance = strongInstance
		}
		return strongInstance!
	}
	
	var isInTransition:Bool = false
	var  isPresenting:Bool? = true
	static let duration:TimeInterval = 0.25
	@objc public var ImageCornerRadius:CGFloat = 0
	
	weak var transitingView:UIView?
	var transitingViewGravity:String?
	
	
	weak var sourceCtr:UIViewController?
	weak var animatingCtr:MDKImageDisplayController?

	@objc public var sourceScreenInset:UIEdgeInsets = UIEdgeInsets()
	
	static let syncQueue = DispatchQueue(label: "MDKImageFlushQueue",attributes: [])

	private static let lock:DispatchSemaphore = DispatchSemaphore(value: 1)
	static func synchronized(_ close:(()->())) -> () {
		MDKImageTransition.lock.wait()
		defer { MDKImageTransition.lock.signal() }
		close()
	}


	weak var _transitionContext:UIViewControllerContextTransitioning?
	func forceTransitionContextCompleteTransition() -> () {
		_transitionContext?.completeTransition(true)
		transitingView?.layer.mask = nil
		animatingCtr?.view.isUserInteractionEnabled = true
		isPresenting = nil
		isInTransition = false
	}
	

	var beginViewMap:NSHashTable<UIView> = NSHashTable()
	var beginSourceFrame:CGRect?

	var dismissViewMap:NSHashTable<UIView> = NSHashTable()
	var dismissTargetFrame:CGRect?


//MARK:	dismiss动画控制的属性
	///dismiss进度
	var process:CGFloat?{
		didSet{
			
			if var process = process{
				process = max(0, min(1, process))
				if let transitingView = transitingView {
					transitingView.layer.speed = 0.0;
					transitingView.layer.timeOffset = CFTimeInterval(process) * MDKImageTransition.duration
				}
			}
		}
	}

	///layer动画的目标位置
	var animationTargetPosition:CGPoint?

	///是否在收尾dismiss/cancel动画
	var finishingDismiss:Bool = false

	///回滚view的transform初始值
	var rollbackTransformT:CGPoint = CGPoint()
	///收尾动画的启动offset
	var commitLayerBeginOffset:TimeInterval = 0
	///收尾动画的帧间距
	var dismissingTimeInterval:TimeInterval = 0
	
}
//MARK:	dismiss动画控制的方法
extension MDKImageTransition{
	func dismiss(viewController : MDKImageDisplayController) {
		
		
		animatingCtr = viewController

		didViewAnimation(to: nil, from: viewController.view)
//		if (animatingCtr?.isFrom3DTouch ?? false) , let layer = transitingView?.layer {//3d touch打开后dismiss的动画无效
//			layer.beginTime = CACurrentMediaTime()
//		}
		transitingView?.layer.masksToBounds = false
	}

	
	func controlTransitionView(position:CGPoint) -> () {
		
		
		
		guard let transitingView = transitingView, let targetPosition = animationTargetPosition else { return }
		
		let sourcePosition = transitingView.layer.position
		
		let ratio = CGFloat(transitingView.layer.timeOffset / MDKImageTransition.duration)
		let currentPosition = CGPoint(x: (sourcePosition.x - targetPosition.x) * ratio , y: (sourcePosition.y - targetPosition.y) * ratio)

		
		//fix m11 和 m22过大时滑动太快
		var positionXRatio = transitingView.layer.transform.m11
		if positionXRatio>1 {
			positionXRatio *= positionXRatio
		}else{
			positionXRatio = 1
		}
		
		var positionYRatio = transitingView.layer.transform.m22
		if positionYRatio>1 {
			positionYRatio *= positionYRatio
		}else{
			positionYRatio = 1
		}
		
		transitingView.transform.tx = position.x + (currentPosition.x/positionXRatio)
		transitingView.transform.ty = position.y + (currentPosition.y/positionYRatio)

	}
	
	func cancelDismiss() {
		
		
		guard let view = transitingView else { return }
		if finishingDismiss { return }
		animatingCtr?.view.isUserInteractionEnabled = false
		finishingDismiss = true
		rollbackTransformT = CGPoint(x: view.transform.tx, y: view.transform.ty)
		commitLayerBeginOffset = view.layer.timeOffset
		dismissingTimeInterval = (commitLayerBeginOffset)/(MDKImageTransition.duration*60)
		commitLayerAnimation(view ,rollback: true)
	}
	
	func commitDismiss() {
		
		
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
		commitLayerBeginOffset = view.layer.timeOffset
		dismissingTimeInterval = (MDKImageTransition.duration-commitLayerBeginOffset)/(MDKImageTransition.duration*60)
		commitLayerAnimation(view ,rollback: false)
	}
	func commitLayerAnimation(_ view:UIView , rollback:Bool){
		
		
		let layer = view.layer
		var timeOffset = layer.timeOffset
		if dismissingTimeInterval == 0 {
			dismissingTimeInterval = 0.000000001
		}
		rollback ? (timeOffset -= dismissingTimeInterval) : (timeOffset += dismissingTimeInterval)
		if rollback ? (timeOffset < 0) : (timeOffset > MDKImageTransition.duration) {
			if rollback{
				layer.removeAllAnimations()
				layer.timeOffset = 0
				forceTransitionContextCompleteTransition()
				
			}else if let animKey = layer.animationKeys()?.first , let anim = layer.animation(forKey: animKey){
				animationDidStop(anim, finished: true)
				
			}
			view.layer.speed = 1
			view.layer.beginTime = 0
			view.layer.timeOffset = 0
			view.transform.tx = 0
			view.transform.ty = 0
			finishingDismiss = false
			animatingCtr?.view.isUserInteractionEnabled = true
			return
		}
		
		var reduce:CGFloat = 0
		if rollback {
			if commitLayerBeginOffset == 0{
				reduce = 0
			}else{
				reduce = CGFloat(timeOffset / commitLayerBeginOffset)
			}
		}else{
			if MDKImageTransition.duration == commitLayerBeginOffset{
				reduce = 0
			}else{
				reduce = CGFloat((MDKImageTransition.duration - timeOffset) / (MDKImageTransition.duration - commitLayerBeginOffset))
			}
		}
		
		view.transform.tx = rollbackTransformT.x * reduce
		view.transform.ty = rollbackTransformT.y * reduce
		
		layer.timeOffset = min(max(timeOffset, 0), MDKImageTransition.duration)
		
		DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(1/60.0)) {
			self.commitLayerAnimation(view, rollback: rollback)
		}
	}
}
extension MDKImageTransition : UIViewControllerTransitioningDelegate{
	public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
		return TransitionController(presentedViewController: presented, presenting: presenting)
	}
	public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		self.isPresenting = true
		return self
	}

	public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		self.isPresenting = false
		return self
	}
}

extension MDKImageTransition :  UIViewControllerAnimatedTransitioning{

	public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
		return MDKImageTransition.duration
	}

	public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
		
		
		finishingDismiss = false
		_transitionContext = transitionContext
		if let isPresented = isPresenting {
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
		}else{
			forceTransitionContextCompleteTransition()
		}
	}

	func didViewAnimation(to:UIView?,from:UIView?) -> () {
		
		

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

		var targetView:UIView?
		var sourceView:UIView?
		let sourceFrame:CGRect? = isPresent ? beginSourceFrame : dismissTargetFrame
		var beginTransitionView:UIView? = beginViewMap.anyObject

		var hasViewPair:Bool = false
		var keyWinFrame = MDKKeywindow.frame
		keyWinFrame.origin.x += sourceScreenInset.left
		keyWinFrame.origin.y += sourceScreenInset.top
		keyWinFrame.size.width -= sourceScreenInset.left+sourceScreenInset.right
		keyWinFrame.size.height -= sourceScreenInset.top+sourceScreenInset.bottom
		assert(keyWinFrame.size.width > 0, "sourceScreenInset.left or sourceScreenInset.right is wrong")
		assert(keyWinFrame.size.height > 0, "sourceScreenInset.top or sourceScreenInset.bottom is wrong")

		var enumerator = dismissViewMap.objectEnumerator()
		if dismissViewMap.count == 0 {
			enumerator = beginViewMap.objectEnumerator()
		}

		while let view = enumerator.nextObject() as? UIView {
			if containVIew.contain(subview: view) {
				targetView = view
				if view == beginTransitionView{
					beginTransitionView = nil
				}
			}else if let frame = view.superview?.convert(view.frame, to: MDKKeywindow) , keyWinFrame.intersects(frame){
				sourceView = view
			}

			if targetView != nil,sourceView != nil{
				break
			}
		}

		if let targetView = targetView{
			if let sourceView = sourceView {
				hasViewPair = pairAnimationViews(targetView: targetView, sourceView: sourceView, sourceFrameToKeyWin: nil, isPresent: isPresent)
			}else if let sourceFrame = sourceFrame{
				hasViewPair = pairAnimationViews(targetView: targetView, sourceView: nil, sourceFrameToKeyWin: sourceFrame, isPresent: isPresent)
			}
		}

		if !hasViewPair , let targetView = targetView{
			if let sourceView = beginTransitionView{
				hasViewPair = pairAnimationViews(targetView: targetView, sourceView: sourceView, sourceFrameToKeyWin: nil, isPresent: isPresent)
			}else if let sourceFrame = sourceFrame{
				hasViewPair = pairAnimationViews(targetView: targetView, sourceView: nil, sourceFrameToKeyWin: sourceFrame, isPresent: isPresent)
			}
		}
		if !hasViewPair {
			if isPresent {
				targetView?.alpha = 0
			}

			animatingCtr?.view.isUserInteractionEnabled = false
			UIView.animate(withDuration: MDKImageTransition.duration, animations: {
				targetView?.alpha = isPresent ? 1 : 0
			}) { (finish) in
				self.forceTransitionContextCompleteTransition()
				self.animatingCtr?.view.isUserInteractionEnabled = true
				if !isPresent{
					self.animatingCtr?.dismiss(animated: false, completion: nil)
				}
			}
		}
	}

	func pairAnimationViews(targetView view:UIView , sourceView:UIView?, sourceFrameToKeyWin:CGRect? , isPresent:Bool) -> Bool {
		if let imageView = view as? UIImageView , imageView.image == nil {
			return false
		}
		var frameToKeyWin = CGRect()
		if let sourceFrameToKeyWin = sourceFrameToKeyWin{
			frameToKeyWin = sourceFrameToKeyWin
		}else if let sourceFrameOri = sourceView?.frame ,let soucreSuperView = sourceView?.superview{
			frameToKeyWin = soucreSuperView.convert(sourceFrameOri, to: MDKKeywindow)
		}


		animatingCtr?.view.layoutIfNeeded()

		let frameMaskToKeyWin = getMaskFrame(frameToKeyWin: frameToKeyWin, fromView: view)
		let sourceFrameToTarget = MDKKeywindow.convert(frameToKeyWin, to: view.superview)
		let maskFrameToTarget = MDKKeywindow.convert(frameMaskToKeyWin, to: view.superview)
		updateLayer(from: view, sourceFrame: sourceFrameToTarget ,maskFrame:maskFrameToTarget, isPresent: isPresent)
		
		return true
	}

	func getMaskFrame(frameToKeyWin:CGRect ,fromView view:UIView) -> (CGRect) {
		var maskFrame = frameToKeyWin


		if frameToKeyWin.origin.x < sourceScreenInset.left {
			let insert = sourceScreenInset.left-frameToKeyWin.origin.x
			
			maskFrame.size.width -= insert
			maskFrame.origin.x += insert/view.layer.transform.m11
		}

		if frameToKeyWin.origin.y < sourceScreenInset.top{
			let insert = sourceScreenInset.top-frameToKeyWin.origin.y
			
			maskFrame.size.height -= insert
			maskFrame.origin.y += insert/view.layer.transform.m22
		}

		if frameToKeyWin.maxX > MDKKeywindow.frame.width - sourceScreenInset.right{
			let insert = MDKKeywindow.frame.width - sourceScreenInset.right-frameToKeyWin.maxX
			maskFrame.size.width -= insert
		}
		if frameToKeyWin.maxY > MDKKeywindow.frame.height - sourceScreenInset.bottom{
			let insert = MDKKeywindow.frame.height - sourceScreenInset.bottom-frameToKeyWin.maxY
			maskFrame.size.height -= insert
		}
		return maskFrame;
	}

	func updateLayer(from view:UIView , sourceFrame:CGRect , maskFrame:CGRect , isPresent:Bool) -> () {
		isInTransition = true
		
		
		if finishingDismiss {
			forceTransitionContextCompleteTransition()
			return
		}

		if sourceFrame != maskFrame || true{//等调试好再说

			let mask = CALayer()
			mask.backgroundColor = UIColor.white.cgColor

			let sourcebounds = CGRect(origin: CGPoint(), size: CGSize(width: maskFrame.width/view.layer.transform.m11, height: maskFrame.height/view.layer.transform.m22));
			let viewbounds = view.layer.bounds
			mask.bounds = sourcebounds;
			mask.anchorPoint.x = 0
			mask.anchorPoint.y = 0
			
			mask.position = maskFrame.origin


			let maskBoundsAnim = CABasicAnimation()
			maskBoundsAnim.keyPath = "bounds"
			isPresent ? (maskBoundsAnim.toValue = viewbounds) : (maskBoundsAnim.fromValue = viewbounds)


			let maskPositionAnim = CABasicAnimation()
			maskPositionAnim.keyPath = "position"

			isPresent ? (maskPositionAnim.toValue = CGPoint()) : (maskPositionAnim.fromValue = CGPoint())


			let maskGroup = CAAnimationGroup()
			maskGroup.animations = [maskBoundsAnim,maskPositionAnim]

			maskGroup.duration = MDKImageTransition.duration
			maskGroup.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)


			maskGroup.isRemovedOnCompletion = false;
			maskGroup.fillMode = kCAFillModeForwards;

			mask.add(maskGroup, forKey: "animateTransition")
			view.layer.mask = mask
//			view.layer.addSublayer(mask)

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



		group.duration = MDKImageTransition.duration
		group.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)


		group.isRemovedOnCompletion = false;
		group.fillMode = kCAFillModeForwards;
		let delegate = AnimationProxy()
		delegate.delegate = self
		group.delegate = delegate



		if !isPresent ,let superlayer = view.layer.superlayer{//3d touch打开后dismiss的动画无效
			view.layer.beginTime = superlayer.convertTime(CACurrentMediaTime(), from: nil)
			group.beginTime = view.layer.convertTime(CACurrentMediaTime(), from: nil)
		}
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
extension MDKImageTransition : CAAnimationDelegate{

	public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {

		
		
		animatingCtr?.view.isUserInteractionEnabled = true
		if let isPresented = isPresenting, isPresented {
			animatingCtr?.didFinishPresent(flag)
		}
		
		if finishingDismiss {
			
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

