//
//  BETemplateWindowController.h
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

#import <Cocoa/Cocoa.h>
#import "BEResource.h"

#define BEResourceType @"BEResourceType"
#define BEPropertyType @"BEPropertyType"
#define BESelectionType @"BESelectionType"


@interface BETemplateWindowController : NSWindowController
<NSOutlineViewDelegate,
NSOutlineViewDataSource,
NSTableViewDataSource,
NSTableViewDelegate,
BEResourceController>

@property (nonatomic) NSMutableArray *editingTemplate;
@property (nonatomic) NSString *templateName;
@property (nonatomic) NSArray *selectedTypes;

@property (weak) IBOutlet NSOutlineView *typeOutLineView;
@property (weak) IBOutlet NSOutlineView *propertiesOutLineView;
@property (strong) IBOutlet NSTreeController *typeTreeController;
@property (strong) IBOutlet NSTreeController *propertyTreeController;

@property (weak) IBOutlet NSTableView *selectionTable;
@property (weak) IBOutlet NSOutlineView *referenceOutLineView;
@property (strong) IBOutlet NSArrayController *selectionController;
@property (strong) IBOutlet NSTreeController *referenceController;

@property (strong) IBOutlet NSPanel *referenceWindow;
@property (strong) IBOutlet NSPanel *selectionWindow;

@property (strong) IBOutlet NSView *fileExtensions;
@property (weak) IBOutlet NSPopUpButton *extensionMenu;

//type
- (IBAction)addType:(id)sender;
- (IBAction)removeType:(id)sender;
- (IBAction)addSubType:(id)sender;
- (IBAction)copyType:(id)sender;

//property
- (IBAction)addProperty:(id)sender;
- (IBAction)removeProperty:(id)sender;
- (IBAction)addSubProperty:(id)sender;
- (IBAction)copyProperty:(id)sender;

//sheet
- (IBAction)editProperty:(id)sender;
- (IBAction)addMenuItem:(id)sender;
- (IBAction)endSelectionSetting:(id)sender;
- (IBAction)endReferenceSetting:(id)sender;
- (IBAction)cancelReferenceSetting:(id)sender;

//save & load
- (IBAction)newTemplate:(id)sender;
- (IBAction)loadFromFile:(id)sender;
- (IBAction)saveToFile:(id)sender;
- (IBAction)loadFromDefault:(id)sender;
- (IBAction)saveToDefault:(id)sender;

//
- (id)resourceAtPath:(NSString *)path;

@end
