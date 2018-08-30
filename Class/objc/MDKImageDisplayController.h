//
//  MDKImageDisplayController.h
//  MDKImageCollection
//
//  Created by mikun on 2018/8/30.
//  Copyright © 2018 mdk. All rights reserved.
//

@import MDKImageCollection;


@interface MDKImageDisplayController()

- (nonnull instancetype)initWithPhotoCount:(NSInteger)photoCount largeClose:(void (^)(MDKImageCloseOption *option, void (^handler)(UIImage *)))largeClose;

- (nonnull instancetype)initWithLargeClose:(NSString *(^)(MDKImageCloseOption *option, void (^handler)(UIImage *)))largeClose;

@end
