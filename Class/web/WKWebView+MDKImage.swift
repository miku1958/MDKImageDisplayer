//
//  WKWebView+MDKImage.swift
//  MDKImageCollection
//
//  Created by mikun on 2018/8/30.
//  Copyright © 2018 mdk. All rights reserved.
//

import Foundation
import WebKit

extension WKWebView {
	public var MDKImage:MDKImageWebHocker {
		let hocker = MDKImageWebHocker.share
		hocker.webView = self;
		return hocker
	}
}
