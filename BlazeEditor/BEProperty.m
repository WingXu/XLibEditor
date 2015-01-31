//
//  BEProperty.m
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

#import "BEProperty.h"

@implementation BEProperty

-(BEProperty *) init{
    
    self = [super init];
    
    if (self) {
        _children = [NSMutableArray new];
        _selection = [NSMutableArray new];
        _allowedChildrenReference = [NSNumber numberWithBool:NO];
    }
    return self;
}

- (NSString *)fullPath{
    
    NSString *fullPath = self.name;
    id parent = self.parentProperty;
    
    while ([parent valueForKey:@"name"] != nil) {
        
        fullPath = [[parent valueForKey:@"name"] stringByAppendingPathComponent:fullPath];
        parent = [parent valueForKey:@"parentProperty"];
    }
    fullPath = [@"/" stringByAppendingPathComponent:fullPath];
    
    return fullPath;
}

#pragma mark

- (void)setValue:(NSString *)newValue{
    
    if (self.propertyType.integerValue == kInteger) {
        
        if (newValue == nil) {
            _value = newValue;
            return;
        }
        
        if ( _max !=nil && newValue.integerValue > _max.integerValue){_value = _max.stringValue; return;}
        if ( _min !=nil && newValue.integerValue < _min.integerValue){_value = _min.stringValue;return;}
        
        _value = [NSNumber numberWithInteger:newValue.integerValue].stringValue;
        
        return;
    }
    
    if (self.propertyType.integerValue == kPhoto) {
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        _value = newValue;
        
        if (newValue!= nil) {
            self.photoPath = [[defaults objectForKey:@"photoPath"] stringByAppendingString:newValue];
        }
    }
    
    if(self.propertyType.integerValue == kFloat){
        
        if (newValue == nil) {
            _value = newValue;
            return;
        }
        
        if ( _max !=nil && newValue.floatValue > _max.floatValue) {_value = _max.stringValue;return;};
        if ( _min !=nil && newValue.floatValue < _min.floatValue) {_value = _min.stringValue;return;}
        
        _value = [NSNumber numberWithFloat:newValue.floatValue].stringValue;
        
        return;
    }
    
    if (self.mode == kTemplateMode && self.propertyType.integerValue == kSelection) {
        
        [self.selection removeAllObjects];
        
        if (newValue == nil ) {
            _value = newValue;
            self.selection = _selection;
            return;
        }
        
        NSMutableArray *selectionList = [[newValue componentsSeparatedByString:@","] mutableCopy];
        
        for (NSString *name in selectionList) {
            
            if ([name rangeOfString:@"*"].location != NSNotFound) {
                
                NSAlert *alert = [NSAlert new];
                [alert addButtonWithTitle:@"OK"];
                [alert setMessageText:@"Cannot use ”*” in name."];
                [alert runModal];
                return;
            }
            [self.selection addObject:[NSMutableDictionary dictionaryWithObject:name forKey:@"name"]];
    
        self.selection = _selection;
        }
        _value = newValue;
        return;
    }

    if (self.propertyType.integerValue == kReference) {
        
        if (_value == newValue) {
            return;
        }
                
        //remove from old backtrack list
        id oldResource = [self.resourceController resourceAtPath:_value];
        NSMutableArray *oldBackTrackList = [oldResource valueForKey:@"referenceBacktrackList"];
        [oldBackTrackList removeObject:self];
        
        if (newValue == nil ) {
            _value = newValue;
            return;
        }
        
        id newResource = [self.resourceController resourceAtPath:newValue];
        
        if (newResource == nil) {
            NSAlert *alert = [NSAlert new];
            [alert addButtonWithTitle:@"OK"];
            [alert setMessageText:[NSString stringWithFormat:@"Reference not found:\n %@",newValue]];
            [alert runModal];
            return;
        }
        
        NSMutableArray *backTrackList = [newResource valueForKey:@"referenceBacktrackList"];
        
        if ([backTrackList indexOfObject:self] == NSNotFound) {
            [backTrackList addObject:self];
        }
        
        if (self.mode == kTemplateMode) {
            if ([newValue hasSuffix:@"*"]) {
                self.allowedChildrenReference = [NSNumber numberWithBool:YES];
            }else{
                self.allowedChildrenReference = [NSNumber numberWithBool:NO];
            }
        }
        
        if ([newValue hasPrefix:@"/"]) {
            _value = newValue;
        }else{
            _value = [@"/" stringByAppendingString:newValue];
        }

        return;
    }

    _value = newValue;
}

