//
//  MDKImageDisplayController.swift
//  MDKImageCollection
//
//  Created by mikun on 2018/7/14.
//  Copyright © 2018 mdk. All rights reserved.
//

import UIKit

//TODO:	做读取时占位提示圈


class MDKImageDisplayController: UIViewController {

	static private weak var instance:MDKImageDisplayController?
	
	class func current() -> MDKImageDisplayController? {
		return instance
	}
	
	private var largeClose:OptionImgRtStringClose?
	convenience init(photoCount:Int ,largeClose:OptionImgRtStringClose?) {
		
		self.init()
		
		photoList.count = photoCount
		self.largeClose = largeClose
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		initself()
	}
	

	private init() {
		super.init(nibName: nil, bundle: nil)
		initself()
	}
	
	func initself() -> () {
		MDKImageDisplayController.instance = self
		modalPresentationStyle = .custom;
		transitioningDelegate = transition
		
		collectionView.delegate = self
		collectionView.dataSource = self
		collectionView.MDKRegister(Cell: DisplayCell.self)
		
		
		collectionView.addGestureRecognizer(dismissPan)
		dismissPan.addTarget(self, action: #selector(dismissPanFunc(pan:)))
		dismissPan.delegate = self
		
		collectionView.addGestureRecognizer(toolbarPan)
		toolbarPan.addTarget(self, action: #selector(toolbarPanFunc(pan:)))
		toolbarPan.delegate = self
		
		
		dismissTap.addTarget(self, action: #selector(tapDismissFunc(tap:)))
		collectionView.addGestureRecognizer(dismissTap)
		
		dismissTap.numberOfTapsRequired = 1
		dismissTap.numberOfTouchesRequired = 1
		dismissTap.delegate = self
		dismissTap.require(toFail: dismissPan)
		dismissTap.require(toFail: zoomTap)
		
		zoomTap.addTarget(self, action: #selector(tapZoomFunc(tap:)))
		collectionView.addGestureRecognizer(zoomTap)
		
		
		zoomTap.delegate = self
		zoomTap.require(toFail: dismissPan)
		
		
		longPress.addTarget(self, action: #selector(longPressFunc(longPress:)))
		collectionView.addGestureRecognizer(longPress)
		longPress.delegate = self
		longPress.require(toFail: zoomTap)
		
		toolbar.addFinalAction { [weak self] in
			self?.dismissToolbar(finish: {})
		}
		savePhotoResult = { result in
			switch result {
			case .success:
				UIAlertController(title: "保存成功", message: nil, preferredStyle: .alert).MDKAdd(Cancel: { (_) in
					
				}, title: "返回").MDKQuickPresented()
			case .fail(.denied):
				fallthrough
			case .fail(.restricted):
				UIAlertController(title: "请允许系统访问图片", message: nil, preferredStyle: .alert).MDKAdd(Cancel: { (_) in
					
				}, title: "返回").MDKQuickPresented()
			case let .fail(.saveingFail(error)):
				UIAlertController(title: "保存失败", message: error.localizedDescription, preferredStyle: .alert).MDKAdd(Cancel: { (_) in
					
				}, title: "返回").MDKQuickPresented()
			}
		}
	}

	let blurView = UIVisualEffectView(frame: MDKKeywindow.bounds)
	
	var collectionView:UICollectionView = {
		let flow = UICollectionViewFlowLayout()
		flow.minimumLineSpacing = 0
		flow.minimumInteritemSpacing = 0
		flow.itemSize = MDKKeywindow.frame.size
		flow.scrollDirection = .horizontal
		let collection = UICollectionView(frame: CGRect(x: 0, y: 0, width: MDKScreenWidth-1, height: MDKScreenHeight-1), collectionViewLayout: flow)//防止3D TOUCH出来的照片尺寸一样导致没有滚动到目标位置
		collection.backgroundColor = nil
		collection.isPagingEnabled = true
		return collection
	}()
	
	var toolbar:toolbarView = toolbarView()

	var beginIndex:Int = 0
	func setDisplayIndex(_ displayIndex:Int) -> () {
		beginIndex = displayIndex
		collectionView.reloadData()
		let displayIndexPath = IndexPath(item: displayIndex, section: 0)
		collectionView.scrollToItem(at: displayIndexPath, at: .left, animated: false)
		collectionViewIsScrolling = false

		loadPhoto(displayIndex)
		collectionView.layoutIfNeeded()
		if sourceTransitionIDPrefix != nil {
			beginTransitionID = "MDK\(sourceTransitionIDPrefix!)\(displayIndex)"
		}

	}
	var displayIndex:Int{
		guard
			let cell = collectionView.visibleCells.first as? DisplayCell,
			let indexPath = collectionView.indexPath(for: cell)
			else { return 0}
		return indexPath.item
	}




	fileprivate var photoList:lazyArray<photoNode> = lazyArray(0, {(index)->(photoNode) in
		var photo = photoNode()
		photo.index = index
		return photo
	})
	var preloadCloses:[Int:Bool] = [:]

	



	var isFailToTryPrevious:Bool?
	var isFailToTryNext:Bool?

	var isPreloadingPrevious:Bool = false
	var isFinishingPreloadPrevious:Bool = false


	public var isFrom3DTouch:Bool = false

	//MARK:	手势相关
	let dismissPan:UIPanGestureRecognizer = UIPanGestureRecognizer()

	let toolbarPan:UIPanGestureRecognizer = UIPanGestureRecognizer()

	let longPress = UILongPressGestureRecognizer()

	let dismissTap:UITapGestureRecognizer = UITapGestureRecognizer()
	let zoomTap:DoubleTapThanPanGesture = DoubleTapThanPanGesture()
	var tapCount:Int = 0


	var toolbarIsOpening:Bool = false
	var toolbarIsFinishOpen:Bool = false
	
	var longPressIsActive:Bool = false
	
	

	var savePhotoResult:SavePhotoClose?

	var collectionViewIsScrolling :Bool = false
	
	let transition = Transition.global()

	///transition 动画是否做完
	var didFinishPresentTransitionAnimation:Bool = false
	var shouldResetCellImage:Bool = false
	///transition 动画做做完后需不需要切换到大图(防止layer动画的时候切换大图会导致视图大小出错)
	var needSwitchToLarge:Bool = true

	
	var _animator:AnyObject?
	@available(iOS 10.0, *)
	func animator() -> UIViewPropertyAnimator? {
		return _animator as? UIViewPropertyAnimator
	}

	
	///用来第一次显示的时候滚动到当前要显示的cell
	var firstResetPosition :Bool = false
	///记录第一次显示的cell的transition ID
	var beginTransitionID:String = ""
	
	///transition ID前缀
	public var sourceTransitionIDPrefix:String?
	
//MARK:	供外部使用的属性
	@objc public  var displayIndexWillChange:IndexClose?
	@objc public  var willDismiss:IndexClose?
	@objc public  var didDismiss:IndexClose?
	///供外部获取当前displayCtr的显示信息
	@objc public var displayingOption:DisplayingOption{
		let option = DisplayingOption()
		let pNode = photoList[displayIndex - photoList.negativeCount]
		if pNode.isDequeueFromIdentifier,let identifier = pNode.identifier{
			option.identifier = identifier
		}else{
			option.index = displayIndex
		}
		return option
	}
	public var QRCodeHandler:QRCodeHandlerClose = { QRCodes,touchPoint in
		if QRCodes.count == 1{
			UIApplication.shared.openURL(MDKURL(QRCodes.first!.key))
		}else{
			var inPoint = false
			if var touchPoint = touchPoint{
				for (message,rect) in QRCodes {
					
					if rect.contains(touchPoint){
						inPoint = true
						UIApplication.shared.openURL(MDKURL(message))
						break
					}
				}
			}
			if !inPoint{
				//弹个选择框给用户
				let alert = UIAlertController(title: "检查到多个二维码", message: "请选择", preferredStyle: .actionSheet)
				for (message,_) in QRCodes {
					alert.MDKAdd(Default: { (action) in
						UIApplication.shared.openURL(MDKURL(message))
					}, title: message)
				}
				alert.MDKAdd(Cancel: { (action) in
					
				}, title: "取消")
				alert.MDKQuickPresented()
			}
		}
	}
}



//MARK:	view function
extension MDKImageDisplayController{
	
	override func viewDidLoad() {
		super.viewDidLoad()
		view.addSubview(blurView)
		view.addSubview(collectionView)
	}
	
	override func viewDidLayoutSubviews() {
		let collFrame = collectionView.frame
		
		if collFrame.size != view.bounds.size {
			collectionView.frame = view.bounds
			blurView.frame = collectionView.frame
			if !firstResetPosition{
				firstResetPosition = true
				
				self.collectionView.scrollToItem(at: IndexPath(item: beginIndex + self.photoList.negativeCount, section: 0), at: .left, animated: false)
				self.collectionViewIsScrolling = false
			}
			
		}
		
	}
	
	override func viewWillAppear(_ animated: Bool) {
		
		UIView.animate(withDuration: Transition.duration) {
			self.blurView.effect = UIBlurEffect(style: .dark)
		}
		
		dismissToolbar { }
	}
	override func viewDidAppear(_ animated: Bool) {
		if didFinishPresentTransitionAnimation && isFrom3DTouch {
			didFinishPresent(true)
		}
		didFinishPresentTransitionAnimation = true
	}
	func didFinishPresent(_ animated: Bool) -> () {
		didFinishPresentTransitionAnimation = true
		collectionViewIsScrolling = false
		if needSwitchToLarge , displayIndex-photoList.negativeCount == beginIndex, let cell = collectionView.visibleCells.first , let indexPath = collectionView.indexPath(for: cell){
			collectionView(collectionView, willDisplay: cell, forItemAt: indexPath)
		}
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		if let cell = collectionView.cellForItem(at: IndexPath(item: displayIndex, section: 0)){
			Transition.antiRegistr(view: cell)
		}
		if #available(iOS 10.0, *) {
			let anim = UIViewPropertyAnimator(duration: Transition.duration, curve: .easeInOut) {
				self.blurView.effect = nil
			}
			anim.startAnimation()
			_animator = anim
			anim.addCompletion { (position) in
				switch position {
				case .start , .end:
					self._animator = nil
				default:break
				}
			}
		} else {
			UIView.animate(withDuration: 0.15) {
				self.blurView.effect = nil
			}
		}
		
	}
	
	
}

//MARK:	UICollectionViewDelegate,UICollectionViewDataSource
extension MDKImageDisplayController: UICollectionViewDelegateFlowLayout,UICollectionViewDataSource{
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return photoList.count + photoList.negativeCount
	}

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(DisplayCell.self), for: indexPath) as! DisplayCell
		if cell.scrollDelegate == nil {
			cell.scrollDelegate = self
			if let pinch = cell.contentScroll.pinchGestureRecognizer{
				longPress.require(toFail:pinch)
			}

		}
		return cell
	}
	func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {

		let item = indexPath.item
		let displayIndex = item - photoList.negativeCount

		displayIndexWillChange?(displayIndex)
		if let cell = cell as? DisplayCell {
			if shouldResetCellImage{
				cell.imageView.image = nil
			}
			cell.imageView.alpha = 1
			cell.imageView.layer.mask = nil
			cell.isScrolling = false


			if let identifier = photoList[item - photoList.negativeCount].identifier{
				Transition.register(view: cell.imageView, for: identifier)
			}else{
				var sourceID = ""

				if beginTransitionID.count > 0, photoList[item - photoList.negativeCount].isDequeueFromIdentifier {
					sourceID = beginTransitionID
				}else if sourceTransitionIDPrefix != nil{
					sourceID = "MDK\(sourceTransitionIDPrefix!)\(displayIndex)"
				}
				if sourceID.count > 0{
					Transition.register(view: cell.imageView, for: sourceID)
				}
			}



			let option = CloseOption()
			if displayIndex>0 {
				option.lastIdentifier = photoList[displayIndex-1].identifier
			}else if displayIndex<0{
				option.lastIdentifier = photoList[displayIndex+1].identifier
			}
			option.index = displayIndex
			option.needQuality = .large
			option.displayCtr = self
			var hasLargePhoto = false
			var largeIsFromNet = false//修正加载大图太快会闪一下
			let _ = largeClose?(option){[weak self] photo in
				if let _self = self , ( !largeIsFromNet ||  _self.didFinishPresentTransitionAnimation){

					if displayIndex == 0{
						_self.needSwitchToLarge = false
					}
					hasLargePhoto = true
					guard let photo = photo else {return}
					_self.photoList[displayIndex].photoQuality = .large
					_self.photoList[displayIndex].photo = photo
					DispatchQueue.main.async {
						if let cell = _self.collectionView.cellForItem(at: IndexPath(item: item, section: 0)) as? DisplayCell {
							
							_self.updateCell(cell, image: photo, displayIndex: displayIndex, isThumbnail: false)
							_self.shouldResetCellImage = true

						}
					}
				}
			}
			largeIsFromNet = true


			if !hasLargePhoto {
				option.needQuality = .thumbnail

				let _ = self.largeClose?(option){[weak self] photo  in
					DispatchQueue.main.async {
						guard let _self = self else {return}
						if _self.photoList[displayIndex].photoQuality == .thumbnail{
							_self.photoList[displayIndex].photo = photo
							if let cell = _self.collectionView.cellForItem(at: IndexPath(item: item, section: 0)) as? DisplayCell{
								_self.updateCell(cell, image: photo, displayIndex: displayIndex, isThumbnail: true)
							}
						}
					}
				}
			}



		}
		Transition.syncQueue.async {
			DispatchQueue.main.sync {
				Transition.synchronized({
					if !self.isFinishingPreloadPrevious{
						self.loadPhoto(displayIndex - 1)
					}
					self.loadPhoto(displayIndex + 1)
				})
			}
		}


	}

	func updateCell(_ cell:DisplayCell , image:UIImage? , displayIndex:Int , isThumbnail:Bool) -> () {
		if transition.isInTransition {
			return
		}
		photoList[displayIndex].updatingCell = true
		cell.setPhoto(image, isThumbnail: isThumbnail)
		if let zoom = photoList[displayIndex].browsingScale{
			cell.contentScroll.zoomScale = zoom
		}
		if let offset = photoList[displayIndex].browsingOffset{
			cell.contentScroll.contentOffset = offset
		}

		photoList[displayIndex].updatingCell = false
	}
	func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		if didFinishPresentTransitionAnimation {
			 shouldResetCellImage = true
		}
		if let cell = cell as? DisplayCell {
			cell.isScrolling = false
			Transition.antiRegistr(view: cell.imageView)
		}

	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		return MDKKeywindow.bounds.size
	}
	func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
		collectionViewIsScrolling = true
	}
	func scrollViewDidZoom(_ scrollView: UIScrollView) {
		if let cell = collectionView.visibleCells.first as? DisplayCell , scrollView == cell.contentScroll ,!photoList[displayIndex - photoList.negativeCount].updatingCell{
			photoList[displayIndex - photoList.negativeCount].browsingScale = scrollView.zoomScale
		}
	}
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		if scrollView.panGestureRecognizer.translation(in: nil).x > 1 || scrollView.panGestureRecognizer.translation(in: nil).y > 1 {
			resetTapCount()
		}

		if let cell = collectionView.visibleCells.first as? DisplayCell , scrollView == cell.contentScroll {
			if !photoList[displayIndex - photoList.negativeCount].updatingCell{
				photoList[displayIndex - photoList.negativeCount].browsingOffset = scrollView.contentOffset
			}
			if toolbarIsOpening ,scrollView.panGestureRecognizer.velocity(in: scrollView).y > 0{
				dismissToolbar(finish: {})
			}
		}


		if scrollView == collectionView {
			collectionViewIsScrolling = true
		}
	}
	func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
		if !decelerate {
			scrollViewDidEndDecelerating(scrollView)
		}
	}
	func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		collectionViewIsScrolling = false
	}

	func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
		collectionViewIsScrolling = false
	}

}

