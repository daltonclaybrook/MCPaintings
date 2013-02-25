//
//  Painting.h
//  MCCustomPaintings
//
//  Created by Dalton Claybrook on 2/24/13.
//  Copyright (c) 2013 Claybrook Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Painting : NSObject

@property (nonatomic, strong) NSImage *image;
//Rect is measured by 16px x 16px blocks
//e.g. {{1, 2}, {4, 4}} equates to {{16, 32}, {64, 64}} 
@property (nonatomic) NSRect rect;

- (id)initWithImage:(NSImage *)image rect:(NSRect)rect;
- (id)initWithSourceImage:(NSImage *)source coordinates:(NSRect)rect;

@end