- (void)setNumberValue:(NSNumber *)newNumberValue{
    _numberValue = newNumberValue;
    self.value = _numberValue.stringValue;
}

- (void)setMax:(NSNumber *)newMax{
    
    if (newMax == nil) {
        _max = newMax;
        return;
    }
    
    if (self.propertyType.integerValue == kInteger ||
        self.propertyType.integerValue == kList) {
        _max = [NSNumber numberWithFloat:newMax.integerValue];
        
        if (_max.integerValue<1 && self.propertyType.integerValue == kList) {
            _max = [NSNumber numberWithInteger:1];
        }
    }else{
        _max = newMax;
    }
    
    if (_max != nil && _min != nil && newMax.floatValue < _min.floatValue) {
        _max = [_min copy];
    }
    
    if (self.propertyType.integerValue == kList) {
        return;
    }
    
    if (_max != nil && _value != nil && _value.floatValue > _max.floatValue) {
        
        if (self.propertyType.integerValue == kInteger) {
            _value = [NSNumber numberWithInteger:_max.integerValue].stringValue;
        }else{
            _value = [NSNumber numberWithFloat:_max.floatValue].stringValue;
        }
    }
}

- (void)setMin:(NSNumber *)newMin{
    
    if (newMin == nil) {
        _min = newMin;
        return;
    }
    
    if (self.propertyType.integerValue == kInteger ||
        self.propertyType.integerValue == kList) {
        
        _min = [NSNumber numberWithFloat:newMin.integerValue];
        
        if (_min.integerValue<1 && self.propertyType.integerValue == kList) {
            _min = [NSNumber numberWithInteger:1];
        }
        
    }else{
        _min = newMin;
    }
    
    if (_max != nil && newMin != nil && newMin.floatValue > _max.floatValue) {
        _min = [_max copy];
    }
    
    if (self.propertyType.integerValue == kList) {
        return;
    }
    
    if (_min != nil && _value != nil && _value.floatValue < _min.floatValue) {
        
        if (self.propertyType.integerValue == kInteger) {
            _value = [NSNumber numberWithInteger:_min.integerValue].stringValue;
        }else{
            _value = [NSNumber numberWithFloat:_min.floatValue].stringValue;
        }
    }
}


- (void)setName:(NSString *)newName{
    if (newName == nil || newName == _name) {
        return;
    }
    
    if (self.propertyType.integerValue == kListItem) {
        _name = newName;
        return;
    }
    
    NSMutableArray *parentArray = [self.parentProperty valueForKey:@"children"];
    
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
}

- (void)setPropertyType:(NSNumber *)newPropertyType{
    _propertyType = newPropertyType;
    
    if ([self valueEnabled] == NO) {
        self.value = nil;
    }
    
    if ([self rangeEnabled] == NO) {
        self.max = nil;
        self.min = nil;
    }
    
    if ([self subEnabled] == NO) {
        [self.children removeAllObjects];
        self.children = self.children;
        [self clearReference];
    }
    
    if (self.propertyType.integerValue != kSelection) {
        [self.selection removeAllObjects];
        self.selection = _selection;
    }
    
    if (self.propertyType.integerValue == kReference) {
        self.value = nil;
    }else{
        self.value = _value;
    }
    
    if (self.propertyType.integerValue == kInteger) {
        self.max = _max;
        self.min = _min;
    }
    
    if (self.propertyType.integerValue == kList) {
        self.value = nil;
    }
    
    self.subEnabled = _subEnabled;
}

#pragma mark

