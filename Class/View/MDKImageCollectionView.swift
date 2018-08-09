//
//  MDKImageCollectionView.swift
//  MDKImageCollection
//
//  Created by mikun on 2018/7/9.
//  Copyright © 2018 mdk. All rights reserved.
//





//FIXME:	thumbnailClose改成两组一组传入数组数量后不需要返回BOOL/另一组去掉传入数组数量
//FIXME:	larget同理
//FIXME:	去掉flowlayout.改成通用型.完全交给开发者决定布局.默认初始化保留flowlayout


open class MDKImageCollectionView: UICollectionView {
	
	
	@objc public convenience init() {
		let layout = UICollectionViewFlowLayout();
		layout.itemSize = CGSize(width: MDKScreenWidth, height: MDKScreenHeight)
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
		cusMiniteritemSpace = flowLayout.minimumInteritemSpacing
		cusSectionInset = flowLayout.sectionInset
		
		MDKRegister(Cell: ThumbnailCell.self)
		if #available(iOS 11.0, *) {
			self.contentInsetAdjustmentBehavior = .never
		}
	}

	
	
	

	@objc public var ImageTransitionCornerRadius:CGFloat = 0

	@objc public var customTransitionID:String?



	@objc public var hasThumbnailClose:Bool = false
	private var thumbnailClose:OptionImgClose? {
		didSet{
			updateThumbnailClose()
		}
	}

	func updateThumbnailClose() -> () {
		hasThumbnailClose = thumbnailClose != nil
		let option = CloseOption()
		option.item = 0;

		let handler:imageClose = {image in
			DispatchQueue.main.async {
				if  self.autoSizeWhenOnePhot , self.photoList.count == 1 ,self.photoList[0].count == 1 {
					if image != nil{
						self.flowLayout.itemSize = image!.size
					}
					self.reloadData()
					self.invalidateIntrinsicContentSize()
				}
				if let cell = self.cellForItem(at: IndexPath(item: 0, section: 0)) as? ThumbnailCell {
					cell.imageView.image = image
				}
			}
		}

		if let thumbnailClose = thumbnailClose  {
			thumbnailClose(option,handler)
		}

		reloadData()
		invalidateIntrinsicContentSize()
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
	@objc public var displayingOption:DisplayingOption?{
		return MDKImageDisplayController.current()?.displayingOption
	}



	//FIXME:	废弃
	private var _columnCount:Int = 0
	@objc public var autoSizeWhenOnePhot:Bool = false {
		didSet{
			if autoSizeWhenOnePhot {
				columnCount(1)
			}
		}
	}

	private var maxVisibleCount:Int = 0
	
	//FIXME:	废弃
	private var currentColumnCount:Int = 0
	//FIXME:	废弃
	private var currentCount:Int = 0

	//FIXME:	废弃
	private var cusMiniteritemSpace:CGFloat = 0
	//FIXME:	废弃
	private var cusSectionInset:UIEdgeInsets = UIEdgeInsets()

	private var loadingIndex:Int = 1
	private var preloadToIndex:Int = 1
	private var isLoading:Bool = false

	var preloadPhotos:[photoNode] = []

	private var photoList:lazyArray<lazyArray<photoNode>> = lazyArray(0, {(index)->(lazyArray<photoNode>) in
		var section = lazyArray(0, {(index)->(photoNode) in
			var photo = photoNode()
			photo.item = index
			return photo
		})
		return section
	})


	//FIXME:	废弃
	@objc public var flowLayout: UICollectionViewFlowLayout{
		return collectionViewLayout as! UICollectionViewFlowLayout
	}
	//FIXME:	废弃
	@objc public func setForceSectionInset(_ inset:UIEdgeInsets){
		_forceSectionInset = inset
	}
	//FIXME:	废弃
	private var _forceSectionInset:UIEdgeInsets? {
		didSet{
			if _forceSectionInset != nil{
				flowLayout.sectionInset = _forceSectionInset!
			}
		}
	}



}
//MARK:	view function
extension MDKImageCollectionView{
	open override func layoutSubviews() {
		
		super.layoutSubviews()
		if _columnCount == 0 {
			flowLayout.minimumInteritemSpacing = cusMiniteritemSpace
			flowLayout.sectionInset = _forceSectionInset != nil ? _forceSectionInset! : cusSectionInset
			var contentWidth = frame.size.width - cusSectionInset.left - cusSectionInset.right - flowLayout.itemSize.width
			currentColumnCount = 0
			while contentWidth > 0 {
				currentColumnCount += 1
				contentWidth -= flowLayout.itemSize.width
				contentWidth -= cusMiniteritemSpace
			}
			return;
		}
		currentColumnCount = _columnCount
		var tempMaxCount = CGFloat(currentColumnCount)
		if flowLayout.itemSize.height > 0 {
			tempMaxCount = tempMaxCount * (frame.size.height / flowLayout.itemSize.height)
		}
		
		maxVisibleCount = max(1, Int(tempMaxCount))
		var itemWidths:CGFloat = 0
		let itemWidth = min(frame.width, flowLayout.itemSize.width )
		let itemHeight = min(frame.height, flowLayout.itemSize.height)
		if itemWidth > 0 , itemHeight > 0{
			flowLayout.itemSize = CGSize(width: itemWidth, height: itemHeight)
			while itemWidths < frame.size.width {
				itemWidths += itemWidth
			}
			let itemCount = max(1, Int(itemWidths / itemWidth))
			if  itemCount <= _columnCount {
				//尺寸满足条件,查看间距需不需要调整
				let interSpace = (frame.size.width - itemWidths) / CGFloat(itemCount - 1)
				if interSpace < flowLayout.minimumInteritemSpacing {
					flowLayout.minimumInteritemSpacing = interSpace
				}
			}else {
				//一行能放的比columnCount多
				let interSpace = CGFloat(Int((frame.size.width - flowLayout.itemSize.width * CGFloat(_columnCount)) / CGFloat(_columnCount + 1)))
				flowLayout.minimumInteritemSpacing = interSpace
				if _forceSectionInset != nil{
					flowLayout.sectionInset = _forceSectionInset!;
				}else{
					flowLayout.sectionInset = UIEdgeInsets(top: cusSectionInset.top, left: interSpace, bottom: cusSectionInset.bottom, right: interSpace)
				}
			}
		}
		
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
extension MDKImageCollectionView{
	//MARK:	thumbnail
	@objc @discardableResult open
	func thumbnailForIndex(sectionCount:Int , numberInSection:IndexRtIntClose , close:@escaping OptionImgClose) ->  MDKImageCollectionView {

		photoList.count = sectionCount;
		for section in 0..<sectionCount{
			photoList[section].count = numberInSection(sectionCount)
		}
		thumbnailClose = close
		return self;
	}


	//MARK:	large
	@objc @discardableResult open
	func largeForIndex(close:@escaping OptionImgClose) ->  MDKImageCollectionView {
		largeClose = close
		return self;
	}
	@objc @discardableResult open
	func largeForIndexUseIndetifier(close:@escaping OptionImgRtStringClose) ->  MDKImageCollectionView {
		largeIdentifierClose = close
		return self;
	}


	//MARK:	columnCount
	@objc open var columnCount_:intRtSelfClose{
		return {
			
			self._columnCount = $0
			return self;
		}
	}

	@discardableResult
	func columnCount(_ count:Int) ->  MDKImageCollectionView {
		_columnCount = count
		return self;
	}


	//MARK:	updateSectionCount
	@discardableResult
	func updateSectionCount(_ sectionCount:Int , numberInSection:IndexRtIntClose) ->  MDKImageCollectionView {
		self.updateCollectionSectionCount(sectionCount,numberInSection: numberInSection)
		return self;
	}

	private func updateCollectionSectionCount(_ sectionCount:Int , numberInSection:IndexRtIntClose) -> () {
		var needUpdate = photoList.count != sectionCount
		photoList.count = sectionCount

		if sectionCount == 0 {
			for cell in visibleCells as! [ThumbnailCell]{
				Transition.antiRegistr(view: cell.imageView)
			}
			reloadData()
		}else{
			var insertIndexPs:[IndexPath] = []
			var deleteIndexPs:[IndexPath] = []

			for section in 0..<sectionCount{
				let item = numberInSection(section)
				if item>photoList[section].count {
					for idx in photoList[section].count..<item {
						insertIndexPs.append(IndexPath(item: idx, section: 0))
					}
					photoList[section].count = item
				}else{
					for idx in item..<photoList[section].count {
						deleteIndexPs.append(IndexPath(item: idx, section: 0))
					}
					photoList[section].count = item

				}
			}

			if insertIndexPs.count>0{
				UIView.performWithoutAnimation {
					CATransaction.begin()
					CATransaction.setDisableActions(true)
					insertItems(at: insertIndexPs)
					layoutIfNeeded()
					CATransaction.commit()
				}
				needUpdate = true
			}
			if insertIndexPs.count>0{
				needUpdate = true
				deleteItems(at: deleteIndexPs)
			}
		}
		if needUpdate {
			invalidateIntrinsicContentSize()
		}
	}
}

//MARK:	UICollectionViewDelegate,UICollectionViewDataSource
extension MDKImageCollectionView : UICollectionViewDelegate,UICollectionViewDataSource {
	open override var numberOfSections: Int{
		return photoList.count;
	}
	public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return photoList[section].count
	}

	public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(ThumbnailCell.self), for: indexPath) as! ThumbnailCell
		return cell
	}
	public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath){
		let item = indexPath.item
		guard let cell = cell as? ThumbnailCell else  {return}
		if let customTransitionID = customTransitionID {
			Transition.register(view:cell.imageView, for: customTransitionID)
		}else{
			Transition.register(view:cell.imageView, for: "MDK\(Unmanaged.passUnretained(self).toOpaque())\(item)")
		}


		cell.imageView.image = nil
		let option = CloseOption()
		option.item = item;
		let handler:imageClose = {[weak self] image in
			DispatchQueue.main.async {

				if let cacheCell = self?.cellForItem(at: IndexPath(item: item, section: 0)) as? ThumbnailCell{
					cacheCell.imageView.image = image
				}
			}
		}
		if let thumbnailClose = self.thumbnailClose{
			thumbnailClose(option,handler)
		}

	}

	public func collectwillDisplayCellionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		if let cell = cell as? ThumbnailCell {
			Transition.antiRegistr(view: cell.imageView)
			cell.imageView.image = nil
		}
	}

	public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let display = getDisplayCtr(displayIndex: indexPath.item)
		MDKRootViewController.present(display, animated: true, completion: {
			
		})
		
	}
	
	func getDisplayCtr(displayIndex:Int) -> (MDKImageDisplayController) {
		var photoCount = 0
		for section in 0..<photoList.count {
			photoCount += photoList[section].count
		}
		let display = MDKImageDisplayController( photoCount: photoCount){ [weak self] option,handler in
			guard let _self = self else{return nil}

			var photoCount = 0
			for section in 0..<_self.photoList.count {
				photoCount += _self.photoList[section].count
				if photoCount>option.item{
					option.section = section
					option.item = option.item - (photoCount - _self.photoList[section].count)
					break;
				}
			}

			switch option.needQuality {
			case .thumbnail:
				_self.thumbnailClose?(option){ photo  in
					handler(photo)
				}
			case .large , .original:
				if _self.largeClose != nil{
					_self.largeClose?(option){ photo  in
						handler(photo)
					}
				}else{
					return _self.largeIdentifierClose?(option){ photo  in
						handler(photo)
					}
				}

			}
			return nil
		}
		display.transition.ImageCornerRadius = ImageTransitionCornerRadius
		display.sourceTransitionIDPrefix = "\(Unmanaged.passUnretained(self).toOpaque())"
		display.setDisplayIndex(displayIndex)
		
		display.displayIndexWillChange = { [weak self]   index in
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
extension MDKImageCollectionView: UIViewControllerPreviewingDelegate{

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


		//设置显示高度
		display.preferredContentSize = CGSize(width: MDKScreenWidth, height: min(MDKScreenHeight, MDKScreenWidth/image.size.width * image.size.height))
		
		return display;
		
	}
	
	public func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
		MDKRootViewController.show(viewControllerToCommit, sender: nil)
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
