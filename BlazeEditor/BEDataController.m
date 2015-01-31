//
//  BEDataController.m
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

#import "BEDataController.h"

@implementation BEDataController

- (BEDataController *)init
{
    self = [super init];
    if (self) {
        
        [self initTemplate];
        
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(defaultSettingChanged) name:@"TemplateChanged" object:nil];
    }
    return self;
}

#pragma mark
- (IBAction)addResource:(id)sender {
    
    if (self.typeOutlineView.selectedRow < 0) {
        return;
    }
    
    BEResource *selectedType = [self selectedType];
    
    if (selectedType.propertyList.count == 0) {
        return;
    }
    
    BEResource *newResouce = selectedType.instanceCopy;
    
    if (newResouce == nil) {
        return;
    }
    
    [self.resourceListController addObject:newResouce];
    
    [self reindex];
    
    [self.propertyOutlineView expandItem:nil expandChildren:YES];
}

- (IBAction)removeResource:(id)sender {
    
    if (self.resourceTable.selectedRow < 0) {
        return;
    }
    
    BEResource *selectedResource = [self.resourceListController.content objectAtIndex:self.resourceTable.selectedRow];
    
    [selectedResource clearReferenceValue];
    
    [self.resourceListController remove:sender];
    
}

- (IBAction)copyResource:(id)sender {
    
    if (self.resourceTable.selectedRow < 0) {
        return;
    }
    BEResource *selectedType = [self selectedType];
    
    BEResource *selectedResource = [self selectedResource];
    NSDictionary *resourceArchive = selectedResource.templateArchive;
    
    BEResource *newResource = [BEResource new];
    newResource.resourceController = self;
    newResource.parentResource = [self selectedType];
    newResource.mode = kInstanceMode;
    
    NSString *name = [resourceArchive objectForKey:@"name"];
    
    newResource.name = [BEProperty generateNameWithPrefix:name inArray:[self selectedType].children];
    
    NSArray *propertyListArchive = [resourceArchive objectForKey:@"propertyList"];
    
    //property
    for (NSInteger x = 0; x<selectedType.propertyList.count; x++) {
        BEProperty *newProperty = [[selectedType.propertyList objectAtIndex:x]instanceCopy];
        
        [newProperty loadArchive:[propertyListArchive objectAtIndex:x]];
        
        [newResource.propertyList addObject:newProperty];
    }
    
    if (self.resourceTable.selectedRow+1 >= [self.resourceListController.content count]) {
        [self.resourceListController.content addObject:newResource];
    }else{
        [self.resourceListController.content insertObject:newResource atIndex:self.resourceTable.selectedRow+1];
    }
    
    [self reindex];
    
    self.resourceListController.content = _resourceListController.content;
}

- (IBAction)insertResource:(id)sender {
    
    if (self.resourceTable.selectedRow < 0) {
        return;
    }
    
    BEResource *selectedType = [self selectedType];
    
    BEResource *newResouce = selectedType.instanceCopy;
    
    if (newResouce == nil) {
        return;
    }
    
    [selectedType.resourceList insertObject:newResouce atIndex:self.resourceTable.selectedRow];
    
    self.resourceListController.content = _resourceListController.content;
    
    [self reindex];
    
    [self.propertyOutlineView expandItem:nil expandChildren:YES];
}

#pragma mark
- (IBAction)addProperty:(id)sender {
    
    BEProperty *selectedProperty = [self selectedProperty];
    if (selectedProperty.propertyType.integerValue == kListItem) {
        selectedProperty = selectedProperty.parentProperty;
    }
    
    BEProperty *propertyTemplate = selectedProperty.propertyTemplate;
    
    if (propertyTemplate.max.integerValue>0 && selectedProperty.children.count >= propertyTemplate.max.integerValue) {
        return;
    }
    
    [selectedProperty addListItem];
    
    self.propertyTreeController.content = _propertyTreeController.content;
    [self.propertyOutlineView expandItem:NO expandChildren:YES];
}

