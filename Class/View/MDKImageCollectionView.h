//
//  MDKImageCollectionView.h
//  MDKImageCollection
//
//  Created by mikun on 2018/8/5.
//  Copyright © 2018年 mdk. All rights reserved.
//

#import "MDKImageCollection-Swift.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullability-completeness"

@interface MDKImageCollectionView (SWIFT_EXTENSION(MDKImageCollection))
- (MDKImageCollectionView *)thumbnailForIndexWithCount:(NSInteger)count close:(BOOL (^ )(NSInteger index, void (^handler)(UIImage *)))close;
- (MDKImageCollectionView * _Nonnull)largeForIndexWithClose:(NSString * (^)(CloseOption *option, void (^handler)(UIImage *)))close;
@end

#pragma clang diagnostic pop
