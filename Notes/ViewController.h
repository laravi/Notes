//
//  ViewController.h
//  Notes
//
//  Created by Vignesh Ramesh on 12/08/15.
//  Copyright (c) 2015 vignesh. All rights reserved.
//

#import "AppDelegate.h"

@interface ViewController : UIViewController

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *notesList;
@property (nonatomic, strong) AppDelegate *appDel;

@end

