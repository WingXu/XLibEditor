//
//  BEResource.m
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

#import "BEResource.h"

@implementation BEResource

-(BEResource *) init{
    self = [super init];
    if (self) {
        
        _children = [NSMutableArray new];
        
        _propertyList = [NSMutableArray new];
        
        _resourceList = [NSMutableArray new];
        
        _referenceBacktrackList = [NSMutableArray new];
    }
    return self;
}

- (void)setName:(NSString *)newName{
    if (newName == nil) {
        return;
    }
    
    NSMutableArray *parentArray;
    if (self.mode == kInstanceMode) {
        parentArray = [self.parentResource valueForKey:@"resourceList"];
    }else{
        parentArray = [self.parentResource valueForKey:@"children"];
    }
    
    NSAlert *alert = [NSAlert new];
    [alert setMessageText:@"This name is aready exist."];
    [alert addButtonWithTitle:@"OK"];
    
    //duplicate check
    if ([BEProperty name:newName existInArray:parentArray]) {
        
        [alert runModal];
        return;
    }
    //illegal check
    if ([newName rangeOfString:@"/"].location != NSNotFound) {
        
        [alert setMessageText:@"Cannot use ”/” in name."];
        [alert runModal];
        return;
    }
    if ([newName rangeOfString:@"*"].location != NSNotFound) {
        
        [alert setMessageText:@"Cannot use ”*” in name."];
        [alert runModal];
        return;
    }
    if ([newName rangeOfString:@"."].location != NSNotFound) {
        
        [alert setMessageText:@"Cannot use ”.” in name."];
        [alert runModal];
        return;
    }
    _name = newName;
    
    [self refreshReferenceValue];
}

- (NSString *)fullPath{
    
    NSString *fullPath;
    
    id parent = self.parentResource;
    
    while ([parent valueForKey:@"name"] != nil) {
        
        fullPath = [[parent valueForKey:@"name"] stringByAppendingPathComponent:fullPath];
        
        parent = [parent valueForKey:@"parentResource"];
    }
    
    fullPath = [@"/" stringByAppendingPathComponent:fullPath];
    
    if (self.mode == kInstanceMode) {
        fullPath = [fullPath stringByAppendingPathExtension:self.name];
    }else{
        fullPath = [fullPath stringByAppendingPathComponent:self.name];
    }
    
    return fullPath;
}

- (void)refreshReferenceValue{
    
    for (BEProperty *property in self.referenceBacktrackList) {
        
        if (property.allowedChildrenReference.boolValue == YES) {
            
            property.value = [self.fullPath stringByAppendingPathComponent:@"*"];
        }else{
            property.value = self.fullPath;
        }
    }
    
    for (BEResource *childResource in self.children) {
        [childResource refreshReferenceValue];
    }
}

- (void)clearReferenceValue{
    
    for (BEProperty *property in self.referenceBacktrackList) {
            property.value = nil;
    }
    
    for (BEResource *childResource in self.children) {
        [childResource clearReferenceValue];
    }
}

#pragma mark

- (NSMutableDictionary *)templateArchive{
    
    NSMutableDictionary *archive = [NSMutableDictionary dictionaryWithObjectsAndKeys:self.name,@"name", nil];
    
    //property
    NSMutableArray *propertyListArchive = [NSMutableArray new];
    for (BEProperty *property in self.propertyList) {
        [propertyListArchive addObject:property.archiveDictionary];
    }
    [archive setObject:propertyListArchive forKey:@"propertyList"];
    
    //children
    if (self.children.count>0) {
        NSMutableArray *children = [NSMutableArray new];
        for (BEResource *resource in self.children) {
            [children addObject:resource.templateArchive];
        }
        
        [archive setObject:children forKey:@"children"];
    }
    
    return archive;
}

- (void)loadTemplateArchive:(NSDictionary *)archive{
    
    _name = [archive objectForKey:@"name"];
    NSMutableArray *childrenArchive = [archive objectForKey:@"children"];
    
    for (NSDictionary *childArchive in childrenArchive) {
        BEResource *newResource = [BEResource new];
        newResource.resourceController = self.resourceController;
        newResource.parentResource = self;
        [newResource loadTemplateArchive:childArchive];
        [self.children addObject:newResource];
    }
}

- (NSMutableDictionary *)instanceArchive{
    
    NSMutableDictionary *archive = [NSMutableDictionary dictionaryWithObjectsAndKeys:self.name,@"name", nil];
    
    //resourceList
    NSMutableArray *resouceList = [NSMutableArray new];
    for (BEResource *resource in self.resourceList) {
        
        NSMutableDictionary *resourceArchive = resource.templateArchive;
        
        if (resource.index != nil) {
            
            [resourceArchive setObject:resource.index forKey:@"index"];
        }
        
        [resouceList addObject:resourceArchive];
    }
    
    [archive setObject:resouceList forKey:@"resource"];
    
    //children
    if (self.children.count>0) {
        NSMutableArray *children = [NSMutableArray new];
        for (BEResource *resource in self.children) {
            [children addObject:resource.instanceArchive];
        }
        
        [archive setObject:children forKey:@"children"];
    }

    return archive;
}

- (void)loadInstanceArchive:(NSDictionary *)archive{
    
    NSArray *resourceList = [archive objectForKey:@"resource"];
    
    //resource
    for (NSDictionary *resourceArchive in resourceList) {
        
        BEResource *newResource = [BEResource new];
        
        newResource.resourceController = self.resourceController;
        newResource.parentResource = self;
        newResource.mode = kInstanceMode;
        newResource.name = [resourceArchive objectForKey:@"name"];
        newResource.index = [resourceArchive objectForKey:@"index"];
        
        [self.resourceList addObject:newResource];
    }
    
    //children
    NSArray *children = [archive objectForKey:@"children"];
    for (NSInteger i = 0 ; i< self.children.count; i++) {
        if (i>= children.count) {
            break;
        }
        
        NSDictionary *instanceArchive = [children objectAtIndex:i];
        BEResource *type = [self.children objectAtIndex:i];
        
        [type loadInstanceArchive:instanceArchive];
    }
}

