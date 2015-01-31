//
//  BEDataController.h
//  XLibEditor
//
//  Created by Wing Xu on 13-3-13.
/*
 
 Copyright (c) 2015, Wing Xu
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 
 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 
 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 */

#define BEInstanceType @"BEInstanceType"

#import <Foundation/Foundation.h>

#import "BEResource.h"

#import "NSData+AES256.h"

@interface BEDataController : NSObject <NSTableViewDataSource , NSTableViewDelegate,BEResourceController>

@property (nonatomic) NSMutableArray *usingTemplate;
@property (nonatomic) NSString *templateName;

@property (nonatomic,weak) NSMutableArray *languageList;
@property (weak)  NSWindow *window;

@property (nonatomic) NSMutableArray *referenceTree;

@property (weak) IBOutlet NSOutlineView *typeOutlineView;
@property (weak) IBOutlet NSTableView *resourceTable;
@property (weak) IBOutlet NSOutlineView *propertyOutlineView;

@property (strong) IBOutlet NSTreeController *typeTreeController;
@property (strong) IBOutlet NSArrayController *resourceListController;
@property (strong) IBOutlet NSTreeController *propertyTreeController;

@property (weak) IBOutlet NSTreeController *typeReferenceController;
@property (weak) IBOutlet NSArrayController *instanceReferenceController;
@property (weak) IBOutlet NSOutlineView *typeReferenceOutlineView;
@property (weak) IBOutlet NSTableView *instanceReferenceTable;

@property (unsafe_unretained) IBOutlet NSPanel *referencePanel;

@property (nonatomic) NSIndexSet *selectedResources;
@property (nonatomic) NSArray *selectedTypes;

- (IBAction)addResource:(id)sender;
- (IBAction)removeResource:(id)sender;
- (IBAction)copyResource:(id)sender;
- (IBAction)insertResource:(id)sender;

- (IBAction)addProperty:(id)sender;
- (IBAction)removeProperty:(id)sender;

- (IBAction)changeTemplate:(id)sender;
- (IBAction)editProperty:(id)sender;

- (IBAction)endReferenceSetting:(id)sender;
- (IBAction)cancelReferenceSetting:(id)sender;

- (void)loadResourceFromArchive:(NSMutableArray*)archive;

- (void)defaultSettingChanged;
@end