- (BOOL)valueEnabled{
    
    if (self.mode == kInstanceMode) {
        
        if (self.propertyType.integerValue == kInteger ||
            self.propertyType.integerValue == kFloat ||
            self.propertyType.integerValue == kKeyword ||
            self.propertyType.integerValue == kString ||
            self.propertyType.integerValue == kPhoto ||
            self.propertyType.integerValue == kReference) {
            return YES;
        }else{
            return NO;
        }
    }else{
        if (self.propertyType.integerValue == kInteger ||
            self.propertyType.integerValue == kFloat ||
            self.propertyType.integerValue == kKeyword ||
            self.propertyType.integerValue == kString ||
            self.propertyType.integerValue == kList ||
            self.propertyType.integerValue == kSelection ||
            self.propertyType.integerValue == kReference) {
            return YES;
        }else{
            return NO;
        }
    }
}

- (BOOL)editEnabled{
    
    if (self.mode == kInstanceMode) {
        
        if (self.propertyType.integerValue == kPhoto) {
            return YES;
        }
        
        if (self.propertyType.integerValue == kReference) {
            return YES;
        }
        
        return NO;
    }else{
        if (self.propertyType.integerValue == kSelection ||
            self.propertyType.integerValue == kReference) {
            return YES;
        }else{
            return NO;
        }
    }
    
}

- (BOOL)subEnabled{
    
    if (self.mode == kInstanceMode) {
        if (self.propertyType.integerValue == kList ||
            self.propertyType.integerValue == kListItem) {
            return YES;
        }else{
            return NO;
        }
    }else{
        if (self.propertyType.integerValue == kClassify ||
            self.propertyType.integerValue == kList) {
            return YES;
        }else{
            return NO;
        }
    }
}

- (BOOL)rangeEnabled{
    if (self.propertyType.integerValue == kInteger ||
        self.propertyType.integerValue == kFloat ||
        self.propertyType.integerValue == kList) {
        return YES;
    }else{
        return NO;
    }
}

- (BOOL)selectionEnabled{
    if (self.propertyType.integerValue == kSelection) {
        return YES;
    }else{
        return NO;
    }
}

- (BOOL)photoEnabled{
    if (self.propertyType.integerValue == kPhoto) {
        return YES;
    }else{
        return NO;
    }
}

- (BOOL)textEnabled{
    if (self.propertyType.integerValue == kKeyword ||
        self.propertyType.integerValue == kString) {
        return YES;
    }else{
        return NO;
    }
}

- (BOOL)addEnabled{
    if (self.propertyType.integerValue == kList ||
        self.propertyType.integerValue == kListItem) {
        return YES;
    }else{
        return NO;
    }
}

- (BOOL)removeEnabled{
    if (self.propertyType.integerValue == kListItem) {
        return YES;
    }else{
        return NO;
    }
}

#pragma mark

