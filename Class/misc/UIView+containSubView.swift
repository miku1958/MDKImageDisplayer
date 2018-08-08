//
//  UIView+containSubView.swift
//  MDKImageCollection
//
//  Created by mikun on 2018/8/8.
//  Copyright © 2018年 mdk. All rights reserved.
//

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
