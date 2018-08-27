//
//  ImageCollectionView.swift
//  MDKImageCollection
//
//  Created by mikun on 2018/7/9.
//  Copyright © 2018 mdk. All rights reserved.
//





//FIXME:	去掉flowlayout.改成通用型.完全交给开发者决定布局.默认初始化保留flowlayout
//FIXME:	handler改成传出去一个UIImageVIew,可以通过注册类型来改显示的UIIMageView以支持gif/视频


open class ImageCollectionView: UICollectionView {

	
	@objc public convenience init() {
		let layout = UICollectionViewFlowLayout();
		layout.minimumLineSpacing = 2
		layout.minimumInteritemSpacing = 2
		self.init(frame: CGRect(), flowLayout: layout)
	}
	private convenience init(frame: CGRect) {
		self.init()
	}
	private override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
		super.init(frame: frame, collectionViewLayout: layout)
	}
	@objc public convenience init(frame: CGRect, flowLayout layout: UICollectionViewFlowLayout) {
		
		self.init(frame: frame, collectionViewLayout: layout)
		initSelf()
	}
	
	public required  init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		initSelf()
	}
	func initSelf() -> () {
		delegate = self
		dataSource = self
//		cusMiniteritemSpace = flowLayout.minimumInteritemSpacing
//		cusSectionInset = flowLayout.sectionInset

		MDKRegister(Cell: ThumbnailCell.self)
		if #available(iOS 11.0, *) {
			self.contentInsetAdjustmentBehavior = .never
		}
	}

	var cellSize:CGSize = CGSize(width: MDKScreenWidth, height: MDKScreenHeight)
	

	@objc public var imageTransitionCornerRadius:CGFloat = 0




	@objc public var hasThumbnailClose:Bool = false
	private var thumbnailClose:OptionImgClose? {
		didSet{
			updateThumbnailClose()
		}
	}
	private var thumbnaiIdentifierClose:OptionImgRtBoolClose? {
		didSet{
			updateThumbnailClose()
		}
	}

	func updateThumbnailClose() -> () {
		hasThumbnailClose = !(thumbnailClose == nil && thumbnaiIdentifierClose == nil)
		let option = MDKImageCloseOption()
		option.index = 0;

		let handler:imageClose = {image in
			DispatchQueue.main.async {
				if self.needAutoPreLoad , self.photoList.count == 0 {
					self.photoList.count = 1
				}
//				if  self.autoSizeWhenOnePhot , !self.needAutoPreLoad ,self.photoList.count == 1 {
//					if image != nil{
//						self.flowLayout.itemSize = image!.size
//						self.flowLayout.itemSize.width = min(self.flowLayout.itemSize.width, self.frame.width-self.contentInset.left - self.contentInset.right)
//					}
//					self.reloadData()
//					self.invalidateIntrinsicContentSize()
//				}
				if let cell = self.cellForItem(at: IndexPath(item: 0, section: 0)) as? ThumbnailCell {
					cell.imageView.image = image
				}
			}
		}

		if let thumbnailClose = thumbnailClose  {
			thumbnailClose(option,handler)
		}else if let thumbnailClose = thumbnaiIdentifierClose{
			let hasImage = thumbnailClose(option,handler)
			if hasImage , photoList.count == 0  {
				photoList.count = 1
			}
		}

		reloadData()
		invalidateIntrinsicContentSize()
	}

	open override func reloadData() {
		super.reloadData()
	}

	@objc public var hasLargeClose:Bool = false
	private var largeClose:OptionImgClose? {
		didSet{
			hasLargeClose = largeClose != nil || hasLargeClose
		}
	}
	
	private var largeIdentifierClose:OptionImgRtStringClose? {
		didSet{
			hasLargeClose = largeClose != nil || hasLargeClose
		}
	}
	@objc public var displayingInfo:MDKImageDisplayingInfo?{
		return MDKImageDisplayController.current()?.displayingInfo
	}

	@objc public var sourceScreenInset:UIEdgeInsets = UIEdgeInsets()


	//FIXME:	废弃
//	private var _columnCount:Int = 0
//	@objc public var autoSizeWhenOnePhot:Bool = false {
//		didSet{
//			if autoSizeWhenOnePhot {
//				columnCount(1)
//			}
//		}
//	}

	private var needAutoPreLoad:Bool = false
	private var maxVisibleCount:Int = 0
	
//	//FIXME:	废弃
//	private var currentColumnCount:Int = 0
//	//FIXME:	废弃
//	private var currentCount:Int = 0
//
//	//FIXME:	废弃
//	private var cusMiniteritemSpace:CGFloat = 0
//	//FIXME:	废弃
//	private var cusSectionInset:UIEdgeInsets = UIEdgeInsets()

	private var loadingIndex:Int = 1
	private var preloadToIndex:Int = 1
	private var isLoading:Bool = false

	var preloadPhotos:[photoNode] = []

	private var photoList:lazyArray<photoNode> = lazyArray(0, {(index)->(photoNode) in
		var photo = photoNode()
		photo.index = index
		return photo
	})


