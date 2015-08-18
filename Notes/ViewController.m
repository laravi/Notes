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

@interface ViewController () <UITableViewDelegate, UITableViewDataSource, DBRestClientDelegate, EditorDelegate>

@end

@implementation ViewController


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
    
    self.restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
    self.restClient.delegate = self;

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

- (void)deleteNote:(NSString *)name
{
    
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
    [cell.textLabel setText:[note valueForKey:@"name"]];
    
    //configure right buttons
    cell.rightButtons = @[[MGSwipeButton buttonWithTitle:@"Delete" backgroundColor:[UIColor redColor] callback:^BOOL(MGSwipeTableCell *sender) {
        [UIAlertView showWithTitle:@"Do you really want to delete the note?" message:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@[@"Delete"] tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if (buttonIndex == 1) {
                [self deleteNote:sender.textLabel.text];
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
    [self openEditor:[note valueForKey:@"filepath"]];
}

#pragma mark DataModel methods

- (void)updateDataModel:(NSString *)name filePath:(NSString *)filepath
{
    NSManagedObject *newNote = [NSEntityDescription insertNewObjectForEntityForName:@"Notes" inManagedObjectContext:[self.appDel managedObjectContext]];
    [newNote setValue:name forKey:@"name"];
    [newNote setValue:filepath forKey:@"filepath"];
    [newNote setValue:[NSNumber numberWithBool:YES] forKey:@"shouldsync"];
    
    NSError *error = nil;
    // Save the object to persistent store
    if (![[self.appDel managedObjectContext] save:&error]) {
        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
    }
}

# pragma mark EditorDelegate

- (void)noteSavedWithText:(NSString *)text inPath:(NSString *)filepath
{
    NSString *noteName;
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"\n"
                                                                          options:NSRegularExpressionCaseInsensitive
                                                                            error:nil];
    NSTextCheckingResult *res = [regex firstMatchInString:text options:NSMatchingReportCompletion range:NSMakeRange(0, text.length)];
    if (res && (res.range.location != 0)) {
        noteName = ([text substringToIndex:res.range.location].length >10)?[text substringToIndex:10]:[text substringToIndex:res.range.location];
    } else {
        (text.length > 10)?(noteName = [text substringToIndex:10]):(noteName = text);
    }
    
    [self updateDataModel:noteName filePath:filepath];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
