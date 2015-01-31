//
//  BETemplateWindowController.m
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

#import "BETemplateWindowController.h"

@interface BETemplateWindowController ()

@end

@implementation BETemplateWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        //init template
        self.editingTemplate = [NSMutableArray new];
        self.templateName = @"NoName";
    }

    return self;
}

- (NSString *)windowNibName
{
    return @"BETemplateWindowController";
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    //type drag settings
    self.typeOutLineView.delegate = self;
    self.typeOutLineView.dataSource = self;
    [self.typeOutLineView registerForDraggedTypes:[NSArray arrayWithObjects:BEResourceType, nil]];
    
    //type properties settings
    self.propertiesOutLineView.delegate = self;
    self.propertiesOutLineView.dataSource = self;
    [self.propertiesOutLineView registerForDraggedTypes:[NSArray arrayWithObjects:BEPropertyType, nil]];
    
    //type selection settings
    self.selectionTable.delegate = self;
    self.selectionTable.dataSource = self;
    [self.selectionTable registerForDraggedTypes:[NSArray arrayWithObjects:BESelectionType, nil]];
    
    [self loadFromDefault:self];
}

#pragma mark

- (IBAction)addType:(id)sender {
    
    NSTreeNode *selectedItem = [self.typeOutLineView itemAtRow:[self.typeOutLineView selectedRow]];
    
    NSMutableArray *parentArray;
    
    if (selectedItem == nil) {
        parentArray = self.editingTemplate;
    }else{
        parentArray = [selectedItem.parentNode.representedObject valueForKey:@"children"];
    }
    
    //generate a name
    NSString *newResourceName = [BEProperty generateNameWithPrefix:@"newResource" inArray:parentArray];
    if (newResourceName == nil) {
        return;
    }
    
    //create new resource
    BEResource *newResource = [BEResource new];
    newResource.resourceController = self;
    newResource.parentResource = selectedItem.parentNode.representedObject;
    newResource.name = newResourceName;
    
    //add to tree
    [self.typeTreeController addObject:newResource];
    
    [self.typeOutLineView expandItem:nil expandChildren:YES];
}

- (IBAction)removeType:(id)sender {
    
    if ([self.typeOutLineView selectedRow] <0 ) {
        return;
    }
    
    NSTreeNode *selectedItem = [self.typeOutLineView itemAtRow:[self.typeOutLineView selectedRow]];
    BEResource *selectedResource = selectedItem.representedObject;
    
    [selectedResource clearReferenceValue];
    [self.typeTreeController remove:sender];

}

- (IBAction)addSubType:(id)sender {
    
    if ([self.typeOutLineView selectedRow] <0) {
        return;
    }
    
    NSTreeNode *selectedItem = [self.typeOutLineView itemAtRow:[self.typeOutLineView selectedRow]];
    NSMutableArray *parentArray = [selectedItem.representedObject valueForKey:@"children"];
    
    //generate a name
    NSString *newResourceName = [BEProperty generateNameWithPrefix:@"newResource" inArray:parentArray];
    if (newResourceName == nil) {
        return;
    }
    
    //create new resource
    BEResource *newResource = [BEResource new];
    newResource.resourceController = self;
    newResource.parentResource = selectedItem.representedObject;
    newResource.name = newResourceName;
    
    //add to tree
    [parentArray addObject:newResource];
    
    self.editingTemplate = _editingTemplate;
    [self.typeOutLineView expandItem:nil expandChildren:YES];
}

- (IBAction)copyType:(id)sender {
    
    if ([self.typeOutLineView selectedRow] <0 ) {
        return;
    }
    
    NSTreeNode *selectedItem = [self.typeOutLineView itemAtRow:[self.typeOutLineView selectedRow]];
    BEResource *selectedResource = selectedItem.representedObject;
    NSMutableArray *parentArray = [selectedItem.parentNode.representedObject valueForKey:@"children"];
    
    if (parentArray == nil) {
        parentArray = self.editingTemplate;
    }
    
    NSDictionary *resourceArchive = [selectedResource templateArchive];
    
    BEResource *newResource = [BEResource new];
    newResource.resourceController = self;
    [newResource loadTemplateArchive:resourceArchive];
    
    newResource.parentResource = selectedItem.parentNode.representedObject;
    newResource.name = [BEProperty generateNameWithPrefix:newResource.name inArray:parentArray];
    
    [newResource loadPropertyListFromArchive:resourceArchive mode:kTemplateMode];
    
    if ([self.typeOutLineView selectedRow]+1 > parentArray.count -1) {
        
        [self.typeTreeController addObject:newResource];
    }else{
        [parentArray insertObject:newResource atIndex:[self.typeOutLineView selectedRow]+1];
    }
    
    self.editingTemplate = _editingTemplate;
    [self.typeOutLineView expandItem:nil expandChildren:YES];
}