- (void)loadPropertyListFromArchive:(NSDictionary *)archive mode:(NSInteger)mode{
    
    //template
    if (mode == kTemplateMode) {
        //load propertylist for self
        NSArray *propertyListArchive = [archive objectForKey:@"propertyList"];
        
        for (NSDictionary *propertyArchive in propertyListArchive) {
            BEProperty *newProperty = [BEProperty new];
            newProperty.resourceController = self.resourceController;
            newProperty.mode = mode;
            newProperty.parentProperty = nil;
            
            [newProperty loadArchive:propertyArchive];
            
            [self.propertyList addObject:newProperty];
        }
        
        //load propertylist for children
        NSMutableArray *childrenArchive = [archive objectForKey:@"children"];
        
        for (NSInteger i = 0; i < childrenArchive.count; i++) {
            if (i>= childrenArchive.count) {
                break;
            }
            NSDictionary *resourceArchive = [childrenArchive objectAtIndex:i];
            BEResource *resource = [self.children objectAtIndex:i];
            
            [resource loadPropertyListFromArchive:resourceArchive mode:mode];
        }
        
    //instance
    }else{
        NSArray *resourceList = [archive objectForKey:@"resource"];
        
        //resource
        for (NSInteger i = 0 ; i<self.resourceList.count; i++) {
            if (i>= resourceList.count) {
                break;
            }
            
            NSDictionary *resourceArchive = [resourceList objectAtIndex:i];
            BEResource *resource = [self.resourceList objectAtIndex:i];
            
            NSArray *propertyListArchive = [resourceArchive objectForKey:@"propertyList"];
            
            //property
            for (NSInteger x = 0; x<self.propertyList.count; x++) {
                
                BEProperty *newProperty = [[self.propertyList objectAtIndex:x]instanceCopy];
                
                if (x < propertyListArchive.count) {
                    [newProperty loadArchive:[propertyListArchive objectAtIndex:x]];
                }
                
                [resource.propertyList addObject:newProperty];
            }
        }
        
        //children
        NSArray *children = [archive objectForKey:@"children"];
        for (NSInteger i = 0 ; i< self.children.count; i++) {
            if (i >=children.count) {
                return;
            }
            
            NSDictionary *instanceArchive = [children objectAtIndex:i];
            
            BEResource *type = [self.children objectAtIndex:i];
            
            [type loadPropertyListFromArchive:instanceArchive mode:kInstanceMode];
        }
    }
}

#pragma mark

- (BEResource*)instanceCopy{
    BEResource *newResource = [BEResource new];
    
    NSString *name = [BEProperty generateNameWithPrefix:self.name inArray:self.resourceList];
    
    if (name == nil) {
        return nil;
    }
    
    newResource.name = name;
    newResource.resourceController = self.resourceController;
    newResource.parentResource = self;
    newResource.mode = kInstanceMode;
    
    //copy propertylist in instance mode
    for (BEProperty *property in self.propertyList) {
        [newResource.propertyList addObject:property.instanceCopy];
    }
    
    return newResource;
}

+ (NSMutableArray *)archiveFromTree:(NSMutableArray *)array mode:(NSInteger)mode{
    
    NSMutableArray *archive = [NSMutableArray new];
    
    if (mode == kTemplateMode) {
        for (BEResource *resource in array) {
            [archive addObject:[resource templateArchive]];
        }
    }else{
        for (BEResource *resource in array) {
            [archive addObject:[resource instanceArchive]];
        }
    }
    return archive;
}

+ (void)loadArchive:(NSArray *)treeArchive
     toTemplateTree:(NSMutableArray *)instanceTree
     withController:(id<BEResourceController>)controller{
    
    //create resource tree
    for (NSDictionary *resourceArchive in treeArchive) {
        BEResource *newResource = [BEResource new];
        newResource.resourceController = controller;
        newResource.parentResource = nil;
        [newResource loadTemplateArchive:resourceArchive];
        
        [instanceTree addObject:newResource];
    }
    
    //load properties for each resource
    for (NSInteger i = 0; i < treeArchive.count; i++) {
        if (i>=treeArchive.count) {
            break;
        }
        
        NSDictionary *resourceArchive = [treeArchive objectAtIndex:i];
        BEResource *resource = [instanceTree objectAtIndex:i];
        
        [resource loadPropertyListFromArchive:resourceArchive mode:kTemplateMode];
    }
}

#pragma mark

+ (id)objectAtPath:(NSString *)path inArray:(NSMutableArray *)array{
    
    id objectAtPath;
    
    NSMutableArray *SeparatedPath = [[path componentsSeparatedByString:@"/"] mutableCopy];
    
    if ([[SeparatedPath objectAtIndex:0] isEqualToString:@""]) {
        [SeparatedPath removeObjectAtIndex:0];
    }
    
    NSMutableArray *childrenArray = array;
    
    for (NSString *pathCompenent in SeparatedPath) {
        
        if ([pathCompenent isEqualToString:@"*"]) {
            break;
        }
        BOOL exist = NO;
        
        for (id resource in childrenArray) {
            
            if ([[resource valueForKey:@"name"] isEqualToString:pathCompenent]) {
                
                exist = YES;
                
                objectAtPath = resource;
                
                childrenArray = [resource valueForKey:@"children"];
                
                break;
            }
        }
        if (exist == NO) {
            return nil;
        }
    }
    return objectAtPath;
}

@end
