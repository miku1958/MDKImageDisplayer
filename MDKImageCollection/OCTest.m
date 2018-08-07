//
//  OCTest.m
//  MDKImageCollection
//
//  Created by mikun on 2018/7/9.
//  Copyright © 2018 mdk. All rights reserved.
//

#import "OCTest.h"
#import "MDKImageCollection-Swift.h"
#import "MDKImageCollectionView.h"

@implementation OCTest
- (instancetype)init
{
	self = [super init];
	if (self) {
		MDKImageCollectionView *collection = [[MDKImageCollectionView alloc]initWithFrame:CGRectZero flowLayout:UICollectionViewFlowLayout.new];

		[collection thumbnailForIndexWithCount:0 close:^BOOL(NSInteger index, void (^handler)(UIImage *)) {
			
			return NO;
		}];
		[collection largeForIndexWithClose:^NSString *(CloseOption *option, void (^handler)(UIImage *)) {
			return nil;
		}];


	}
	return self;

	
}
@end