- (NSMutableDictionary *)archiveDictionary{
    
    NSMutableDictionary *archive = [NSMutableDictionary dictionaryWithObjectsAndKeys:self.name.copy,@"name", nil];

    if (self.mode == kTemplateMode) {
        
        //propertyType,value,max,min
        NSArray *propertyNames = [NSArray arrayWithObjects: @"propertyType" , @"value" , @"max" , @"min", nil];
        
        for (NSString *name in propertyNames) {
            
            id obj = [[self valueForKey:name]copy];
            
            if (obj != nil) {
                [archive setObject:obj forKey:name];
            }
        }
        
    }else{
        if (self.propertyType.integerValue == kInteger ||
            self.propertyType.integerValue == kSelection) {
            [archive setObject:[NSNumber numberWithInteger:_value.integerValue] forKey:@"value"];
            
        }else if(self.propertyType.integerValue == kFloat){
            [archive setObject:[NSNumber numberWithFloat:_value.floatValue] forKey:@"value"];
            
        }else if(self.propertyType.integerValue == kKeyword ||
                 self.propertyType.integerValue == kString ||
                 self.propertyType.integerValue == kReference){
            
            if (_value != nil) {
                
                [archive setObject:_value.copy forKey:@"value"];
                
            }
            
        }else if(self.propertyType.integerValue == kCollection){
            
            NSMutableDictionary *children = [NSMutableDictionary new];
            
            for (BEProperty *childProperty in self.children) {
                
                if (childProperty.value != nil) {
                    if (childProperty.propertyType.integerValue == kPhoto) {
                        
                        [children setObject:childProperty.value.copy
                                     forKey:childProperty.name];
                        
                    }else{
                        
                        [children setObject:childProperty.value.copy forKey:childProperty.name];
                    }
                    
                }
            }
            if (children.count>0) {
                [archive setObject:children forKey:@"children"];
            }
        }
    }
    
    //children
    if (self.propertyType.integerValue != kCollection) {
        NSMutableArray *children = [NSMutableArray new];
        
        for (BEProperty *childProperty in self.children) {
            [children addObject:[childProperty archiveDictionary]];
        }
        
        if (children.count>0) {
            [archive setObject:children forKey:@"children"];
        }
    }
    
    return archive;
}
- (void)loadArchive:(NSDictionary *)propertyArchive{
    
    if (self.mode == kTemplateMode) {
        _name = [propertyArchive objectForKey:@"name"];
        _propertyType = [propertyArchive objectForKey:@"propertyType"];
        _max = [propertyArchive objectForKey:@"max"];
        _min = [propertyArchive objectForKey:@"min"];
        
        self.value = [propertyArchive objectForKey:@"value"];
        
        NSArray *childrenArchive = [propertyArchive objectForKey:@"children"];
        
        for (NSDictionary *childArchive in childrenArchive) {
            BEProperty *newProperty = [BEProperty new];
            newProperty.resourceController = self.resourceController;
            newProperty.parentProperty = self;
            [newProperty loadArchive:childArchive];
            [self.children addObject:newProperty];
        }
    }else{
        
        id newValue = [propertyArchive objectForKey:@"value"];
        
        if (self.valueEnabled == YES && newValue != nil){
            if ([newValue isKindOfClass:[NSNumber class]]) {
                self.value = [newValue valueForKey:@"stringValue"];
            }else{
                self.value = newValue;
            }
            
        }else if(self.propertyType.integerValue == kCollection){
            
            NSDictionary *childrenArchive = [propertyArchive objectForKey:@"children"];
            if (![childrenArchive isKindOfClass:[NSDictionary class]]) {
                return;
            }
            
            for (BEProperty *subProperty in self.children) {
                newValue = [childrenArchive objectForKey:subProperty.name];
                
                if (newValue != nil && [newValue isKindOfClass:[NSString class]]) {
                    
                    subProperty.value = newValue;
                }
            }
            
        }else if(self.propertyType.integerValue == kList){
            
            NSArray *childrenArchive = [propertyArchive objectForKey:@"children"];
            if (![childrenArchive isKindOfClass:[NSArray class]]) {
                return;
            }
            
            for (NSInteger i = 0; i<childrenArchive.count; i++) {
                
                if (i>=self.children.count) {
                    [self addListItem];
                }
                
                BEProperty *child = [self.children objectAtIndex:i];
                
                [child loadArchive:[childrenArchive objectAtIndex:i]];
                
            }
        }else if(self.propertyType.integerValue == kClassify ||
                 self.propertyType.integerValue == kListItem){
            
            NSArray *childrenArchive = [propertyArchive objectForKey:@"children"];
            if (![childrenArchive isKindOfClass:[NSArray class]]) {
                return;
            }
            
            for (NSInteger i = 0; i<self.children.count; i++) {
                if (i >= childrenArchive.count) {
                    break;
                }
                
                BEProperty *child = [self.children objectAtIndex:i];
                
                [child loadArchive:[childrenArchive objectAtIndex:i]];
                
            }
        }
        //children
    }
}

