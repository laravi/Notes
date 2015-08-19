//
//  EditorViewController.m
//  Notes
//
//  Created by Vignesh Ramesh on 17/08/15.
//  Copyright (c) 2015 vignesh. All rights reserved.
//

#import "EditorViewController.h"

@interface EditorViewController () <UITextViewDelegate>

@end

@implementation EditorViewController
{
    BOOL isModified;
    NSLayoutConstraint *bottomConstraint;
}

-(id)initWithFilepath:(NSString *)filepath
{
    self = [super init];
    if (self) {
        isModified = NO;
        self.textView = [UITextView new];
        self.textView.delegate = self;
        self.filePath = filepath;
        self.textView.text = [NSString stringWithContentsOfFile:filepath encoding:NSUTF8StringEncoding error:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpKeyboardNotificationHandlers];
    
//    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(save)];
//    [item setTintColor:[UIColor blackColor]];
//    self.navigationItem.rightBarButtonItem = item;
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"< Back" style:UIBarButtonItemStylePlain target:self action:@selector(closeEditor)];
    [item setTintColor:[UIColor blackColor]];
    self.navigationItem.leftBarButtonItem = item;
    
    self.textView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.textView];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.textView
                                                          attribute:NSLayoutAttributeLeft
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeLeft
                                                         multiplier:1.0
                                                           constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.textView
                                                          attribute:NSLayoutAttributeRight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeRight
                                                         multiplier:1.0
                                                           constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.textView
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1.0
                                                           constant:0]];
    bottomConstraint = [NSLayoutConstraint constraintWithItem:self.textView
                                                    attribute:NSLayoutAttributeBottom
                                                    relatedBy:NSLayoutRelationEqual
                                                       toItem:self.view
                                                    attribute:NSLayoutAttributeBottom
                                                   multiplier:1.0
                                                     constant:0];
    [self.view addConstraint:bottomConstraint];
}

// private methods

- (void)save
{
    if (self.textView.text.length > 0 && isModified) {
        [self.textView.text writeToFile:self.filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        [self.delegate noteSavedWithText:self.textView.text filename:[self.filePath lastPathComponent]];
        isModified = NO;
    } else if (self.textView.text.length == 0) {
        [self.delegate removeNote:[self.filePath lastPathComponent]];
    }
    
}

- (void)closeEditor
{
    [self save];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)setUpKeyboardNotificationHandlers {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(keyboardWillShow:)
                   name:UIKeyboardWillShowNotification object:nil];
    [center addObserver:self selector:@selector(keyboardWillHide:)
                   name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    
    NSDictionary *userInfo = [notification userInfo];
    
    NSValue *aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    
    CGRect keyboardRect = [aValue CGRectValue];
    keyboardRect = [self.view convertRect:keyboardRect fromView:nil];
    
    NSValue *animationDurationValue = [userInfo objectForKey:
                                       UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    bottomConstraint.constant = -keyboardRect.size.height;
    
    [UIView animateWithDuration:animationDuration animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {

    NSDictionary *userInfo = [notification userInfo];
    
    NSValue *animationDurationValue = [userInfo objectForKey:
                                       UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    bottomConstraint.constant = 0;
    
    [UIView animateWithDuration:animationDuration animations:^{
        [self.view layoutIfNeeded];
    }];
}

#pragma mark textview delegate

-(void)textViewDidChange:(UITextView *)textView
{
    if (!isModified) {
        isModified = YES;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
