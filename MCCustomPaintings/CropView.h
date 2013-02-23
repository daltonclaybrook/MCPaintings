//
//  CropView.h
//  MCCustomPaintings
//
//  Created by Dalton Claybrook on 2/21/13.
//  Copyright (c) 2013 Claybrook Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
    AspectRatio1to1,
    AspectRatio1to2,
    AspectRatio2to1,
    AspectRatio4to3
} AspectRatio;

@interface CropView : NSView

@property (nonatomic, strong) NSImage *image;
@property (nonatomic) AspectRatio aspectRatio;

@end
