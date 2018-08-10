//
//  ViewController.swift
//  MDKImageCollection
//
//  Created by mikun on 2018/7/9.
//  Copyright © 2018 mdk. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
//		InfiniteTest()
//		gakkiTest()
//		UpdateTest()
		QRCodeTest()
	}
	override func viewDidLayoutSubviews() {
		imageCollection.frame = view.bounds
	}
	var imageCollection:MDKImageCollectionView!
	func InfiniteTest() -> () {
		let flow = UICollectionViewFlowLayout()
		flow.itemSize = CGSize(width: 100, height: 100)
		imageCollection = MDKImageCollectionView(frame: CGRect(), flowLayout: flow)
		view.addSubview(imageCollection)

		imageCollection.thumbnailForIndexUseCheck(close: { (option, handler) in
			handler(UIImage(named: "\(option.index%3)"))
			return true
		}).largeForIndex { (option, handler) in
			handler(UIImage(named: "\(option.index%3)"))
		}
		imageCollection.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height)
	}
	func UpdateTest() -> () {
		let flow = UICollectionViewFlowLayout()
		flow.itemSize = CGSize(width: 100, height: 100)
		imageCollection = MDKImageCollectionView(frame: CGRect(), flowLayout: flow)
		view.addSubview(imageCollection)
		
		imageCollection.thumbnailForIndex(count: 20, close: { (option, handler) in
			handler(UIImage(named: "\(option.index%3)"))
			if option.index == 19{
				self.imageCollection.updateCount(40)
			}
		}).largeForIndex { (option, handler) in
				handler(UIImage(named: "\(option.index%3)"))
		}
		imageCollection.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height)
	}
	func gakkiTest() -> () {
		guard
			let path = Bundle.main.path(forResource: "gakki.plist", ofType: nil),
			let urlArr = NSArray(contentsOfFile: path) as? [String]
		else {return}
		
		let flow = UICollectionViewFlowLayout()
		flow.itemSize = CGSize(width: 100, height: 100)
		imageCollection = MDKImageCollectionView(frame: CGRect(), flowLayout: flow)
		view.addSubview(imageCollection)
		imageCollection.registerFor3DTouchPreviewing(self)
		imageCollection.thumbnailForIndex(count: urlArr.count, close: { (option, handler) in
			let url = urlArr[option.index].replacingOccurrences(of: "thumb300", with: "orj360")
			self.downloadImage(url: url, finish: { (image) in
				handler(image)
			})
		}).largeForIndex { (option, handler) in
			let url = urlArr[option.index].replacingOccurrences(of: "thumb300", with: "large")
			print(url)
			self.downloadImage(url:url , finish: { (image) in
				handler(image)
			})
		}
		imageCollection.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height)
	}
	func QRCodeTest() -> () {
		imageCollection = MDKImageCollectionView()
		let layout = imageCollection.collectionViewLayout as! UICollectionViewFlowLayout
		layout.itemSize = CGSize(width: 200, height: 200)
		view.addSubview(imageCollection)

		imageCollection.thumbnailForIndex(count: 1, close: { (_, handler) in
			handler(#imageLiteral(resourceName: "QRCode"))
		}).largeForIndex { (option, handler) in
				handler(#imageLiteral(resourceName: "QRCode"))
		}
		imageCollection.frame.size = #imageLiteral(resourceName: "QRCode").size
		imageCollection.center = view.center
	}

	var cache:NSCache<NSString,UIImage> = NSCache()
	func downloadImage(url urlstr:String , finish:@escaping (UIImage)->()) {
		if let image =  cache.object(forKey: urlstr as NSString) {
			finish(image)
			return
		}
		guard let url = URL(string: urlstr) else {return}

		URLSession.shared.dataTask(with: url) {[weak self] (data, _, _) in
			guard
				let data = data,
				let image = UIImage(data: data)
			else {return}
			self?.cache.setObject(image, forKey: urlstr as NSString)
			finish(image)
		}.resume()
	}

}

