//
//  BEResource.h
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

#import <Foundation/Foundation.h>

#import "BEProperty.h"

@interface BEResource : NSObject

@property (nonatomic) NSString *name;

@property (nonatomic) NSNumber *index;

@property (nonatomic) NSInteger mode;

@property (nonatomic) NSMutableArray *children;

@property (nonatomic) id parentResource;

@property (nonatomic) NSMutableArray *propertyList;

@property (nonatomic) NSMutableArray *resourceList;

@property (nonatomic) NSMutableArray *referenceBacktrackList;

@property (nonatomic) id<BEResourceController> resourceController;

- (NSString *)fullPath;

- (void)refreshReferenceValue;

- (void)clearReferenceValue;


- (NSMutableDictionary *)templateArchive;

- (NSMutableDictionary *)instanceArchive;

- (void)loadTemplateArchive:(NSDictionary *)archive;

- (void)loadInstanceArchive:(NSDictionary *)archive;

- (void)loadPropertyListFromArchive:(NSDictionary *)resourceArchive mode:(NSInteger)mode;


- (BEResource *)instanceCopy;

+ (NSMutableArray *)archiveFromTree:(NSMutableArray *)array mode:(NSInteger)mode;

+ (void)loadArchive:(NSArray *)treeArchive
     toTemplateTree:(NSMutableArray *)instanceTree
     withController:(id<BEResourceController>)controller;

+ (id)objectAtPath:(NSString *)path inArray:(NSMutableArray *)array;

@end