#pragma mark

- (IBAction)addProperty:(id)sender {
    
    if ([self.typeOutLineView selectedRow] <0) {
        return;
    }
    
    NSTreeNode *selectedItem = [self.propertiesOutLineView itemAtRow:[self.propertiesOutLineView selectedRow]];
    
    NSMutableArray *parentArray;
    
    if ([self.propertiesOutLineView selectedRow] <0) {
        parentArray = self.propertyTreeController.content;
    }else{
        parentArray = [selectedItem.parentNode.representedObject valueForKey:@"children"];
    }
    
    //generate a name
    NSString *newPropertyName = [BEProperty generateNameWithPrefix:@"newProperty" inArray:parentArray];
    if (newPropertyName == nil) {
        return;
    }
    
    //create new property
    BEProperty *newProperty = [BEProperty new];
    newProperty.name = newPropertyName;
    newProperty.resourceController = self;
    newProperty.mode = kTemplateMode;
    newProperty.parentProperty = selectedItem.parentNode.representedObject;
    
    //add to tree
    [self.propertyTreeController addObject:newProperty];
    
    [self.propertiesOutLineView expandItem:nil expandChildren:YES];
}

- (IBAction)removeProperty:(id)sender {
    
    if ([self.propertiesOutLineView selectedRow] < 0) {
        return;
    }
    
    //remove selected property from backtrack list
    NSTreeNode *selectedItem = [self.propertiesOutLineView itemAtRow:[self.propertiesOutLineView selectedRow]];
    BEProperty *selectedProperty = selectedItem.representedObject;
    
    [selectedProperty clearReference];
    [self.propertyTreeController remove:sender];
}

- (IBAction)addSubProperty:(id)sender {
    
    if ([self.propertiesOutLineView selectedRow] <0) {
        return;
    }
    
    NSTreeNode *selectedItem = [self.propertiesOutLineView itemAtRow:[self.propertiesOutLineView selectedRow]];
    NSMutableArray *parentArray = [selectedItem.representedObject valueForKey:@"children"];
    
    //generate a name
    NSString *newPropertyName = [BEProperty generateNameWithPrefix:@"newProperty" inArray:parentArray];
    if (newPropertyName == nil) {
        return;
    }
    
    //create new property
    BEProperty *newProperty = [BEProperty new];
    newProperty.name = newPropertyName;
    newProperty.resourceController = self;
    newProperty.mode = kTemplateMode;
    newProperty.parentProperty = selectedItem.representedObject;
    
    //add to tree
    [parentArray addObject:newProperty];
    
    self.propertyTreeController.content = _propertyTreeController.content;
    [self.propertiesOutLineView expandItem:nil expandChildren:YES];
}

- (IBAction)copyProperty:(id)sender {

    if ([self.propertiesOutLineView selectedRow] <0) {
        return;
    }
    
    NSTreeNode *selectedItem = [self.propertiesOutLineView itemAtRow:[self.propertiesOutLineView selectedRow]];
    BEProperty *selectedProperty = selectedItem.representedObject;
    NSMutableArray *parentArray = [selectedItem.parentNode.representedObject valueForKey:@"children"];
    
    BEProperty *newProperty = [BEProperty new];

    newProperty.resourceController = self;
    newProperty.mode = kTemplateMode;
    [newProperty loadArchive:selectedProperty.archiveDictionary];
    
    newProperty.parentProperty = selectedItem.parentNode.representedObject;
    newProperty.name = [BEProperty generateNameWithPrefix:newProperty.name inArray:parentArray];
    
    if ([self.propertiesOutLineView selectedRow]+1 > parentArray.count -1) {
        [self.propertyTreeController addObject:newProperty];
    }else{
        [parentArray insertObject:newProperty atIndex:[self.propertiesOutLineView selectedRow]+1];
    }
    
    self.propertyTreeController.content = _propertyTreeController.content;
    [self.propertiesOutLineView expandItem:nil expandChildren:YES];
    
}

