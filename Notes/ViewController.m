//
//  ViewController.m
//  Notes
//
//  Created by Vignesh Ramesh on 12/08/15.
//  Copyright (c) 2015 vignesh. All rights reserved.
//

#import "ViewController.h"
#import "EditorViewController.h"
#import "MGSwipeTableCell.h"
#import "MGSwipeButton.h"
#import "DropboxUtil.h"

#import <DropboxSDK/DropboxSDK.h>

@interface ViewController () <UITableViewDelegate, UITableViewDataSource, EditorDelegate>

@end

@implementation ViewController
{
    DropboxUtil *util;
}

-(id)init
{
    self = [super init];
    if (self) {
        self.tableView = [UITableView new];
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        
        self.notesList = [NSMutableArray new];
        self.appDel = [[UIApplication sharedApplication] delegate];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(createNew) name:@"DropboxLinkedNotification" object:nil];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSManagedObjectContext *managedObjectContext = [self.appDel managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Notes"];
    [fetchRequest setReturnsObjectsAsFaults:NO];
    self.notesList = [[managedObjectContext executeFetchRequest:fetchRequest error:nil] mutableCopy];
    [self.tableView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"New" style:UIBarButtonItemStylePlain target:self action:@selector(createNew)];
    [item setTintColor:[UIColor blackColor]];
    self.navigationItem.rightBarButtonItem = item;
    
    self.navigationItem.title = @"Notes";
    
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.tableView];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.tableView
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1.0
                                                           constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.tableView
                                                          attribute:NSLayoutAttributeBottom
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1.0
                                                           constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.tableView
                                                          attribute:NSLayoutAttributeLeft
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeLeft
                                                         multiplier:1.0
                                                           constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.tableView
                                                          attribute:NSLayoutAttributeRight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeRight
                                                         multiplier:1.0
                                                           constant:0]];
}

// private methods

- (void)createNew
{
    if (![[DBSession sharedSession] isLinked]) {
        [[DBSession sharedSession] linkFromController:self];
        return;
    }
    [self openEditor:[[[self.appDel localDocumentsDirectory] stringByAppendingPathComponent:[self currentTimeAsString]] stringByAppendingPathExtension:@"txt"]];
}

- (void)openEditor:(NSString *)filepath
{
    EditorViewController *cont = [[EditorViewController alloc] initWithFilepath:filepath];
    cont.delegate = self;
    [self.navigationController pushViewController:cont animated:YES];
}

- (NSString *)currentTimeAsString
{
    long currentTime = (long)(NSTimeInterval)([[NSDate date] timeIntervalSince1970]);
    return [NSString stringWithFormat:@"%ld", currentTime];
}

- (void)deleteNote:(NSString *)filename
{
    NSString *path = [[self.appDel localDocumentsDirectory] stringByAppendingPathComponent:filename];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return;
    }
    NSError *error;
    if (![[NSFileManager defaultManager] removeItemAtPath:path error:&error]) {
        NSLog(@"Can't delete! %@ %@", error, [error localizedDescription]);
    }
    [self removeDataModelEntry:filename];
    
    NSManagedObjectContext *managedObjectContext = [self.appDel managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Notes"];
    [fetchRequest setReturnsObjectsAsFaults:NO];
    self.notesList = [[managedObjectContext executeFetchRequest:fetchRequest error:nil] mutableCopy];
    [self.tableView reloadData];
}

- (NSString *)getUniqueTitle:(NSString *)title
{
    int i = 0;
    NSUInteger titleCount;
    NSString *newTitle;
    do {
        i++;
        newTitle = [title stringByAppendingFormat:@"-%d",i];
        
        NSManagedObjectContext *managedObjectContext = [self.appDel managedObjectContext];
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Notes" inManagedObjectContext:managedObjectContext];
        NSError *error;
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@",@"title",newTitle];
        [fetchRequest setEntity:entityDescription];
        [fetchRequest setPredicate:predicate];
        [fetchRequest setReturnsObjectsAsFaults:NO];
        titleCount = [managedObjectContext countForFetchRequest:fetchRequest error:&error];
    } while (titleCount>0);
    return newTitle;
}