- (IBAction)removeProperty:(id)sender {
    
    BEProperty *selectedProperty = [self selectedProperty];
    if (selectedProperty.propertyType.integerValue == kListItem) {
        selectedProperty = selectedProperty.parentProperty;
    }
    
    BEProperty *propertyTemplate = selectedProperty.propertyTemplate;
    
    if (propertyTemplate.min.integerValue>0 && selectedProperty.children.count <= propertyTemplate.min.integerValue) {
        return;
    }
    
    [selectedProperty clearReference];
    
    [self.propertyTreeController remove:sender];
}

- (IBAction)changeTemplate:(id)sender {
}

#pragma mark

- (IBAction)editProperty:(id)sender {
    
    BEProperty *selectedProperty = [self selectedProperty];
    
    if (selectedProperty.propertyType.integerValue == kPhoto) {
        
        NSOpenPanel *openPanel = [NSOpenPanel new];
        openPanel.allowedFileTypes = [NSArray arrayWithObjects:@"png", nil];
        openPanel.prompt = @"Select";
        
        //set default path
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        NSString *resourcePath = [defaults objectForKey:@"photoPath"];
        
        NSString *panelPath = [@"file://localhost/" stringByAppendingString:resourcePath];
        
        [openPanel setDirectoryURL:[NSURL URLWithString:panelPath]];
        
        [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result){
            
            if (result == NO) return;
            
            if ([openPanel.URL.path hasPrefix:resourcePath]) {
                
                selectedProperty.value = [openPanel.URL.path substringFromIndex:resourcePath.length];;
            }
        }];
        
    }else{
        //reference
        BEProperty *selectedProperty = [self selectedProperty];
        
        BEResource *referenceType = [BEResource objectAtPath:selectedProperty.referencePath inArray:self.usingTemplate];
        
        if (referenceType == nil) {
            return;
        }
        
        self.referenceTree = [NSMutableArray arrayWithObject:referenceType];
        [self.typeReferenceOutlineView expandItem:nil expandChildren:YES];
        
        [NSApp beginSheet:self.referencePanel
           modalForWindow:self.window
            modalDelegate:self
           didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
              contextInfo:nil];
    }
}

- (IBAction)endReferenceSetting:(id)sender {
    
    if (self.instanceReferenceTable.selectedRow < 0) {
        return;
    }
    
    //get resource fullpath
    BEResource *selectedResource = [self.instanceReferenceController.content objectAtIndex:[self.instanceReferenceTable selectedRow]];
    
    BEProperty *selectedProperty = [self selectedProperty];
    
    selectedProperty.value = selectedResource.fullPath;
    
    [NSApp endSheet:self.referencePanel];
}

- (IBAction)cancelReferenceSetting:(id)sender {
    
    [NSApp endSheet:self.referencePanel];
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:self];
}

#pragma mark
-(void)reindex{
    
    BEResource *resource;
    
    NSMutableArray *edtingList = self.resourceListController.content;
    
    for (int i = 0; i<edtingList.count; i++) {
        
        resource = [edtingList objectAtIndex:i];
        
        resource.index = [NSNumber numberWithInteger:i];
    }
    self.resourceListController.content = _resourceListController.content;
}

- (id)resourceAtPath:(NSString *)path{
    if ([path rangeOfString:@"."].location != NSNotFound) {
        
        NSArray *separatedPath = [path componentsSeparatedByString:@"."];
        
        if (separatedPath.count >2) {
            return nil;
        }

        BEResource *type = [BEResource objectAtPath:[separatedPath objectAtIndex:0] inArray:self.usingTemplate];
        
        return [BEResource objectAtPath:[separatedPath objectAtIndex:1] inArray:type.resourceList];
        
    }else{
        return [BEResource objectAtPath:path inArray:self.usingTemplate];
    }
}

- (BEProperty*)selectedProperty{
    
    NSTreeNode *selectedItem = [self.propertyOutlineView itemAtRow:[self.propertyOutlineView selectedRow]];
    
    return selectedItem.representedObject;
}