#pragma mark
#pragma mark sheet

- (IBAction)editProperty:(id)sender {
    
    NSTreeNode *selectedItem = [self.propertiesOutLineView itemAtRow:[self.propertiesOutLineView selectedRow]];
    BEProperty *selectedProperty = selectedItem.representedObject;
    
    if (selectedProperty.propertyType.integerValue == kSelection) {
        [NSApp beginSheet:self.selectionWindow
           modalForWindow:self.window
            modalDelegate:self
           didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
              contextInfo:nil];
    }else{
        
        self.referenceController.content = _editingTemplate;
        
        [self.referenceOutLineView expandItem:nil expandChildren:YES];
        
        [self.referenceOutLineView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
        
        [NSApp beginSheet:self.referenceWindow
           modalForWindow:self.window
            modalDelegate:self
           didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
              contextInfo:nil];
    }
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:self];
}

- (IBAction)addMenuItem:(id)sender{
    
    NSMutableDictionary *newItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"unnamed",@"name", nil];
    [self.selectionController addObject:newItem];
}

- (IBAction)endSelectionSetting:(id)sender {
    
    [NSApp endSheet:self.selectionWindow];
    
    NSTreeNode *selectedItem = [self.propertiesOutLineView itemAtRow:[self.propertiesOutLineView selectedRow]];
    BEProperty *selectedProperty = selectedItem.representedObject;
    
    NSMutableString *values = [NSMutableString new];
    BOOL notAtBegin = NO;
    
    for (NSMutableDictionary *dict in selectedProperty.selection) {
        
        if (notAtBegin == NO) {
            notAtBegin = YES;
            [values appendFormat:@"%@",[dict objectForKey:@"name"]];
        }else{
            [values appendFormat:@",%@",[dict objectForKey:@"name"]];
        }
    }
    selectedProperty.value = [values copy];
}

- (IBAction)endReferenceSetting:(id)sender {
    
    [NSApp endSheet:self.referenceWindow];
    
    NSTreeNode *selectedItem = [self.propertiesOutLineView itemAtRow:[self.propertiesOutLineView selectedRow]];
    BEProperty *selectedProperty = selectedItem.representedObject;
    
    NSTreeNode *selectedReferenceItem = [self.referenceOutLineView itemAtRow:[self.referenceOutLineView selectedRow]];
    BEResource *selectedReferenceResource = selectedReferenceItem.representedObject;
    
    if (selectedProperty.allowedChildrenReference.boolValue == YES) {
        selectedProperty.value = [selectedReferenceResource.fullPath stringByAppendingPathComponent:@"*"];
    }else{
        selectedProperty.value = selectedReferenceResource.fullPath;
    }
}

- (IBAction)cancelReferenceSetting:(id)sender {
    
    [NSApp endSheet:self.referenceWindow];
}

#pragma mark
#pragma mark save & load

