//
//  lazyArray.swift
//  MDKImageCollection
//
//  Created by mikun on 2018/7/31.
//  Copyright © 2018 mdk. All rights reserved.
//

import Foundation

struct lazyArray<Element> {
	typealias handleClose = (Int)->(Element)
	var count:Int = 0
	var negativeCount:Int = 0
	func checkIndex(_ index:Int) -> Bool {
		if index >= count {
			return false
		}
		if index < 0 && index < -negativeCount{
			return false
		}
		return true
	}

	let handle:handleClose!
	var array:[Int:Element] = [:]
	init(_ count:Int , _ handle:@escaping handleClose) {
		self.count = count
		self.handle = handle
	}
	var first:Element?{
		return array[0]
	}
	var last:Element?{
		return array[count-1]
	}
	mutating func removeAll() -> () {
		array.removeAll()
	}
	subscript(pos:Int) -> Element {
		mutating get {
			if let element = self.array[pos] {
				return element
			}else{
				assert(pos < count, "上越界")
				if pos<0{
					assert(pos >= -negativeCount,"下越界")
				}
				self.array[pos] = handle(pos)
				return array[pos]!
			}
		}
		set {
			if (newValue as! photoNode).identifier == nil {

			}
			array[pos] = newValue
		}
	}
}