//	//FIXME:	废弃?
	@objc public var flowLayout: UICollectionViewFlowLayout?{
		return collectionViewLayout as?  UICollectionViewFlowLayout
	}
//	//FIXME:	废弃
//	@objc public func setForceSectionInset(_ inset:UIEdgeInsets){
//		_forceSectionInset = inset
//	}
//	//FIXME:	废弃
//	private var _forceSectionInset:UIEdgeInsets? {
//		didSet{
//			if _forceSectionInset != nil{
//				flowLayout.sectionInset = _forceSectionInset!
//			}
//		}
//	}



}
//MARK:	view function
extension ImageCollectionView{
	open override func layoutSubviews() {
		
		super.layoutSubviews()
//		if _columnCount == 0 {
//			flowLayout.minimumInteritemSpacing = cusMiniteritemSpace
//			flowLayout.sectionInset = _forceSectionInset != nil ? _forceSectionInset! : cusSectionInset
//			var contentWidth = frame.size.width - cusSectionInset.left - cusSectionInset.right - flowLayout.itemSize.width
//			currentColumnCount = 0
//			while contentWidth > 0 {
//				currentColumnCount += 1
//				contentWidth -= flowLayout.itemSize.width
//				contentWidth -= cusMiniteritemSpace
//			}
//			return;
//		}
//		currentColumnCount = _columnCount
//		var tempMaxCount = CGFloat(currentColumnCount)
//		if flowLayout.itemSize.height > 0 {
//			tempMaxCount = tempMaxCount * (frame.size.height / flowLayout.itemSize.height)
//		}

//		maxVisibleCount = max(1, Int(tempMaxCount))
//		var itemWidths:CGFloat = 0
//		var itemWidth = min(frame.width, flowLayout.itemSize.width )
//		let itemHeight = min(frame.height, flowLayout.itemSize.height)
//		if itemWidth > 0 , itemHeight > 0{
//			itemWidth = min(itemWidth, frame.width-contentInset.left - contentInset.right)
//			flowLayout.itemSize = CGSize(width: itemWidth, height: itemHeight)
//			while itemWidths < frame.size.width {
//				itemWidths += itemWidth
//			}
//			let itemCount = max(1, Int(itemWidths / itemWidth))
//			if  itemCount <= _columnCount {
//				//尺寸满足条件,查看间距需不需要调整
//				let interSpace = (frame.size.width - itemWidths) / CGFloat(itemCount - 1)
//				if interSpace < flowLayout.minimumInteritemSpacing {
//					flowLayout.minimumInteritemSpacing = interSpace
//				}
//			}else {
//				//一行能放的比columnCount多
//				let interSpace = CGFloat(Int((frame.size.width - flowLayout.itemSize.width * CGFloat(_columnCount)) / CGFloat(_columnCount + 1)))
//				flowLayout.minimumInteritemSpacing = interSpace
//				if _forceSectionInset != nil{
//					flowLayout.sectionInset = _forceSectionInset!;
//				}else{
//					flowLayout.sectionInset = UIEdgeInsets(top: cusSectionInset.top, left: interSpace, bottom: cusSectionInset.bottom, right: interSpace)
//				}
//			}
//		}

		if !self.bounds.size.equalTo(intrinsicContentSize) {
			
			invalidateIntrinsicContentSize()
			
		}
	}
	open override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
		return self.contentSize
	}
	open override var intrinsicContentSize: CGSize {
		return self.contentSize
	}
}

//MARK:	链式设置
extension ImageCollectionView{
	//MARK:	thumbnail
	@objc @discardableResult open
	func thumbnailForIndex(count:Int , close:@escaping OptionImgClose) ->  ImageCollectionView {
		needAutoPreLoad = false
		
		photoList.count = count;
		thumbnailClose = close
		return self;
	}
	
	@objc @discardableResult open
	func thumbnailForIndexUseCheck(close:@escaping OptionImgRtBoolClose) ->  ImageCollectionView {
		needAutoPreLoad = true
		
		photoList.count = 0;
		thumbnaiIdentifierClose = close
		return self;
	}


	//MARK:	large
	@objc @discardableResult open
	func largeForIndex(close:@escaping OptionImgClose) ->  ImageCollectionView {
		largeClose = close
		return self;
	}
	@objc @discardableResult open
	func largeForIndexUseIndetifier(close:@escaping OptionImgRtStringClose) ->  ImageCollectionView {
		largeIdentifierClose = close
		return self;
	}