- (IBAction)newTemplate:(id)sender {
    
    NSAlert *alert = [NSAlert new];
    [alert setMessageText:@"Editing template will be DELETE. You cannot undo this action. Are you sure you want to do this?"];
    [alert addButtonWithTitle:@"NO"];
    [alert addButtonWithTitle:@"YES"];
    
    NSInteger result = [alert runModal];
    if (result == NSAlertFirstButtonReturn) {
        return;
    }
    
    self.editingTemplate = [NSMutableArray new];
    
}
- (IBAction)loadFromFile:(id)sender {
    
    NSAlert *alert = [NSAlert new];
    [alert setMessageText:@"Editing template will be DELETE. You cannot undo this action. Are you sure you want to do this?"];
    [alert addButtonWithTitle:@"NO"];
    [alert addButtonWithTitle:@"YES"];
    
    NSInteger result = [alert runModal];
    if (result == NSAlertFirstButtonReturn) {
        return;
    }
    
    NSOpenPanel *openPanel = [NSOpenPanel new];
    openPanel.allowedFileTypes = [NSArray arrayWithObjects:@"template",@"plist", nil];
    
    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result){
        
        if (result == NO) return;
        
        NSString *filePath = openPanel.URL.path;
        NSArray *archive;

        NSData *data = [[NSData alloc] initWithContentsOfFile:filePath];
        
        //load template data
        if ([filePath.pathExtension isEqualToString:@"template"]) {
            
            NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
            archive = [unarchiver decodeObjectForKey:@"template"];
            
            self.templateName = [unarchiver decodeObjectForKey:@"templateName"];
            
            [unarchiver finishDecoding];
            
        }else if ([filePath.pathExtension isEqualToString:@"plist"]){
            NSPropertyListFormat format;
            
            NSMutableDictionary *dictionary =
            [NSPropertyListSerialization propertyListWithData:data
                                                      options:NSPropertyListMutableContainersAndLeaves
                                                       format:&format error:nil];

            archive = [dictionary objectForKey:@"template"];
            
            self.templateName = [dictionary objectForKey:@"templateName"];
        }
        
        self.editingTemplate = [NSMutableArray new];
        [BEResource loadArchive:archive toTemplateTree:self.editingTemplate withController:self];
        
        self.editingTemplate = _editingTemplate;
        
        [self.typeOutLineView expandItem:nil expandChildren:YES];
        [self.propertiesOutLineView expandItem:nil expandChildren:YES];
    }];
}

- (IBAction)saveToFile:(id)sender {
    
    //create save panel
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setAccessoryView:self.fileExtensions];
    [savePanel setExtensionHidden:YES];
    
    [savePanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result){
        
        if (result == NO) return;
        
        if (self.templateName == nil || self.templateName.length < 1) {
            self.templateName = @"NoName";
        }
        
        //get extension
        NSString *filePath = savePanel.URL.path;
        NSString *extension = filePath.pathExtension;
        
        if ( !([extension isEqualToString:@"plist"] || [extension isEqualToString:@"template"] ) ) {
            filePath = [filePath stringByAppendingPathExtension:self.extensionMenu.title];
        }
        
        //get data
        if ([filePath.pathExtension isEqualToString:@"template"]) {
            
            NSMutableData *data = [NSMutableData new];
            NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
            
            [archiver encodeObject:[BEResource archiveFromTree:self.editingTemplate mode:kTemplateMode]
                            forKey:@"template"];
            [archiver encodeObject:self.templateName forKey:@"templateName"];
            
            [archiver finishEncoding];
            [data writeToFile:filePath atomically:NO];
            
        }else if ([filePath.pathExtension isEqualToString:@"plist"]){
            
            NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                               [BEResource archiveFromTree:self.editingTemplate mode:kTemplateMode],
                                               @"template",self.templateName,@"templateName", nil];
            
            NSData *data = [NSPropertyListSerialization dataWithPropertyList:dictionary
                                                                      format:NSPropertyListXMLFormat_v1_0
                                                                     options:NSPropertyListMutableContainersAndLeaves
                                                                       error:nil];
            
            [data writeToFile:filePath atomically:NO];
        }

    }];
    
}

- (IBAction)loadFromDefault:(id)sender {
    
    if (sender != self) {
        NSAlert *alert = [NSAlert new];
        [alert setMessageText:@"Editing template will be DELETE. You cannot undo this action. Are you sure you want to do this?"];
        [alert addButtonWithTitle:@"NO"];
        [alert addButtonWithTitle:@"YES"];
        
        NSInteger result = [alert runModal];
        if (result == NSAlertFirstButtonReturn) {
            return;
        }
    }
    
    //load template from defaut
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *data = [defaults objectForKey:@"defaultTemplate"];
    
    if (data == nil) {
        if (sender != self) {
            NSAlert *alert = [NSAlert new];
            [alert setMessageText:@"No default template fonded."];
            [alert addButtonWithTitle:@"OK"];
            [alert runModal];
            return;
        }else{
            return;
        }
    }
    
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    
    self.templateName = [unarchiver decodeObjectForKey:@"templateName"];
    NSMutableArray *templateArchive = [unarchiver decodeObjectForKey:@"template"];
    
    [unarchiver finishDecoding];
    
    if (templateArchive != nil) {
        
        self.editingTemplate = [NSMutableArray new];
        
        [BEResource loadArchive:templateArchive toTemplateTree:self.editingTemplate withController:self];
    }
    
    self.editingTemplate = _editingTemplate;
    
    [self.typeOutLineView expandItem:nil expandChildren:YES];
    [self.propertiesOutLineView expandItem:nil expandChildren:YES];

}

