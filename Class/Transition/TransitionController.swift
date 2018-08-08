//
//  TransitionController.swift
//  MDKImageCollection
//
//  Created by mikun on 2018/7/25.
//  Copyright © 2018 mdk. All rights reserved.
//


class TransitionController: UIPresentationController {
	override func presentationTransitionWillBegin() {
		if let presentedView = presentedView , let containerView = containerView{
			presentedView.frame = containerView.bounds;
			containerView.addSubview(presentedView)
		}
	}

	override func dismissalTransitionDidEnd(_ completed: Bool) {
		presentedView?.removeFromSuperview()
	}
}
