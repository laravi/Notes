//
//  UIAlertView+Blocks.h
//  Notes
//
//  Created by Vignesh Ramesh on 18/08/15.
//  Copyright (c) 2015 vignesh. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^UIAlertViewBlock) (UIAlertView * alertView);
typedef void (^UIAlertViewCompletionBlock) (UIAlertView * alertView, NSInteger buttonIndex);

@interface UIAlertView (Blocks)

+ (instancetype)showWithTitle:(NSString *)title
                      message:(NSString *)message
                        style:(UIAlertViewStyle)style
            cancelButtonTitle:(NSString *)cancelButtonTitle
            otherButtonTitles:(NSArray *)otherButtonTitles
                     tapBlock:(UIAlertViewCompletionBlock)tapBlock;

+ (instancetype)showWithTitle:(NSString *)title
                      message:(NSString *)message
            cancelButtonTitle:(NSString *)cancelButtonTitle
            otherButtonTitles:(NSArray *)otherButtonTitles
                     tapBlock:(UIAlertViewCompletionBlock)tapBlock;

@property (copy, nonatomic) UIAlertViewCompletionBlock tapBlock;
@property (copy, nonatomic) BOOL(^shouldEnableFirstOtherButtonBlock)(UIAlertView * alertView);

@end