- (IBAction)saveToDefault:(id)sender {
    
    NSAlert *alert = [NSAlert new];
    [alert setMessageText:@"All opened documents will be changed, Some DATA may LOST. You can't undo this action. Are you sure you want to do this?"];
    [alert addButtonWithTitle:@"NO"];
    [alert addButtonWithTitle:@"YES"];
    NSInteger result = [alert runModal];
    
    if (result == NSAlertFirstButtonReturn) {
        return;
    }
    
    //save to data
    NSMutableData *data = [NSMutableData new];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    
    [archiver encodeObject:[BEResource archiveFromTree:self.editingTemplate mode:kTemplateMode] forKey:@"template"];
    [archiver encodeObject:self.templateName forKey:@"templateName"];
    
    [archiver finishEncoding];
    
    //save to userDefault
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:data forKey:@"defaultTemplate"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TemplateChanged" object:data];
}

#pragma mark


- (id)resourceAtPath:(NSString *)path{
    
    return [BEResource objectAtPath:path inArray:self.editingTemplate];
}

- (void)setSelectedTypes:(NSArray *)newSelectedTypes{
    _selectedTypes = newSelectedTypes;
    
    [self.propertiesOutLineView expandItem:nil expandChildren:YES];
}

#pragma mark
#pragma mark table drag

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
    
    [pboard declareTypes:[NSArray arrayWithObject:BESelectionType] owner:self];
    
    [pboard setData:data forType:BESelectionType];
    
    return YES;
}

- (BOOL)tableView:(NSTableView *)tableView
       acceptDrop:(id<NSDraggingInfo>)info
              row:(NSInteger)row
    dropOperation:(NSTableViewDropOperation)dropOperation{
    
    NSPasteboard *pb = [info draggingPasteboard];
    
    NSData *data = [pb dataForType:BESelectionType];
    
    NSNumber *beginIndex = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    NSMutableArray *selectionArray = self.selectionController.content;
    
    id selectedItem = [selectionArray objectAtIndex:beginIndex.integerValue];
    
    [selectionArray removeObjectAtIndex:beginIndex.integerValue];
    
    if (row >= selectionArray.count) {

        [selectionArray addObject:selectedItem];
    }else{
        
        [selectionArray insertObject:selectedItem atIndex:row];
    }
        self.selectionController.content = _selectionController.content;
    
    return YES;
}

