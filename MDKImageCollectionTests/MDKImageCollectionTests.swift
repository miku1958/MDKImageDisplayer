//
//  MDKImageCollectionTests.swift
//  MDKImageCollectionTests
//
//  Created by mikun on 2018/9/19.
//  Copyright © 2018 mdk. All rights reserved.
//

import XCTest
@testable import MDKImageCollection

class MDKImageCollectionTests: XCTestCase {

    override func setUp() {
        super.setUp()
		continueAfterFailure = true
    }

	func testTransitionFinish() -> () {
		let transition = MDKImageTransition.global()
		XCTAssertNotNil(transition)

		transition.forceTransitionContextCompleteTransition()
		XCTAssertNil(transition._transitionContext)
		XCTAssertNil(transition.transitingView?.layer.mask)

		if let enable = transition.animatingCtr?.view.isUserInteractionEnabled{
			XCTAssertTrue(enable)
		}

		if let alpha = transition.animatingCtr?.view.alpha{
			XCTAssertTrue(alpha == 1)
		}


		XCTAssertNil(transition.isPresenting)

		XCTAssertFalse(transition.isInTransition)
	}
}
