//
//  toolbarView.swift
//  MDKImageCollection
//
//  Created by mikun on 2018/7/17.
//  Copyright © 2018 mdk. All rights reserved.
//

import UIKit

class toolbarView: UIView {


	let table = UITableView(frame: MDKKeywindow.bounds, style: .grouped)


	let identifier = NSStringFromClass(UITableViewCell.self)
	let cellBlurTag = 123
	let cellSeparatorTag = 233

	override init(frame: CGRect) {
		super.init(frame: MDKKeywindow.bounds)

		addSubview(table)

		table.dataSource = self
		table.delegate = self

		if #available(iOS 11.0, *) {
			table.contentInsetAdjustmentBehavior = .never
		}
		table.estimatedSectionHeaderHeight = 0
		table.estimatedSectionFooterHeight = 0
		table.isScrollEnabled = false
		table.separatorStyle = .none

		backgroundColor = nil
		table.backgroundColor = nil
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}


	typealias actionClose = ()->()

	var actionList:[  [  [String:actionClose]  ]  ] = []

	@discardableResult
	func addGroup() ->  toolbarView {
		actionList.append([])
		reload()
		return self;
	}
	@discardableResult
	func insertGroup(at index:Int) ->  toolbarView {
		actionList.insert([], at: index)
		reload()
		return self;
	}

	@discardableResult
	func addAction(title:String	 , action:@escaping actionClose) ->  toolbarView {
		if actionList.count == 0{
			actionList.append([])
		}
		actionList[actionList.count-1].append([title:action])
		reload()
		return self;
	}

	@discardableResult
	func insertAction(title:String	 , action:@escaping actionClose, atGroup groupIndex:Int, at index:Int) ->  toolbarView {
		actionList[groupIndex].insert([title:action], at: index)
		insert(row: index, group: groupIndex)
		return self
	}

	var finalAction:actionClose?
	@discardableResult
	func addFinalAction(action:@escaping actionClose) ->  toolbarView{
		finalAction = action
		return self
	}

	@discardableResult
	func removeAllAction() ->  toolbarView{
		actionList.removeAll()
		return self
	}
	@discardableResult
	func removeAllActionAt(groupIndex:Int) ->  toolbarView{
		actionList.remove(at: groupIndex)
		return self
	}
	@discardableResult
	func removeFinalAction() ->  toolbarView{
		finalAction = nil
		return self
	}
	func reload() -> () {
		table.frame.size.width = MDKKeywindow.frame.width
		table.reloadData()
		table.layoutIfNeeded()
		self.frame.size = table.contentSize
	}
	func insert(row:Int , group:Int) -> () {
		table.frame.size.width = MDKKeywindow.frame.width
		table.insertRows(at: [IndexPath(row: row, section: group)], with: .automatic)
		if row > 0 {
			table.reloadRows(at: [IndexPath(row: row-1, section: group)], with: .automatic)
		}
		table.layoutIfNeeded()
		self.frame.size = table.contentSize
	}
}

extension toolbarView : UITableViewDataSource,UITableViewDelegate{
	func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		return section == actionList.count-1 ? 1 : 10
	}
	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 1
	}
	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		return nil
	}

	func numberOfSections(in tableView: UITableView) -> Int {
		return actionList.count
	}
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return actionList[section].count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

		var cell = table.dequeueReusableCell(withIdentifier: identifier)

		if cell == nil {
			cell = UITableViewCell(style: .default, reuseIdentifier: identifier)
			cell?.textLabel?.textAlignment = .center
			if #available(iOS 8.2, *) {
				cell?.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .light)
			} else {
				cell?.textLabel?.font = UIFont.systemFont(ofSize: 17)
			}
			cell?.backgroundColor = nil


			let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
			cell?.contentView.insertSubview(blurView, belowSubview: cell!.textLabel!)
			blurView.tag = cellBlurTag


			let separator = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 1))
			cell?.contentView.insertSubview(separator, aboveSubview: blurView)
			separator.tag = cellSeparatorTag
			separator.backgroundColor = MDKColorFrom(Hex: 0x999999)
		}

		cell?.textLabel?.text = actionList[indexPath.section][indexPath.row].keys.first

		return cell!
	}
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		cell.contentView.viewWithTag(cellBlurTag)?.frame = cell.bounds
		if let separator = cell.contentView.viewWithTag(cellSeparatorTag) {
			separator.frame.size.width = cell.bounds.width
			separator.frame.origin.y = cell.bounds.height - separator.frame.height
			separator.isHidden = indexPath.row == actionList[indexPath.section].count - 1
		}

	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: false)
		actionList[indexPath.section][indexPath.row].values.first?()
		finalAction?()
	}
}