#pragma mark Tableview Delegate

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.notesList.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * reuseIdentifier = @"id";
    MGSwipeTableCell * cell = [self.tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (!cell) {
        cell = [[MGSwipeTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    }
    
    NSManagedObject *note = [self.notesList objectAtIndex:indexPath.row];
    [cell.textLabel setText:[note valueForKey:@"title"]];
    
    //configure right buttons
    cell.rightButtons = @[[MGSwipeButton buttonWithTitle:@"Delete" backgroundColor:[UIColor redColor] callback:^BOOL(MGSwipeTableCell *sender) {
        [UIAlertView showWithTitle:@"Do you really want to delete the note?" message:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@[@"Delete"] tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if (buttonIndex == 1) {
                [self deleteNote:[note valueForKey:@"filename"]];
            }
        }];
        return YES;
    }]];
    cell.rightSwipeSettings.transition = MGSwipeTransition3D;
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSManagedObject *note = [self.notesList objectAtIndex:indexPath.row];
    [self openEditor:[[self.appDel localDocumentsDirectory] stringByAppendingPathComponent:[note valueForKey:@"filename"]]];
}

#pragma mark DataModel methods

- (void)updateDataModel:(NSString *)title filename:(NSString *)filename
{
    NSManagedObjectContext *managedObjectContext = [self.appDel managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Notes" inManagedObjectContext:managedObjectContext];
    NSError *error;
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@",@"title",title];
    [fetchRequest setEntity:entityDescription];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setReturnsObjectsAsFaults:NO];
    NSUInteger titleCount = [managedObjectContext countForFetchRequest:fetchRequest error:&error];
    
    predicate = [NSPredicate predicateWithFormat:@"%K == %@",@"filename",filename];
    fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entityDescription];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setReturnsObjectsAsFaults:NO];
    NSArray *fetchDetails = [managedObjectContext executeFetchRequest:fetchRequest error:&error];

    NSManagedObject *obj;
    NSString *oldTitle;
    if (fetchDetails.count == 0) {
        //New note
        if (titleCount>0) {
            title = [self getUniqueTitle:title];
        }
        obj = [NSEntityDescription insertNewObjectForEntityForName:@"Notes" inManagedObjectContext:managedObjectContext];
        [obj setValue:title forKey:@"title"];
        [obj setValue:filename forKey:@"filename"];
        [obj setValue:nil forKey:@"rev"];
        [obj setValue:[NSNumber numberWithBool:YES] forKey:@"shouldsync"];
        
        error = nil;
        if (![[self.appDel managedObjectContext] save:&error]) {
            NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
        }
    } else {
        //Update note
        obj = [fetchDetails firstObject];
        if (titleCount == 1 && ![[obj valueForKey:@"title"] isEqualToString:title]) {
            title = [self getUniqueTitle:title];
        }
        if (![[obj valueForKey:@"title"] isEqualToString:title]) {
            oldTitle = [obj valueForKey:@"title"];
        }
        [obj setValue:title forKey:@"title"];
        [obj setValue:[NSNumber numberWithBool:YES] forKey:@"shouldsync"];
        
        error = nil;
        if (![[self.appDel managedObjectContext] save:&error]) {
            NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
        }
    }
    util = [[DropboxUtil alloc] initWithobject:obj];
    if (oldTitle) {
        [util moveNote:oldTitle];
    } else {
        [util saveNote];
    }
}

- (void)removeDataModelEntry:(NSString *)filename
{
    NSManagedObjectContext *managedObjectContext = [self.appDel managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Notes" inManagedObjectContext:managedObjectContext];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@",@"filename",filename];
    [fetchRequest setEntity:entityDescription];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setReturnsObjectsAsFaults:NO];
    
    NSError *error;
    NSArray *fetchDetails = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    if (fetchDetails.count>0) {
        NSManagedObject *note = [fetchDetails firstObject];
        util = [[DropboxUtil alloc] initWithobject:nil];
        [util deleteNote:[note valueForKey:@"title"]];
        [managedObjectContext deleteObject:note];
        error = nil;
        if (![[self.appDel managedObjectContext] save:&error]) {
            NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
        }
    }

}

# pragma mark EditorDelegate

- (void)noteSavedWithText:(NSString *)text filename:(NSString *)filename
{
    NSString *txt = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *noteTitle;
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"\n"
                                                                          options:NSRegularExpressionCaseInsensitive
                                                                            error:nil];
    NSTextCheckingResult *res = [regex firstMatchInString:txt options:NSMatchingReportCompletion range:NSMakeRange(0, txt.length)];
    if (res) {
        noteTitle = ([txt substringToIndex:res.range.location].length >10)?[txt substringToIndex:10]:[txt substringToIndex:res.range.location];
    } else {
        (txt.length > 10)?(noteTitle = [txt substringToIndex:10]):(noteTitle = txt);
    }
    
    [self updateDataModel:noteTitle filename:filename];
}

- (void)removeNote:(NSString *)filename
{
    [self deleteNote:filename];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
