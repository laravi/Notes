//
//  EditorViewController.h
//  Notes
//
//  Created by Vignesh Ramesh on 17/08/15.
//  Copyright (c) 2015 vignesh. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EditorDelegate <NSObject>

- (void)noteSavedWithText:(NSString *)text inPath:(NSString *)filepath;

@end

@interface EditorViewController : UIViewController

@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic) id<EditorDelegate> delegate;


-(id)initWithFilepath:(NSString *)filepath;

@end
