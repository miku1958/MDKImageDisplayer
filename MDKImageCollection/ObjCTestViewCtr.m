//
//  ObjCTestViewCtr.m
//  MDKImageCollection
//
//  Created by mikun on 2018/8/25.
//  Copyright © 2018 mdk. All rights reserved.
//

#import "ObjCTestViewCtr.h"
#import "MDKImageCollection-Swift.h"

@interface ObjCTestViewCtr ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView0;

@property (weak, nonatomic) IBOutlet UIImageView *imageView1;
@property (weak, nonatomic) IBOutlet UIImageView *imageView2;

@property (weak, nonatomic) IBOutlet UIImageView *imageView3;
@end

@implementation ObjCTestViewCtr

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
	__weak typeof(self) _self = self;
	CGPoint point = [touches.anyObject locationInView:self.view];
	UIImageView *view = (id)[self.view hitTest:point withEvent:event];
	NSString *identifer = [self identifierWithView:view];
	if (identifer) {
		MDKImageDisplayController *display = [[MDKImageDisplayController alloc]initWithLargeClose:^NSString * (MDKImageCloseOption * option, void (^ handler)(UIImage * image)) {
			if (!option.lastIdentifier) {
				handler(view.image);
				return identifer;
			}else{
				NSInteger lastIndex = [self indexWithIdentifer:option.lastIdentifier];
				if (option.index>0) {
					if (lastIndex == 3) {
						return nil;
					}
					lastIndex += 1;
					handler([self imageViewWithIndex:lastIndex].image);
					return [self identiferWithWithIndex:lastIndex];
				}else{
					if (lastIndex == 0) {
						return nil;
					}
					lastIndex -= 1;
					handler([self imageViewWithIndex:lastIndex].image);
					return [self identiferWithWithIndex:lastIndex];
				}
			}
		}];
		display.registerAppearSourecView = ^UIView *{
			return view;
		};
		display.registerDismissTargetView = ^UIView * (MDKImageCloseOption * option) {
			return [_self imageViewWithIndex:[_self indexWithIdentifer:option.lastIdentifier]];
		};
		[self presentViewController:display animated:YES completion:nil];
	}

}


- (NSString *)identifierWithView:(UIView *)view{
	if (view == _imageView0) {
		return [self identiferWithWithIndex:0];
	}
	if (view == _imageView1) {
		return [self identiferWithWithIndex:1];
	}
	if (view == _imageView2) {
		return [self identiferWithWithIndex:2];
	}
	if (view == _imageView3) {
		return [self identiferWithWithIndex:3];
	}
	return nil;
}
- (NSString *)identiferWithWithIndex:(NSInteger)index{
	return @(index+9000).description;
}
- (NSInteger)indexWithIdentifer:(NSString *)identifer{
	return identifer.integerValue - 9000;
}
- (UIImageView *)imageViewWithIndex:(NSInteger)index{
	return (id)[self valueForKey:[NSString stringWithFormat:@"_imageView%ld",(long)index]];
}
@end
