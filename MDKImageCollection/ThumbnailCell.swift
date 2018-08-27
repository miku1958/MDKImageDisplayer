//
//  ThumbnailCell.swift
//  MDKImageCollection
//
//  Created by mikun on 2018/7/9.
//  Copyright © 2018 mdk. All rights reserved.
//

import UIKit

class ThumbnailCell: UICollectionViewCell,MDKImageProtocol {
	let imageView:UIImageView = {
		let view = UIImageView()
		view.contentMode = .scaleAspectFill
		view.clipsToBounds = true
		
		return view
	}()




	override init(frame: CGRect) {
		super.init(frame: frame)
		addSubview(imageView)
	}

	override func layoutSubviews() {
		imageView.frame = self.bounds
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
}