	public typealias OptionImgRtBoolClose =  (MDKImageCloseOption,@escaping imageClose)->(Bool)
	public typealias intRtSelfClose = (Int) -> (ImageCollectionView)

	//MARK:	updateCount
	@objc open var updateCount_:intRtSelfClose{
		return {
			self.updateCollectionCount($0)
			return self;
		}
	}

	@discardableResult
	func updateCount(_ count:Int) ->  ImageCollectionView {
		self.updateCollectionCount(count)
		return self;
	}

	private func updateCollectionCount(_ count:Int) -> () {
		guard photoList.count != count else { return }
		if count == 0 {
			photoList.count = 0;
			isHidden = true
		}else{
			isHidden = false
			var indexPs:[IndexPath] = []
			if count>photoList.count {
				for idx in photoList.count..<count {
					indexPs.append(IndexPath(item: idx, section: 0))
				}
				
				DispatchQueue.main.async {
					self.photoList.count = count
					self.insertItems(at: indexPs)
				}
			}else{
				for idx in count..<photoList.count {
					indexPs.append(IndexPath(item: idx, section: 0))
				}
				DispatchQueue.main.async {
					self.photoList.count = count
					self.deleteItems(at: indexPs)
				}
			}
		}
		invalidateIntrinsicContentSize()
	}
}

//MARK:	UICollectionViewDelegate,UICollectionViewDataSource
extension ImageCollectionView : UICollectionViewDelegateFlowLayout,UICollectionViewDataSource {
	public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return photoList.count
	}

	public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(ThumbnailCell.self), for: indexPath) as! ThumbnailCell
		return cell
	}
	public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath){
		let item = indexPath.item
		guard let cell = cell as? ThumbnailCell else  {return}



		cell.imageView.image = nil
		let option = MDKImageCloseOption()
		option.index = item;
		let handler:imageClose = {[weak self] image in
			DispatchQueue.main.async {
				if let cacheCell = self?.cellForItem(at: IndexPath(item: item, section: 0)) as? ThumbnailCell{
					cacheCell.imageView.image = image
				}
			}
		}
		if let thumbnailClose = self.thumbnailClose{
			thumbnailClose(option,handler)
		}else if let thumbnailClose = thumbnaiIdentifierClose{
			let _ = thumbnailClose(option,handler)
		}

		guard needAutoPreLoad ,let thumbnailClose = thumbnaiIdentifierClose else {return}
		
		if maxVisibleCount == 0 {
			if let items = collectionViewLayout.layoutAttributesForElements(in: collectionView.bounds){
				maxVisibleCount = items.count
			}
		}
		if maxVisibleCount>2 ,maxVisibleCount%2 != 0 {
			maxVisibleCount -= 1
		}
		MDKImageTransition.syncQueue.async {
			var beginIndex = 0
			var endIndex = 0
			let pageCount = self.maxVisibleCount//如果比这个值高的话,有可能在滚太快的时候导致这个index的cell没有显示就跳过了
			let preloadCount = pageCount
			if indexPath.item == 0{
				//加载第一页self.maxVisibleCount个
				beginIndex = 1
				endIndex = beginIndex + self.maxVisibleCount/*第一页*/ + preloadCount
			}else if indexPath.item % pageCount == 0{
				//间隔self.maxVisibleCount/2个,加载
				beginIndex = (indexPath.item/pageCount) * (pageCount) + 1 + self.maxVisibleCount
				endIndex = beginIndex + preloadCount
			}else{
				return
			}
			if self.photoList.count >= endIndex{
				return
			}

			if self.photoList.count > 0 ,beginIndex < self.photoList[0].index{
				return
			}

			for nextIndex in beginIndex..<endIndex{

				var photo = photoNode()
				photo.index = nextIndex
				
				MDKImageTransition.synchronized({
					self.preloadPhotos.append(photo)
				})
				let option = MDKImageCloseOption()
				option.index = nextIndex;
				let hasImage = thumbnailClose(option){[weak self] image in

					if image != nil {
						DispatchQueue.main.sync {

							MDKImageTransition.synchronized({
								guard self != nil else { return }
								if let firstPhoto = self!.preloadPhotos.first ,
									nextIndex >= firstPhoto.index ,
									nextIndex - firstPhoto.index < self!.preloadPhotos.count{

								}else if nextIndex<self!.photoList.count{
									if let cell = collectionView.cellForItem(at: IndexPath(item: nextIndex, section: 0)) as? ThumbnailCell {
										cell.imageView.image = image
									}
								}
							})

						}
					}
				}
				if(!hasImage){
					MDKImageTransition.synchronized({
						self.preloadPhotos.removeLast()
					})

//					self.currentCount = nextIndex-1
					break
				}


			}
			DispatchQueue.main.sync {
				MDKImageTransition.synchronized({

					if self.preloadPhotos.count > 0{
						var insertedIndexPaths:[IndexPath] = []
						self.photoList.count += self.preloadPhotos.count
						for photo in self.preloadPhotos{
							self.photoList[photo.index] = photo
							insertedIndexPaths.append(IndexPath(item: photo.index, section: 0))
						}
						UIView.performWithoutAnimation {
							CATransaction.begin()
							CATransaction.setDisableActions(true)

							self.insertItems(at: insertedIndexPaths)

							CATransaction.commit()
						}
		
						self.preloadPhotos.removeAll()
					MDKImageDisplayController.current()?.updatePhotoCount(self.photoList.count)
					}

				})
			}
		}
	}

	public func collectwillDisplayCellionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		if let cell = cell as? ThumbnailCell {
			cell.imageView.image = nil
		}
	}

	public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let display = getDisplayCtr(displayIndex: indexPath.item)
		MDKRootViewController.present(display, animated: true, completion: {
			
		})
		
	}
