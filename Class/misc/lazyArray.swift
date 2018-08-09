//
//  lazyArray.swift
//  MDKImageCollection
//
//  Created by mikun on 2018/7/31.
//  Copyright © 2018 mdk. All rights reserved.
//


struct lazyArray<Element> {
	typealias handleClose = (Int)->(Element)

	var array:[Int:Element] = [:]

	var count:Int = 0 {
		didSet{
			if count == 0 {
				array.removeAll()
			}
		}
	}

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
			array[pos] = newValue
		}
	}
}


extension Array where Element == photoNode{
	var photoCount:Int{
		var count:Int = 0
		for node in self{
			if node.photo != nil {
				count += 1
			}else{
				break
			}
		}
		return count
	}
}