//MARK:	baseFunction
extension MDKImageDisplayController{
	
	func dismissWithAnimation(all:Bool = false) -> () {
		if !all {
			if toolbarIsFinishOpen {
				dismissToolbar(finish: {})
				return
			}
			if toolbarIsOpening {
				return
			}
		}

		willDismiss?(displayIndex)
		self.dismiss(animated: true, completion: {
			self.didDismiss?(self.displayIndex)
		})
	}

	func loadPhoto(_ displayIndex:Int)->()  {
		let maxNegativeIndex = (-photoList.negativeCount) - 1;
		guard displayIndex >= maxNegativeIndex , displayIndex < photoList.count+1 else { return }
		let isTryingNext = displayIndex == photoList.count
		let isTryingPrevious = displayIndex == maxNegativeIndex
		if isTryingNext ,(isFailToTryNext ?? false ||
			photoList[displayIndex-1].identifier == nil){

			return
		}
		if isTryingPrevious , (isFailToTryPrevious ?? false ||
			photoList[displayIndex+1].identifier == nil){

			return
		}
		var inPreload = false
		if let _inPreload  = self.preloadCloses[displayIndex] {
			inPreload = _inPreload
		}
		guard !inPreload else { return }
		self.preloadCloses[displayIndex] = true

		let option = CloseOption()
		if displayIndex>0 {
			option.lastIdentifier = photoList[displayIndex-1].identifier
		}else if displayIndex<0{
			option.lastIdentifier = photoList[displayIndex+1].identifier
		}

		option.index = displayIndex
		option.needQuality = .large
		option.displayCtr = self
		var cachePhotoNode:photoNode?

		var hasLargePhoto:Bool = false
		var isFromInternet:Bool = false
		let identifier = largeClose?(option){[weak self] image  in
			hasLargePhoto = true
			let _isFromInternet = isFromInternet;
			MDKDispatch_main_async_safe {
				guard let _self = self else{return}

				var pNode = photoNode()
				if _self.photoList.checkIndex(displayIndex){
					pNode = _self.photoList[displayIndex]
				}
				pNode.photoQuality = .large
				pNode.photo = image
				pNode.index = displayIndex
				if isTryingNext , displayIndex == _self.photoList.count{
					cachePhotoNode = pNode
				}else if isTryingPrevious, displayIndex == (-_self.photoList.negativeCount) - 1{
					cachePhotoNode = pNode
				}else{
					_self.photoList[displayIndex] = pNode
				}
				if !_isFromInternet , !(_self.didFinishPresentTransitionAnimation && displayIndex == _self.beginIndex) ,
					let cell = _self.collectionView.cellForItem(at: IndexPath(item: displayIndex + _self.photoList.negativeCount, section: 0)) as? DisplayCell{
					_self.needSwitchToLarge = false
					_self.updateCell(cell, image: image, displayIndex: displayIndex, isThumbnail: false)
				}

			}
		}
		isFromInternet = true
		if identifier != nil {
			if isTryingNext {
				if photoList[displayIndex-1].identifier == identifier{
					return
				}
				self.photoList.count = max(self.photoList.count, displayIndex + 1)
				isFailToTryNext = false
				if cachePhotoNode != nil{
					self.photoList[displayIndex] = cachePhotoNode!
				}
				UIView.performWithoutAnimation {
					CATransaction.begin()
					CATransaction.setDisableActions(true)

					self.collectionView.insertItems(at: [IndexPath(item: displayIndex+self.photoList.negativeCount, section: 0)])

					CATransaction.commit()
				}


			}
			if isTryingPrevious {
				if photoList[displayIndex+1].identifier == identifier{
					return
				}
				photoList.negativeCount = (-displayIndex)
				if cachePhotoNode != nil{
					photoList[displayIndex] = cachePhotoNode!
				}
				isFailToTryPrevious = false
			}
			if identifier != nil {
				photoList[displayIndex].identifier = identifier
			}
			photoList[displayIndex].isDequeueFromIdentifier = true
			if (isTryingPrevious && !isPreloadingPrevious){
				isPreloadingPrevious = true

				var indexPs:[IndexPath] = [IndexPath(item: 0, section: 0)]
				for idx in 1..<10{
					self.loadPhoto(displayIndex-idx)
					if !self.isPreloadingPrevious {
						break
					}
					indexPs.append(IndexPath(item: 0, section: 0))
				}
				let addOffset = self.collectionView.frame.width * CGFloat(indexPs.count);
				let offsetX = self.collectionView.contentOffset.x + addOffset

				UIView.performWithoutAnimation {
					CATransaction.begin()
					CATransaction.setDisableActions(true)

					self.collectionView.insertItems(at: indexPs)
					self.collectionView.layoutIfNeeded()

					var translation = self.collectionView.panGestureRecognizer.translation(in: nil)
					if translation.x == 0{
						self.collectionView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: false)
					}else{
						translation.x -= addOffset
						self.collectionView.panGestureRecognizer.setTranslation(translation, in: nil)
					}

					self.collectionView.layoutIfNeeded()

					CATransaction.commit()
				}


				self.collectionViewIsScrolling = false
				for cell in self.collectionView.visibleCells as! [DisplayCell]{
					cell.isScrolling = false
				}

				self.isFinishingPreloadPrevious = true
				DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(0.1)) {
					self.isPreloadingPrevious = false
					self.isFinishingPreloadPrevious = false
				}
			}
		}else if isTryingNext{
			isFailToTryNext = true
			return
		}else if isTryingPrevious{
			isFailToTryPrevious = true
			isPreloadingPrevious = false
			return
		}

		if hasLargePhoto {
			return
		}
		option.needQuality = .thumbnail

		let _ = self.largeClose?(option){[weak self] image  in
			DispatchQueue.main.async {
				guard let _self = self else {return}
				if _self.photoList[displayIndex].photoQuality == .thumbnail{

					_self.photoList[displayIndex].photo = image
				}
			}
		}


	}
	
	func updatePhotoCount(_ count:Int) {
		var indexPaths:[IndexPath] = []
		for idx in photoList.count ..< count {
			indexPaths.append(IndexPath(item: idx, section: 0))
		}
		photoList.count = count
		UIView.performWithoutAnimation {
			CATransaction.begin()
			CATransaction.setDisableActions(true)

			self.collectionView.insertItems(at: indexPaths)

			CATransaction.commit()
		}
	}
	func displayToolbar(_ touchPoint:CGPoint? = nil) -> () {

		resetTapCount()

		guard
			let cell = collectionView.visibleCells.first as? DisplayCell,
			let indexPath = collectionView.indexPath(for: cell)
		else { return }

		toolbarIsOpening = true

		toolbar
		.removeAllAction()
		.addGroup()
			.addAction(title: "保存图片", action: { [weak self] in
				self?.savePhoto()
			})
		.addGroup()
			.addAction(title: "关闭图片", action: {[weak self] in
				self?.dismissWithAnimation(all: true)
			})
			.addAction(title: "取消", action: { //[weak self] in

			})

		let updateFrame = {
			UIView.animate(withDuration: Transition.duration, animations: {
				let photoBottom = max(-10, cell.frame.height - cell.imageView.superview!.convert(cell.imageView.frame, to: cell).maxY)
				if photoBottom<self.toolbar.frame.height{
					self.collectionView.frame.origin.y = 0-(self.toolbar.frame.height - photoBottom)
				}
				self.toolbar.frame.origin.y = self.view.frame.height - self.toolbar.frame.height
			}) { (_) in
				self.toolbarIsFinishOpen = true
				self.resetTapCount()
				
			}
		}

		DispatchQueue.global().async {
			self.photoList[indexPath.item - self.photoList.negativeCount].checkHasQRCode {
				DispatchQueue.main.async { [weak self] in
					if let _self = self , (_self.photoList[indexPath.item - _self.photoList.negativeCount].QRCode?.count ?? 0) > 0 {
						_self.toolbar.insertAction(title: "识别图中的二维码", action: {
							guard  let _self = self else {return}
							var convertPoint = touchPoint
							if convertPoint != nil{
								convertPoint = cell.imageView.convert(touchPoint!, from: cell)
								convertPoint!.x *= cell.imageView.image?.scale ?? 1
								convertPoint!.y *= cell.imageView.image?.scale ?? 1
							}
							_self.QRCodeHandler((_self.photoList[indexPath.item - _self.photoList.negativeCount].QRCode)!,convertPoint)
							}, atGroup: 0, at: 1)

						updateFrame()
					}
				}
			}
		}


		updateFrame()

		view.addSubview(toolbar)

		cell.makeScroll(stop: true)
		collectionView.isScrollEnabled = false

	}
	func dismissToolbar(finish:@escaping ()->()) -> () {
		resetTapCount()


		collectionView.isScrollEnabled = true
		UIView.animate(withDuration: Transition.duration, animations: {
			self.collectionView.frame.origin.y = 0
			self.toolbar.frame.origin.y = self.view.frame.height
		}) { (_) in
			if let cell = self.collectionView.visibleCells.first as? DisplayCell {
				cell.makeScroll(stop: false)
			}
			self.resetTapCount()
			self.toolbar.removeFromSuperview()
			self.toolbarIsOpening = false
			self.toolbarIsFinishOpen = false
			finish()
		}
	}
}

