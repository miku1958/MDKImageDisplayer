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

	}

	@IBAction func openDemo(_ sender: UIButton) {
		let demo = DemoCtr()
		demo.index = sender.tag;
		navigationController?.pushViewController(demo, animated: true)
	}
	

}

