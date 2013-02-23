//
//  CropController.m
//  MCCustomPaintings
//
//  Created by Dalton Claybrook on 2/21/13.
//  Copyright (c) 2013 Claybrook Software, LLC. All rights reserved.
//

#import "CropController.h"

@interface CropController ()

@end

@implementation CropController

@synthesize image = _image, cropView = _cropView;

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    if (self.image && !self.cropView.image) {
        [self.cropView setImage:self.image];
        [self.cropView setNeedsDisplay:YES];
    }
    [self.cropView setAspectRatio:AspectRatio4to3];
}

- (void)setImage:(NSImage *)image {
    _image = image;
    [self.cropView setImage:image];
    [self.cropView setNeedsDisplay:YES];
}

@end
