//
//  Document.m
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

#import "Document.h"

@implementation Document

- (id)init
{
    self = [super init];
    if (self) {
        
        //photo path
        NSMutableDictionary *defaultPhotoPath = [NSMutableDictionary new];
        
        [defaultPhotoPath setObject:[NSHomeDirectory() stringByAppendingPathComponent:@"/Documents/"] forKey:@"photoPath"];
        
        [[NSUserDefaults standardUserDefaults] registerDefaults:defaultPhotoPath];
    }
    return self;
}

- (NSString *)windowNibName
{
    return @"Document";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    
    if (self.languageList == nil || self.languageList.count == 0) {
        self.languageList = [NSMutableArray arrayWithObjects:
                             [NSMutableDictionary dictionaryWithObjectsAndKeys:@"en",@"name", nil],
                             [NSMutableDictionary dictionaryWithObjectsAndKeys:@"zh-Hans",@"name", nil],
                             nil];
    }
    
    self.dataController.languageList = self.languageList;
    self.dataController.window  = self.mainWindow;
    
    self.dataController.resourceTable.delegate = self.dataController;
    self.dataController.resourceTable.dataSource = self.dataController;
    [self.dataController.resourceTable registerForDraggedTypes:[NSArray arrayWithObjects:BEInstanceType, nil]];
    
    self.languageTable.delegate = self;
    self.languageTable.dataSource = self;
    [self.languageTable registerForDraggedTypes:[NSArray arrayWithObjects:BELanguageItem, nil]];
    
    //check template
    
    [self.dataController.typeOutlineView expandItem:nil expandChildren:YES];
    [self.dataController.propertyOutlineView expandItem:nil expandChildren:YES];
    
    //load data
    if (self.dataArchive!=nil) {
        [self.dataController loadResourceFromArchive:self.dataArchive];
    }
    
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    if ([typeName isEqualToString:@"xlib"]) {
        
        NSMutableData *data = [NSMutableData new];
        
        NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
        
        [archiver encodeObject:[BEResource archiveFromTree:self.dataController.usingTemplate mode:kInstanceMode] forKey:@"data"];
        
        [archiver encodeObject:self.dataController.templateName forKey:@"templateName"];
        
        [archiver encodeObject:self.languageList forKey:@"languageList"];
        
        [archiver finishEncoding];
        
        return data;
        
    }else if ([typeName isEqualToString:@"plist"]){
        
        NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                    
                                    [BEResource archiveFromTree:self.dataController.usingTemplate mode:kInstanceMode],@"data",
                                    
                                    self.dataController.templateName,@"templateName",
                                    
                                    self.languageList,@"languageList",
                                    
                                    nil];
        
        NSData *data = [NSPropertyListSerialization dataWithPropertyList:dictionary
                                                                  format:NSPropertyListXMLFormat_v1_0
                                                                 options:NSPropertyListMutableContainersAndLeaves
                                                                   error:nil];
        
        return data;
    }
    
    return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    if ([typeName isEqualToString:@"xlib"]) {
        
        NSKeyedUnarchiver *Unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        
        self.templateName = [Unarchiver decodeObjectForKey:@"templateName"];
        
        self.languageList = [Unarchiver decodeObjectForKey:@"languageList"];
        
        self.dataArchive = [Unarchiver decodeObjectForKey:@"data"];
        
        [Unarchiver finishDecoding];
        
    }else if ([typeName isEqualToString:@"plist"]){
        
        NSPropertyListFormat format;
        
        NSDictionary *dictionary = [NSPropertyListSerialization propertyListWithData:data
                                                                             options:NSPropertyListMutableContainersAndLeaves
                                                                              format:&format
                                                                               error:nil];
        
        self.templateName = [dictionary objectForKey:@"TemplateName"];
        
        self.languageList = [dictionary objectForKey:@"languageList"];
        
        self.dataArchive = [dictionary objectForKey:@"data"];
    }
    
    return YES;
}

#pragma mark
#pragma mark language

- (IBAction)languageSetting:(id)sender{
   
    [NSApp beginSheet:self.languagePanel
       modalForWindow:self.mainWindow
        modalDelegate:self
       didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
          contextInfo:nil];
}

- (IBAction)endLauguageSetting:(id)sender {
    [NSApp endSheet:self.languagePanel];
    
    [self.dataController defaultSettingChanged];
}

- (IBAction)addLanguage:(id)sender {
    [self.languageList addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"newLanguage",@"name",nil]];
    
    self.languageList = _languageList;
}

- (IBAction)removeLanguage:(id)sender {
    if (self.languageTable.selectedRow<0) {
        return;
    }
    
    [self.languageList removeObjectAtIndex:self.languageTable.selectedRow];

    self.languageList = _languageList;
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:self];
}


- (NSDragOperation)tableView:(NSTableView *)tableView
                validateDrop:(id<NSDraggingInfo>)info
                 proposedRow:(NSInteger)row
       proposedDropOperation:(NSTableViewDropOperation)dropOperation{
    
    return NSDragOperationEvery;
}

- (BOOL)tableView:(NSTableView *)tableView
writeRowsWithIndexes:(NSIndexSet *)rowIndexes
     toPasteboard:(NSPasteboard *)pboard{
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:[NSNumber numberWithInteger:[rowIndexes firstIndex]]];
    
    [pboard declareTypes:[NSArray arrayWithObject:BELanguageItem] owner:self];
    
    [pboard setData:data forType:BELanguageItem];
    
    return YES;
}

- (BOOL)tableView:(NSTableView *)tableView
       acceptDrop:(id<NSDraggingInfo>)info
              row:(NSInteger)row
    dropOperation:(NSTableViewDropOperation)dropOperation{
    
    NSPasteboard *pb = [info draggingPasteboard];
    
    NSData *data = [pb dataForType:BELanguageItem];
    
    NSNumber *beginIndex = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    NSMutableArray *resourceArray = self.languageList;
    
    id selectedItem = [resourceArray objectAtIndex:beginIndex.integerValue];
    
    [resourceArray removeObjectAtIndex:beginIndex.integerValue];
    
    if (row >= resourceArray.count) {
        
        [resourceArray addObject:selectedItem];
    }else{
        
        [resourceArray insertObject:selectedItem atIndex:row];
    }
    
    self.languageList = _languageList;
    
    return YES;
}

@end
