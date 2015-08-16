//
//  EditorViewController.h
//  Notes
//
//  Created by Vignesh Ramesh on 17/08/15.
//  Copyright (c) 2015 vignesh. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EditorViewController : UIViewController

@property (nonatomic, strong) UITextView *textView;


-(id)initWithFilepath:(NSString *)filepath;

@end
