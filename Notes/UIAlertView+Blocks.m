//
//  UIAlertView+Blocks.m
//  Notes
//
//  Created by Vignesh Ramesh on 18/08/15.
//  Copyright (c) 2015 vignesh. All rights reserved.
//

#import "UIAlertView+Blocks.h"

#import <objc/runtime.h>

static const void *UIAlertViewOriginalDelegateKey                   = &UIAlertViewOriginalDelegateKey;
static const void *UIAlertViewTapBlockKey                           = &UIAlertViewTapBlockKey;
static const void *UIAlertViewShouldEnableFirstOtherButtonBlockKey  = &UIAlertViewShouldEnableFirstOtherButtonBlockKey;

@implementation UIAlertView (Blocks)

+ (instancetype)showWithTitle:(NSString *)title
                      message:(NSString *)message
                        style:(UIAlertViewStyle)style
            cancelButtonTitle:(NSString *)cancelButtonTitle
            otherButtonTitles:(NSArray *)otherButtonTitles
                     tapBlock:(UIAlertViewCompletionBlock)tapBlock {
    
    NSString *firstObject = otherButtonTitles.count ? otherButtonTitles[0] : nil;
    
    UIAlertView *alertView = [[self alloc] initWithTitle:title
                                                 message:message
                                                delegate:nil
                                       cancelButtonTitle:cancelButtonTitle
                                       otherButtonTitles:firstObject, nil];
    
    alertView.alertViewStyle = style;
    
    if (otherButtonTitles.count > 1) {
        for (NSString *buttonTitle in [otherButtonTitles subarrayWithRange:NSMakeRange(1, otherButtonTitles.count - 1)]) {
            [alertView addButtonWithTitle:buttonTitle];
        }
    }
    
    if (tapBlock) {
        alertView.tapBlock = tapBlock;
    }
    
    [alertView show];
    
#if !__has_feature(objc_arc)
    return [alertView autorelease];
#else
    return alertView;
#endif
}


+ (instancetype)showWithTitle:(NSString *)title
                      message:(NSString *)message
            cancelButtonTitle:(NSString *)cancelButtonTitle
            otherButtonTitles:(NSArray *)otherButtonTitles
                     tapBlock:(UIAlertViewCompletionBlock)tapBlock {
    
    return [self showWithTitle:title
                       message:message
                         style:UIAlertViewStyleDefault
             cancelButtonTitle:cancelButtonTitle
             otherButtonTitles:otherButtonTitles
                      tapBlock:tapBlock];
}

- (void)_checkAlertViewDelegate {
    if (self.delegate != (id<UIAlertViewDelegate>)self) {
        objc_setAssociatedObject(self, UIAlertViewOriginalDelegateKey, self.delegate, OBJC_ASSOCIATION_ASSIGN);
        self.delegate = (id<UIAlertViewDelegate>)self;
    }
}

- (UIAlertViewCompletionBlock)tapBlock {
    return objc_getAssociatedObject(self, UIAlertViewTapBlockKey);
}

- (void)setTapBlock:(UIAlertViewCompletionBlock)tapBlock {
    [self _checkAlertViewDelegate];
    objc_setAssociatedObject(self, UIAlertViewTapBlockKey, tapBlock, OBJC_ASSOCIATION_COPY);
}

- (void)setShouldEnableFirstOtherButtonBlock:(BOOL(^)(UIAlertView *alertView))shouldEnableFirstOtherButtonBlock {
    [self _checkAlertViewDelegate];
    objc_setAssociatedObject(self, UIAlertViewShouldEnableFirstOtherButtonBlockKey, shouldEnableFirstOtherButtonBlock, OBJC_ASSOCIATION_COPY);
}

- (BOOL(^)(UIAlertView *alertView))shouldEnableFirstOtherButtonBlock {
    return objc_getAssociatedObject(self, UIAlertViewShouldEnableFirstOtherButtonBlockKey);
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    UIAlertViewCompletionBlock completion = alertView.tapBlock;
    
    if (completion) {
        completion(alertView, buttonIndex);
    }
    
    id originalDelegate = objc_getAssociatedObject(self, UIAlertViewOriginalDelegateKey);
    if (originalDelegate && [originalDelegate respondsToSelector:@selector(alertView:clickedButtonAtIndex:)]) {
        [originalDelegate alertView:alertView clickedButtonAtIndex:buttonIndex];
    }
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    BOOL(^shouldEnableFirstOtherButtonBlock)(UIAlertView *alertView) = alertView.shouldEnableFirstOtherButtonBlock;
    
    if (shouldEnableFirstOtherButtonBlock) {
        return shouldEnableFirstOtherButtonBlock(alertView);
    }
    
    id originalDelegate = objc_getAssociatedObject(self, UIAlertViewOriginalDelegateKey);
    if (originalDelegate && [originalDelegate respondsToSelector:@selector(alertViewShouldEnableFirstOtherButton:)]) {
        return [originalDelegate alertViewShouldEnableFirstOtherButton:alertView];
    }
    
    return YES;
}

@end
