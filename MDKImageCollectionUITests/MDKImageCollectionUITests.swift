//
//  MDKImageCollectionUITests.swift
//  MDKImageCollectionUITests
//
//  Created by mikun on 2018/9/20.
//  Copyright © 2018 mdk. All rights reserved.
//

import XCTest

class MDKImageCollectionUITests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {


		let app = XCUIApplication()
		app.buttons["本地图片延迟加载(无限加载),图片来源@王菊 的猫"].tap()

		let collectionViewsQuery = app.collectionViews
		collectionViewsQuery.children(matching: .cell).element(boundBy: 0).children(matching: .other).element.tap()

		let scrollView = collectionViewsQuery/*@START_MENU_TOKEN@*/.scrollViews.containing(.image, identifier:"0").element/*[[".cells.scrollViews.containing(.image, identifier:\"0\").element",".scrollViews.containing(.image, identifier:\"0\").element"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
		scrollView/*@START_MENU_TOKEN@*/.swipeLeft()/*[[".swipeDown()",".swipeLeft()"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/

		let scrollView2 = collectionViewsQuery/*@START_MENU_TOKEN@*/.scrollViews.containing(.image, identifier:"1").element/*[[".cells.scrollViews.containing(.image, identifier:\"1\").element",".scrollViews.containing(.image, identifier:\"1\").element"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
		scrollView2.tap()
		collectionViewsQuery/*@START_MENU_TOKEN@*/.scrollViews.containing(.image, identifier:"2").element.swipeLeft()/*[[".cells.scrollViews.containing(.image, identifier:\"2\").element",".swipeDown()",".swipeLeft()",".scrollViews.containing(.image, identifier:\"2\").element"],[[[-1,3,1],[-1,0,1]],[[-1,2],[-1,1]]],[0,0]]@END_MENU_TOKEN@*/
		scrollView.tap()
		collectionViewsQuery.children(matching: .cell).element(boundBy: 7).children(matching: .other).element.tap()
		scrollView2.tap()
		scrollView.tap()
		scrollView2.tap()
		collectionViewsQuery.children(matching: .cell).element(boundBy: 10).children(matching: .other).element.tap()
		scrollView2/*@START_MENU_TOKEN@*/.swipeRight()/*[[".swipeUp()",".swipeRight()"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
		scrollView2.tap()
		scrollView2.tap()
		scrollView2/*@START_MENU_TOKEN@*/.swipeLeft()/*[[".swipeDown()",".swipeLeft()"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
		scrollView2.tap()
		scrollView2.tap()
		scrollView2.tap()
		scrollView2.tap()
		scrollView2.tap()
		scrollView2.tap()
		scrollView2.tap()
		scrollView2.tap()
		scrollView2.tap()
		scrollView2.swipeRight()
		scrollView2.swipeLeft()
		scrollView2.tap()


    }

}