//MARK:	GestureFunction
extension MDKImageDisplayController{
	@objc func dismissPanFunc(pan:UIPanGestureRecognizer) ->(){
		let translation = pan.translation(in: nil)

		let progress = min(translation.y / collectionView.bounds.height,  0.5)  
		Transition.global().process = progress
		guard let cell = collectionView.visibleCells.first as? DisplayCell else{return}
		switch pan.state {
		case .began:
			cell.contentScroll.panGestureRecognizer.isEnabled = false
			viewWillDisappear(true)
			if #available(iOS 10.0, *) {
				animator()?.pauseAnimation()
			}
			Transition.global().dismiss(viewController: self)
		case .changed:
			Transition.global().process = progress
			if #available(iOS 10.0, *) {
				animator()?.fractionComplete = min(1, progress*1.5)
			}
			Transition.global().controlTransitionView(position: translation)
		default:
			cell.contentScroll.panGestureRecognizer.isEnabled = true
			
			if progress + pan.velocity(in: nil).y / collectionView.bounds.height > 0.3 , translation.y > collectionView.bounds.height/4 {
				Transition.global().commitDismiss()
				didDismiss?(displayIndex)
				if #available(iOS 10.0, *) {
					if let animator = animator(){
						animator.continueAnimation(withTimingParameters: UICubicTimingParameters(animationCurve: .easeIn), durationFactor: 1/(1-animator.fractionComplete))
					}
				}
			} else {
				Transition.global().cancelDismiss()
				didDismiss?(displayIndex)
				if #available(iOS 10.0, *) {
					animator()?.isReversed = true
					if let animator = animator(){
						animator.continueAnimation(withTimingParameters: UICubicTimingParameters(animationCurve: .easeIn), durationFactor: 1/animator.fractionComplete)
					}
				}
			}
		}
	}
	@objc func toolbarPanFunc(pan:UIPanGestureRecognizer) ->(){


		switch pan.state {
		case .began:
			if toolbarIsOpening{
				let velocity = pan.velocity(in: nil)
				if velocity.y>fabs(velocity.x) {
					dismissToolbar(finish: {})
				}
			}else{
				displayToolbar()
			}
		default:break
		}
	}

	@objc func longPressFunc(longPress:UILongPressGestureRecognizer) -> (){
		switch longPress.state {
		case .began:
			longPressIsActive = true
			displayToolbar(longPress.location(in: nil))
		case .ended:
			DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(0.1)) {
				self.longPressIsActive = false
			}
		default: break
		}
	}
	func resetTapCount() {
		tapCount = 0
	}

	@objc fileprivate func tapDismissFunc(tap:UITapGestureRecognizer){
		if zoomTap.state == .failed && !longPressIsActive{
			tapCount = 1
			self.dismissWithAnimation()
		}
	}

	@objc fileprivate func tapZoomFunc(tap:DoubleTapThanPanGesture){

		if tap.didMoving {
			doubleTapThanPanFunc(pan: tap)
		}else{
			if toolbarIsFinishOpen {
				dismissToolbar(finish: {
					self.resetTapCount()
				})
			}else if !toolbarIsOpening{
				(collectionView.visibleCells.first as? DisplayCell)?.scale(finish: {
					self.resetTapCount()
				})
			}
		}

	}

	@objc func doubleTapThanPanFunc(pan:DoubleTapThanPanGesture){
		guard let cell = self.collectionView.visibleCells.first as? DisplayCell else { return }
		if collectionViewIsScrolling {
			cell.isScrolling = false
			return
		}
		if toolbarIsOpening || toolbarIsFinishOpen {
			return
		}
		switch pan.state {
		case .began:
			break
		case .ended:
			cell.isScrolling = false
		default:
			break
		}
		let translation = pan.translation(in: pan.view)

		var scale:CGFloat = 0

		scale = -translation.y
		scale /= 100
		if let contentScroll = (collectionView.visibleCells.first as? DisplayCell)?.contentScroll{
			contentScroll.setZoomScale(contentScroll.zoomScale + scale, animated: false)
		}

		pan.setTranslation(CGPoint(), in: pan.view)
	}
}