- (BEResource*)selectedType{
    
    NSTreeNode *selectedItem = [self.typeOutlineView itemAtRow:[self.typeOutlineView selectedRow]];
    BEResource *selectedType = selectedItem.representedObject;
    
    return selectedType;
}

- (void)setSelectedResources:(NSIndexSet *)newSelectedResources{
    _selectedResources = newSelectedResources;
    
    [self.propertyOutlineView expandItem:nil expandChildren:YES];
}

- (void)setSelectedTypes:(NSArray *)newSelectedTypes{
    _selectedTypes = newSelectedTypes;
    
    [self.propertyOutlineView expandItem:nil expandChildren:YES];
}

#pragma mark

- (BEResource*)selectedResource{
    BEResource *selectedItem = [self.resourceListController.content objectAtIndex:[self.resourceTable selectedRow]];

    return selectedItem;
}

- (void)loadResourceFromArchive:(NSMutableArray*)archive{
    //load resource for each type
    for (NSInteger i = 0 ; i< self.usingTemplate.count; i++) {
        if (i >= archive.count) {
            break;
        }
        
        NSDictionary *instanceArchive = [archive objectAtIndex:i];
        BEResource *type = [self.usingTemplate objectAtIndex:i];
        
        [type loadInstanceArchive:instanceArchive];
    }
    
    //load properties for each type
    for (NSInteger i = 0 ; i< self.usingTemplate.count; i++) {
        if (i >= archive.count) {
            break;
        }
        
        NSDictionary *instanceArchive = [archive objectAtIndex:i];
        BEResource *type = [self.usingTemplate objectAtIndex:i];

        [type loadPropertyListFromArchive:instanceArchive mode:kInstanceMode];
    }
    
    self.usingTemplate = _usingTemplate;
    
    [self.typeOutlineView expandItem:nil expandChildren:YES];
    [self.propertyOutlineView expandItem:nil expandChildren:YES];
}

- (void)defaultSettingChanged{
    NSMutableArray *archive = [BEResource archiveFromTree:self.usingTemplate mode:kInstanceMode];
    
    [self initTemplate];
    
    [self loadResourceFromArchive:archive];
}

- (void)initTemplate{
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *data = [defaults objectForKey:@"defaultTemplate"];
    
    if (data == nil) {
        
        self.templateName = @"No default template fonded.";
        
    }else{
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        
        self.templateName = [unarchiver decodeObjectForKey:@"templateName"];
        NSMutableArray *templateArchive = [unarchiver decodeObjectForKey:@"template"];
        
        [unarchiver finishDecoding];
        
        if (templateArchive != nil) {
            
            self.usingTemplate = [NSMutableArray new];
            
            [BEResource loadArchive:templateArchive toTemplateTree:self.usingTemplate withController:self];
            
            self.usingTemplate = _usingTemplate;
            
            [self.typeOutlineView expandItem:nil expandChildren:YES];
        }
    }
}

#pragma mark

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
    
    [pboard declareTypes:[NSArray arrayWithObject:BEInstanceType] owner:self];
    
    [pboard setData:data forType:BEInstanceType];
    
    return YES;
}

- (BOOL)tableView:(NSTableView *)tableView
       acceptDrop:(id<NSDraggingInfo>)info
              row:(NSInteger)row
    dropOperation:(NSTableViewDropOperation)dropOperation{
    
    NSPasteboard *pb = [info draggingPasteboard];
    
    NSData *data = [pb dataForType:BEInstanceType];
    
    NSNumber *beginIndex = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    NSMutableArray *resourceArray = self.resourceListController.content;
    
    id selectedItem = [resourceArray objectAtIndex:beginIndex.integerValue];
    
    [resourceArray removeObjectAtIndex:beginIndex.integerValue];
    
    if (row >= resourceArray.count) {
        
        [resourceArray addObject:selectedItem];
    }else{
        
        [resourceArray insertObject:selectedItem atIndex:row];
    }
    
    [self reindex];
    
    self.resourceListController.content = _resourceListController.content;
    
    return YES;
}

@end