- (BEProperty*)instanceCopy{
    BEProperty *newProperty = [BEProperty  new];
    
    newProperty.name = self.name;
    newProperty.propertyType = self.propertyType;
    
    newProperty.max = self.max;
    newProperty.min = self.min;
    newProperty.resourceController = self.resourceController;
    
    newProperty.mode = kInstanceMode;
    
    if (self.propertyType.integerValue == kSelection) {
        
        for (NSDictionary *name in self.selection) {
            [newProperty.selection addObject:[name objectForKey:@"name"]];
        }
        newProperty.numberValue = [NSNumber numberWithInteger:0];
        
    }else if(self.propertyType.integerValue == kReference){
        newProperty.referencePath = self.value;
        
    }else if(self.propertyType.integerValue == kString ||
             self.propertyType.integerValue == kPhoto ){
        
        //multi language support
        newProperty.propertyType = [NSNumber numberWithInteger:kCollection] ;
        
        for (NSDictionary *language in [self.resourceController languageList]) {
            NSString *name = [language objectForKey:@"name"];
            BEProperty *subProperty = [BEProperty new];
            subProperty.name = name;
            subProperty.mode = kInstanceMode;
            subProperty.propertyType = self.propertyType;
            subProperty.parentProperty = newProperty;
            
            [newProperty.children addObject:subProperty];
        }
        
    }else if(self.propertyType.integerValue == kList){
        
        newProperty.propertyTemplate = self;
        
        if (_min.integerValue >0) {
            
            for (NSInteger i = 0; i<_min.integerValue; i++) {
                [newProperty addListItem];
            }
        }
        
    }else {
        newProperty.value = self.value;
    }
    
    if (newProperty.selection.count == 0) {
        [newProperty.selection addObject:@"  "];
        [newProperty.selection addObject:@"  "];
    }
    
    //copy children
    if (self.propertyType.integerValue != kList) {
        for (BEProperty *childProperty in self.children) {
            BEProperty *subProperty = childProperty.instanceCopy;
            
            subProperty.parentProperty = newProperty;
            
            [newProperty.children addObject:subProperty];
        }
    }
    return newProperty;
}

#pragma mark

+ (BOOL)name:(NSString *)name existInArray:(NSArray *)array {
    
    BOOL exist = NO;
    
    for (id obj in array) {
        
        NSString *itemName = [obj valueForKey:@"name"];
        
        if ([name isEqualToString:itemName]) {
            exist = YES;
            break;
        }
    }
    return exist;
}

+ (NSString *) generateNameWithPrefix:(NSString *)prefix inArray:(NSMutableArray *)array{
    
    NSString *name;
    
    for (NSInteger i=0; i<1000; i++) {
        name = [prefix stringByAppendingFormat:@"%li",i];
        
        if ([BEProperty name:name existInArray:array] == NO) {
            break;
        }
        
        if (i == 999) {
            NSAlert *alert = [NSAlert new];
            
            [alert setMessageText:@"New item out of range? OH MY GOD!"];
            
            [alert addButtonWithTitle:@"OK"];
            
            [alert runModal];
            
            return nil;
        }
    }
    return name;
}

#pragma mark

- (void)renameSubPropertiesWithPrefix:(NSString*)prefix{
    
    for (NSInteger i = 0; i< self.children.count; i++) {
        BEProperty *property = [self.children objectAtIndex:i];
        
        if (prefix == nil) {
            prefix = @"";
        }
        property.name = [prefix stringByAppendingFormat:@"%li",i];
    }
}

- (void)clearReference{
    
    if (self.propertyType.integerValue == kReference && self.value != nil) {
        
        id referenceResource = [self.resourceController resourceAtPath:self.value];
        
        if (referenceResource != nil) {
            
            NSMutableArray *backtrackList = [referenceResource valueForKey:@"referenceBacktrackList"];
            
            [backtrackList removeObject:self];
        }
    }
    
    for (BEProperty *child in self.children) {
        [child clearReference];
    }
}

- (void)addListItem{
    BEProperty *newProperty = [BEProperty new];
    newProperty.mode = kInstanceMode;
    newProperty.resourceController = self.resourceController;
    newProperty.parentProperty = self;
    newProperty.propertyType = [NSNumber numberWithInteger:kListItem];
    
    //copy children
    for (BEProperty *child in self.propertyTemplate.children) {
        
        BEProperty *subProperty = child.instanceCopy;
        subProperty.parentProperty = newProperty;
        
        [newProperty.children addObject:subProperty];
    }
    
    [self.children addObject:newProperty];
    
    [self renameSubPropertiesWithPrefix:self.propertyTemplate.value];
}

@end