//MARK:	UIGestureRecognizerDelegate
extension MDKImageDisplayController:UIGestureRecognizerDelegate {
	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {

		if gestureRecognizer == collectionView.panGestureRecognizer || otherGestureRecognizer == collectionView.panGestureRecognizer {
			return false
		}

		return true
	}
	func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {

		if gestureRecognizer == dismissTap {
			guard let cell = self.collectionView.visibleCells.first as? DisplayCell else {return true}

			return (!collectionViewIsScrolling && !cell.isScrolling) || toolbarIsFinishOpen
		}
		if gestureRecognizer.isKind(of: UILongPressGestureRecognizer.self) {
			if toolbarIsOpening {
				return false
			}
			return true
		}

		guard
			let pan = gestureRecognizer as? UIPanGestureRecognizer,
			let scroll = (collectionView.visibleCells.first as? DisplayCell)?.contentScroll
		else { return true}
		if pan == dismissPan {
			if tapCount != 0{
				return false
			}
			if toolbarIsOpening {
				return false
			}
			if fabs(scroll.contentOffset.y + scroll.contentInset.top) < 1 {
				let velocity = pan.velocity(in: nil)
				return  velocity.y>fabs(velocity.x)
			}

			return false
		}
		if pan == toolbarPan {
			if tapCount != 0{
				return false
			}
			if toolbarIsOpening {
				return true
			}
			if fabs(scroll.contentOffset.y + scroll.frame.height - scroll.contentInset.top - scroll.contentSize.height) < 1 {
				let velocity = pan.velocity(in: nil)
				return velocity.y<0 && fabs(velocity.y)>fabs(velocity.x)
			}
			return false
		}


		return true
	}
}