#pragma mark
#pragma mark outline drag

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView
                  validateDrop:(id<NSDraggingInfo>)info
                  proposedItem:(id)item
            proposedChildIndex:(NSInteger)index{
    
    return NSDragOperationEvery;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView
         writeItems:(NSArray *)items
       toPasteboard:(NSPasteboard *)pasteboard{
    
    NSData *data;

    NSString *type;
    
    if (outlineView == self.typeOutLineView) {
        
        NSTreeNode *selectedItem = [self.typeOutLineView itemAtRow:[self.typeOutLineView selectedRow]];
        
        BEResource *selectedResource = selectedItem.representedObject;
        
        data = [NSKeyedArchiver archivedDataWithRootObject:[selectedResource fullPath]];
        
        type = BEResourceType;
        
    }else{
        
        NSTreeNode *selectedItem = [self.propertiesOutLineView itemAtRow:[self.propertiesOutLineView selectedRow]];
        
        BEProperty *selectedProperty = selectedItem.representedObject;
        
        data = [NSKeyedArchiver archivedDataWithRootObject:[selectedProperty fullPath]];
        
        type = BEPropertyType;
        
    }
    
    if (data != nil) {
        [pasteboard declareTypes:[NSArray arrayWithObject:type] owner:self];
        [pasteboard setData:data forType:type];
    }
    
    return YES;
}

- (BOOL) outlineView:(NSOutlineView *)outlineView
          acceptDrop:(id<NSDraggingInfo>)info
                item:(id)item
          childIndex:(NSInteger)index
{
    if (outlineView == self.typeOutLineView) {
        
        NSPasteboard *pb = [info draggingPasteboard];
        NSData *data = [pb dataForType:BEResourceType];
        NSString *objectPath = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        
        if (objectPath != nil) {
            
            NSTreeNode *selectedItem = item;
            
            NSMutableArray *newParentArray;
            
            if (selectedItem.representedObject == nil) {
                newParentArray = self.editingTemplate;
            }else{
                newParentArray = [selectedItem.representedObject valueForKey:@"children"];
            }
            
            BEResource *originResource = [self resourceAtPath:objectPath];
            if (originResource == nil) {
                return NO;
            }
            
            //check if dragged to children node
            if ([[selectedItem.representedObject valueForKey:@"fullPath"] hasPrefix:originResource.fullPath]) {
                return NO;
            }
            
            NSMutableArray *originParenArray = [originResource.parentResource valueForKey:@"children"];
            if (originParenArray == nil) {
                originParenArray = self.editingTemplate;
            }
            
            //double check
            if (originParenArray != newParentArray && [BEProperty name:originResource.name existInArray:newParentArray]) {
                NSAlert *alert = [NSAlert new];
                [alert setMessageText:@"Same name is already exist, plaese rename the resource first."];
                [alert addButtonWithTitle:@"OK"];
                [alert runModal];
                return NO;
            }
            
            //remove old object
            [originParenArray removeObject:originResource];
            
            //insert to new parent
            if (index > newParentArray.count - 1 || index <0 ) {
                [newParentArray addObject:originResource];
            }else{
                [newParentArray insertObject:originResource atIndex:index];
            }
            
            //change parent resource
            originResource.parentResource = selectedItem.representedObject;
            
            //refresh reference
            [originResource refreshReferenceValue];
            
            self.editingTemplate = _editingTemplate;
            [self.typeOutLineView expandItem:nil expandChildren:YES];
        }
    }else{
        NSPasteboard *pb = [info draggingPasteboard];
        NSData *data = [pb dataForType:BEPropertyType];
        NSString *objectPath = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        
        if (objectPath != nil) {
            
            NSTreeNode *selectedItem = item;
            BEProperty *destinationProperty = selectedItem.representedObject;
            
            NSMutableArray *newParentArray;
            
            BEResource *selectedResource = [[self.typeOutLineView itemAtRow:[self.typeOutLineView selectedRow]] valueForKey:@"representedObject"];
            
            if (destinationProperty == nil) {
                newParentArray = selectedResource.propertyList;
            }else{
                newParentArray = destinationProperty.children;
            }
            
            BEProperty *originProperty = [BEResource objectAtPath:objectPath inArray:selectedResource.propertyList];
            if (originProperty == nil) {
                return NO;
            }
            //check if dragged to children node
            if ([destinationProperty.fullPath hasPrefix:originProperty.fullPath]) {
                return NO;
            }
            
            //check if destination object receive sub property
            if (destinationProperty!=nil && destinationProperty.subEnabled == NO ) {
                return NO;
            }
            
            //double check
            NSMutableArray *originParenArray = [originProperty.parentProperty valueForKey:@"children"];
            if (originParenArray == nil) {
                originParenArray = selectedResource.propertyList;
            }
            if (originParenArray != newParentArray && [BEProperty name:originProperty.name existInArray:newParentArray]) {
                NSAlert *alert = [NSAlert new];
                [alert setMessageText:@"Same name is already exist, plaese rename the resource first."];
                [alert addButtonWithTitle:@"OK"];
                [alert runModal];
                return NO;
            }
            
            //remove old object
            [originParenArray removeObject:originProperty];
            
            //insert to new parent
            if (index > newParentArray.count - 1 || index <0 ) {
                [newParentArray addObject:originProperty];
            }else{
                [newParentArray insertObject:originProperty atIndex:index];
            }
            
            //change parent resource
            originProperty.parentProperty = destinationProperty;
            self.propertyTreeController.content = self.propertyTreeController.content;
            
            [self.propertiesOutLineView expandItem:nil expandChildren:YES];
        }
    }
    return YES;
}

@end
