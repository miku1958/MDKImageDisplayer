//
//  MDKImageCollectionView.swift
//  MDKImageCollection
//
//  Created by mikun on 2018/7/9.
//  Copyright © 2018 mdk. All rights reserved.
//

import UIKit
@_exported import MDKTools

@objc public class CloseOption :NSObject{
	@objc public var lastIdentifier:String?
	@objc public var index:Int = 0
	@objc public var needQuality:LoadingPhotoQuality = .thumbnail
	@objc public var displayCtr:UIViewController!
}
@objc public class DisplayingOption : NSObject{
	@objc public var index:Int = 0
	@objc public var identifier:String = ""
}


public typealias imageClose = (UIImage?)->()
public typealias IndexTagImageClose =  (CloseOption,@escaping imageClose)->(String?)

open class MDKImageCollectionView: UICollectionView {

	@objc public var ImageCornerRadius:CGFloat = 0

	@objc public var customTransitionID:String?

	public typealias IndexImageClose =  (Int,@escaping imageClose)->(Bool)
	public typealias IndexImageReturnSelfClose =  (Int,@escaping IndexImageClose)->MDKImageCollectionView

	private var thumbnailClose:IndexImageClose? {
		didSet{

			hasThumbnailClose = thumbnailClose != nil
			guard let thumbnailClose = thumbnailClose else {return}

			let hasImage = thumbnailClose(0){image in
				DispatchQueue.main.async {
					if self.photoList.count == 0 {
						self.photoList.count = 1
					}
					if  self.autoSizeWhenOnePhot , !self.needAutoPreLoad , self.photoList.count == 1 {
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
			if hasImage , photoList.count == 0  {
				photoList.count = 1
			}
			reloadData()
			invalidateIntrinsicContentSize()
		}
	}

	public typealias IndexTagImageReturnSelfClose =  (@escaping IndexTagImageClose)->MDKImageCollectionView
	@objc public var hasLargeClose:Bool = false
	@objc public var hasThumbnailClose:Bool = false
	@objc public var displayingOption:DisplayingOption?{
		return MDKImageDisplayController.current()?.displayingOption
	}
	private var largeClose:IndexTagImageClose? {
		didSet{
			hasLargeClose = largeClose != nil
		}
	}


	public typealias intReturnSelfClose = (Int) -> (MDKImageCollectionView)

	private var _columnCount:Int = 0
	@objc public var autoSizeWhenOnePhot:Bool = false {
		didSet{
			if autoSizeWhenOnePhot {
				columnCount(1)
			}
		}
	}

	private var needAutoPreLoad:Bool = false
	private var currentColumnCount:Int = 0
	private var maxVisibleCount:Int = 0
	private var currentCount:Int = 0

	private var cusMiniteritemSpace:CGFloat = 0
	private var cusSectionInset:UIEdgeInsets = UIEdgeInsets()

	private var loadingIndex:Int = 1
	private var preloadToIndex:Int = 1
	private var isLoading:Bool = false

	var preloadPhotos:[photoNode] = []

	private var photoList:lazyArray<photoNode> = lazyArray(0, {(index)->(photoNode) in
		var photo = photoNode()
		photo.index = index
		return photo
	})


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

	@objc public var flowLayout: UICollectionViewFlowLayout{
		return collectionViewLayout as! UICollectionViewFlowLayout
	}
	@objc public func setForceSectionInset(_ inset:UIEdgeInsets){
		_forceSectionInset = inset
	}
	private var _forceSectionInset:UIEdgeInsets? {
		didSet{
			if _forceSectionInset != nil{
				flowLayout.sectionInset = _forceSectionInset!
			}
		}
	}

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
	func thumbnailForIndex(count:Int,close:@escaping IndexImageClose) ->  MDKImageCollectionView {
		needAutoPreLoad = count == 0
		if !needAutoPreLoad {
			photoList.count = count
		}else{
			photoList.count = 0
		}
		thumbnailClose = close
		return self;
	}

	//MARK:	large
	@objc @discardableResult open
	func largeForIndex(close:@escaping IndexTagImageClose) ->  MDKImageCollectionView {
		largeClose = close
		return self;
	}


	//MARK:	columnCount
	@objc open var columnCount_:intReturnSelfClose{
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


	//MARK:	updateCount
	@objc open var updateCount_:intReturnSelfClose{
		return {
			self.updateCollectionCount($0)
			return self;
		}
	}

	@discardableResult
	func updateCount(_ count:Int) ->  MDKImageCollectionView {
		self.updateCollectionCount(count)
		return self;
	}

	private func updateCollectionCount(_ count:Int) -> () {
		guard photoList.count != count else { return }
		if count == 0 {
			for cell in visibleCells as! [ThumbnailCell]{
				Transition.antiRegistr(view: cell.imageView)
			}
			photoList.count = 0;
			photoList.removeAll()
			reloadData()
		}else{
			var indexPs:[IndexPath] = []
			if count>photoList.count {
				for idx in photoList.count..<count {
					indexPs.append(IndexPath(item: idx, section: 0))
				}
				photoList.count = count
				insertItems(at: indexPs)
			}else{
				for idx in count..<photoList.count {
					indexPs.append(IndexPath(item: idx, section: 0))
				}
				photoList.count = count

				deleteItems(at: indexPs)
			}
		}
		invalidateIntrinsicContentSize()
	}
}

//MARK:	UICollectionViewDelegate,UICollectionViewDataSource
extension MDKImageCollectionView : UICollectionViewDelegate,UICollectionViewDataSource {
	public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return photoList.count
	}

	public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(ThumbnailCell.self), for: indexPath) as! ThumbnailCell
		return cell
	}
	public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath){
		let item = indexPath.item
		guard let cell = cell as? ThumbnailCell , let thumbnailClose = self.thumbnailClose else {return}
		if let customTransitionID = customTransitionID {
			Transition.register(view:cell.imageView, for: customTransitionID)
		}else{
			Transition.register(view:cell.imageView, for: "MDK\(Unmanaged.passUnretained(self).toOpaque())\(item)")
		}


		cell.imageView.image = nil
		let _ = thumbnailClose(item){[weak self] image in
			DispatchQueue.main.async {
				
				if let cacheCell = self?.cellForItem(at: IndexPath(item: item, section: 0)) as? ThumbnailCell{
					cacheCell.imageView.image = image
				}
			}
		}

		guard needAutoPreLoad else {return}

		if maxVisibleCount == 0 {
			layoutSubviews()
			maxVisibleCount = Int(CGFloat(currentColumnCount) * (frame.size.height / flowLayout.itemSize.height))
		}
		if maxVisibleCount>2 ,maxVisibleCount%2 != 0 {
			maxVisibleCount -= 1
		}
		Transition.syncQueue.async {
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
				
				Transition.synchronized({
					self.preloadPhotos.append(photo)
				})

				let hasImage = thumbnailClose(nextIndex){[weak self] image in

					if image != nil {
						DispatchQueue.main.sync {

							Transition.synchronized({
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
					Transition.synchronized({
						self.preloadPhotos.removeLast()
					})

					self.currentCount = nextIndex-1
					break
				}


			}
			DispatchQueue.main.sync {
				Transition.synchronized({

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
		let display = MDKImageDisplayController( photoCount: photoList.count){ [weak self] option,handler in
			guard self != nil else{return nil}
			switch option.needQuality {
			case .thumbnail:
				let _ = self!.thumbnailClose?(option.index){ photo  in
					handler(photo)
				}
			case .large , .original:
				return self!.largeClose?(option){ photo  in
					handler(photo)
				}
			}
			return nil
		}
		display.transition.ImageCornerRadius = ImageCornerRadius
		display.sourceTransitionIDPrefix = "\(Unmanaged.passUnretained(self).toOpaque())"
		display.setDisplayIndex(displayIndex)
		
		display.displayIndexWillChange = { [weak self]   index in
			let indexPath = IndexPath(item: index, section: 0)
			if let cell = self?.cellForItem(at: indexPath) , let contain = self?.visibleCells.contains(cell) , contain == true {
				return
			}
			//			self?.scrollToItem(at: indexPath, at: [], animated: true)
		}
		
		return display
	}
}

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