import Photos
//MARK:	savePhoto
extension MDKImageDisplayController{

	func savePhoto() -> () {
		let author = PHPhotoLibrary.authorizationStatus();
		if author == .restricted {
			//没有权限
			savePhotoResult?(.fail(.restricted))
			return
		}

		if author == .denied {
			//没有权限
			savePhotoResult?(.fail(.denied))
			return
		}
		let displayIndex = self.displayIndex - photoList.negativeCount
		let option = CloseOption()
		if displayIndex>0 {
			option.lastIdentifier = photoList[displayIndex-1].identifier
		}else if displayIndex<0{
			option.lastIdentifier = photoList[displayIndex+1].identifier
		}
		option.index = displayIndex
		option.needQuality = .large
		option.displayCtr = self
		let identifier = largeClose?(option){[weak self] photo in
			guard let photo = photo , let _self = self else {return}
			_self.photoList[displayIndex].photoQuality = .original

			_self.photoList[displayIndex].photo = photo
			UIImageWriteToSavedPhotosAlbum(photo, _self, #selector(_self.image(_:didFinishSavingWithError:contextInfo:)), nil)
		}
		if identifier != nil {
			photoList[displayIndex].identifier = identifier
		}
	}

	@objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
		savePhotoResult?(error == nil ? .success : .fail(.saveingFail(error!)))
	}
}

//系统功能
extension MDKImageDisplayController{
	override var supportedInterfaceOrientations: UIInterfaceOrientationMask{
		return .all
	}

	@available(iOS 9.0, *)
	override var previewActionItems: [UIPreviewActionItem]{
		var actionArr:[UIPreviewActionItem] = []
		actionArr.append(UIPreviewAction(title: "保存图片", style: .default, handler: {[weak self] (action, previewCtr) in
			self?.savePhoto()
		}))

		if self.photoList[0].photo == nil {
			let option = CloseOption()
			option.index = 0
			option.needQuality = .thumbnail
			let _ = largeClose?(option){ photo in
				self.photoList[0].photo = photo
			}
		}
		self.photoList[0].checkHasQRCode { }
		if let qrCode = self.photoList[0].QRCode {
			if (qrCode.count) > 0 {
				actionArr.append(UIPreviewAction(title: "识别图中的二维码", style: .default, handler: { (action, previewCtr) in
					self.QRCodeHandler(qrCode,nil)
				}))
			}
		}

		return actionArr
	}
}