//	public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//		return CGSize(width: min(cellSize.width, frame.width), height: min(cellSize.height, frame.height))
//	}
//	
	func getDisplayCtr(displayIndex:Int) -> (MDKImageDisplayController) {
		let display:MDKImageDisplayController!
			
		if let largeClose = largeClose {
			display = MDKImageDisplayController( photoCount: photoList.count){ [weak self] option,handler in
				guard let _self = self else{return}
				switch option.needQuality {
				case .thumbnail:
					if let thumbnailClose = _self.thumbnailClose{
						thumbnailClose(option){ photo  in
							handler(photo)
						}
					}else if let thumbnailClose = _self.thumbnaiIdentifierClose {
						let _ = thumbnailClose(option){ photo  in
							handler(photo)
						}
					}
					
				case .large , .original:
					largeClose(option){ photo  in
						handler(photo)
					}
				}
			}
		}else{
			let largeIdentifierClose = self.largeIdentifierClose!
			display = MDKImageDisplayController(largeClose: { [weak self] (option, handler) -> (String?) in
				guard let _self = self else{return nil}
				switch option.needQuality {
				case .thumbnail:
					if let thumbnailClose = _self.thumbnailClose{
						thumbnailClose(option){ photo  in
							handler(photo)
						}
					}else if let thumbnailClose = _self.thumbnaiIdentifierClose {
						let _ = thumbnailClose(option){ photo  in
							handler(photo)
						}
					}
					
				case .large , .original:
					return largeIdentifierClose(option){ photo  in
						handler(photo)
					}
					
				}
				return nil
			})
		}
			
		
		display.transition.ImageCornerRadius = imageTransitionCornerRadius
		display.transition.sourceScreenInset = sourceScreenInset

		display.registerAppearSourecView = { [weak self] in
			return self?.cellForItem(at: IndexPath(item: displayIndex, section: 0))
		}
		display.registerDismissTargetView = { [weak self] (option) ->(UIView?) in
			return self?.cellForItem(at: IndexPath(item: option.index, section: 0))
		}

		display.setDisplayIndex(displayIndex)
		
		display.displayIndexWillChange = { [weak self]   index in
			guard index>=0 , index<self?.photoList.count ?? 0  else { return }
			let indexPath = IndexPath(item: index, section: 0)
			if let cell = self?.cellForItem(at: indexPath) , let contain = self?.visibleCells.contains(cell) , contain == true {
				return
			}
			self?.scrollToItem(at: indexPath, at: [], animated: true)
		}

		return display
	}
}
//MARK:	系统功能
extension ImageCollectionView: UIViewControllerPreviewingDelegate{

	@available(iOS 9.0, *)
	public func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {

		guard
			let indexPath = indexPathForItem(at: location),
			let cell = cellForItem(at: indexPath) as? ThumbnailCell ,
			let image = cell.imageView.image
		else {
			return nil
		}
		
		previewingContext.sourceRect = cell.frame
		
		
		let display = getDisplayCtr(displayIndex: indexPath.item)
		display.isFrom3DTouch = true

		//设置显示高度
		display.preferredContentSize = CGSize(width: MDKScreenWidth, height: min(MDKScreenHeight, MDKScreenWidth/image.size.width * image.size.height))
		
		return display;
		
	}
	
	public func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
		MDKRootViewController.present(viewControllerToCommit, animated: true, completion: nil)
	}
	
	@available(iOS 9.0, *) @objc @discardableResult open
	func registerFor3DTouchPreviewing(_  source:UIViewController) -> UIViewControllerPreviewing{
		return source.registerForPreviewing(with: self, sourceView: self)
	}

	@available(iOS 9.0, *) @objc open
	func quickRegister3DTouchPreviewing() -> (){
		MDKRootViewController.registerForPreviewing(with: self, sourceView: self)
	}
	
}
