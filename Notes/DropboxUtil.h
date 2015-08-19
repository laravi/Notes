//
//  DropboxUtil.h
//  Notes
//
//  Created by Vignesh Ramesh on 18/08/15.
//  Copyright (c) 2015 vignesh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DropboxSDK/DropboxSDK.h>
#import <CoreData/CoreData.h>

@interface DropboxUtil : NSObject <DBRestClientDelegate>

@property (nonatomic, strong) DBRestClient *restClient;

-(id)initWithobject:(NSManagedObject *)obj;
- (void)saveNote;
- (void)deleteNote:(NSString *)title;
- (void)moveNote:(NSString *)title;

@end
