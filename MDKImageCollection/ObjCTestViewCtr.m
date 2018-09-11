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

@implementation UIViewController (test)



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
				NSInteger lastIndex = [_self indexWithIdentifer:option.lastIdentifier];
				if (option.index>0) {
					if (lastIndex == 3) {
						return nil;
					}
					lastIndex += 1;
					handler([_self imageViewWithIndex:lastIndex].image);
					return [_self identiferWithWithIndex:lastIndex];
				}else{
					if (lastIndex == 0) {
						return nil;
					}
					lastIndex -= 1;
					handler([_self imageViewWithIndex:lastIndex].image);
					return [_self identiferWithWithIndex:lastIndex];
				}
			}
		}];
		id savePhotoResultObjc = ^(MDKSavePhotoResult * result) {

			NSString *title = nil;
			NSString *message = nil;
			UIAlertAction *confirmAction = nil;
			if (result.success) {
				title = @"保存成功";
				confirmAction = [UIAlertAction actionWithTitle:@"返回" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
				}];
			}else{
				switch (result.failType) {
					case MDKSavePhotoFailTypeDenied:
					case MDKSavePhotoFailTypeRestricted:
						title = @"没有权限保存图片";
						message = @"是否跳转到设置?";
						confirmAction = [UIAlertAction actionWithTitle:@"跳转到设置" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
							NSString *urlstr =@"prefs:root=Privacy&path=PHOTOS";
							NSURL *url;
							if (UIDevice.currentDevice.systemVersion.doubleValue <10.0) {
								url = [NSURL URLWithString:urlstr];
							}else{
								url = [NSURL URLWithString:[urlstr stringByReplacingOccurrencesOfString:@"prefs" withString:@"App-Prefs"]];;
							}

							if ([UIApplication.sharedApplication canOpenURL:url]) {
								[UIApplication.sharedApplication openURL:url];
							}
						}];
						break;
					case MDKSavePhotoFailTypeSaveingFail:
						title = @"保存错误";
						message = result.error.localizedDescription;
						confirmAction = [UIAlertAction actionWithTitle:@"返回" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
						}];
					default:
						break;
				}
			}
			UIAlertController *alertCtr = [UIAlertController
										   alertControllerWithTitle:title
										   message:message //tittle和msg会分行,msg字体会小点
										   preferredStyle:UIAlertControllerStyleAlert];
			[alertCtr addAction:confirmAction];
			UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) { }];
			[alertCtr addAction:cancelAction];
			[_self.presentedViewController presentViewController:alertCtr animated:YES completion:nil];
		};
		display.disableBlurBackgroundWithBlack = true;
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
