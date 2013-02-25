//
//  Painting.m
//  MCCustomPaintings
//
//  Created by Dalton Claybrook on 2/24/13.
//  Copyright (c) 2013 Claybrook Software, LLC. All rights reserved.
//

#import "Painting.h"

@implementation Painting

@synthesize image = _image, rect = _rect;

- (id)initWithImage:(NSImage *)image rect:(NSRect)rect {
    self = [super init];
    if (self) {
        _image = image;
        _rect = rect;
    }
    return self;
}

- (id)initWithSourceImage:(NSImage *)source coordinates:(NSRect)rect {
    self = [super init];
    if (self) {
        NSImage *newImage = [[NSImage alloc] initWithSize:NSMakeSize(rect.size.width*16.0, rect.size.height*16.0)];
        [newImage lockFocus];
        [source drawInRect:NSMakeRect(0, 0, rect.size.width*16.0, rect.size.height*16.0) fromRect:NSMakeRect(rect.origin.x*16.0, rect.origin.y*16.0, rect.size.width*16.0, rect.size.height*16.0) operation:NSCompositeSourceOver fraction:1.0];
        [newImage unlockFocus];
        _image = newImage;
        _rect = rect;
    }
    return self;
}

@end
