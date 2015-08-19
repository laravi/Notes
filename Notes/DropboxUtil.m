//
//  DropboxUtil.m
//  Notes
//
//  Created by Vignesh Ramesh on 18/08/15.
//  Copyright (c) 2015 vignesh. All rights reserved.
//

#import "DropboxUtil.h"
#import "AppDelegate.h"

@implementation DropboxUtil
{
    NSManagedObject *mManagedObjModel;
}

-(id)initWithobject:(NSManagedObject *)obj
{
    self = [super init];
    if (self) {
        self.restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        self.restClient.delegate = self;
        mManagedObjModel = obj;
    }
    return self;
}

- (void)saveNote
{
    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [self.restClient uploadFile:[[mManagedObjModel valueForKey:@"title"] stringByAppendingPathExtension:@"txt"] toPath:@"/" withParentRev:[mManagedObjModel valueForKey:@"rev"] fromPath:[[delegate localDocumentsDirectory] stringByAppendingPathComponent:[mManagedObjModel valueForKey:@"filename"]]];
}

- (void)deleteNote:(NSString *)title
{
    [self.restClient deletePath:[NSString stringWithFormat:@"/%@.txt",title]];
}

- (void)moveNote:(NSString *)title
{
    [self.restClient moveFrom:[NSString stringWithFormat:@"/%@.txt",title] toPath:[NSString stringWithFormat:@"/%@.txt",[mManagedObjModel valueForKey:@"title"]]];
}

#pragma mark Dropbox Delegate Methods

-(void)restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath from:(NSString *)srcPath metadata:(DBMetadata *)metadata
{
    [mManagedObjModel setValue:metadata.rev forKey:@"rev"];
    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    NSError *error = nil;
    if (![[delegate managedObjectContext] save:&error]) {
        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
    }
}

-(void)restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error
{
    NSLog(@"upload error");
}

-(void)restClient:(DBRestClient *)client deletedPath:(NSString *)path
{
    
}

-(void)restClient:(DBRestClient *)client deletePathFailedWithError:(NSError *)error
{
    NSLog(@"delete error");
}

-(void)restClient:(DBRestClient *)client movedPath:(NSString *)from_path to:(DBMetadata *)result
{
    [mManagedObjModel setValue:result.rev forKey:@"rev"];
    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    NSError *error = nil;
    if (![[delegate managedObjectContext] save:&error]) {
        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
    }
}

-(void)restClient:(DBRestClient *)client movePathFailedWithError:(NSError *)error
{
    NSLog(@"Move error");
}

@end
