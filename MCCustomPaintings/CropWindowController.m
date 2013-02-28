//
//  CropController.m
//  MCCustomPaintings
//
//  Created by Dalton Claybrook on 2/21/13.
//  Copyright (c) 2013 Claybrook Software, LLC. All rights reserved.
//

#import "CropWindowController.h"

@interface CropWindowController ()

- (void)setAspectRatioFromCropSize:(NSSize)cropSize;

@end

@implementation CropWindowController

@synthesize delegate = _delegate, image = _image, cropView = _cropView, cropSize = _cropSize;

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
//    if (self.image && !self.cropView.image) {
//        [self.cropView setImage:self.image];
//        [self.cropView setNeedsDisplay:YES];
//    } else {
//        NSOpenPanel *openPanel = [[NSOpenPanel alloc] init];
//        [openPanel setDelegate:self];
//        [openPanel setAllowedFileTypes:[NSArray arrayWithObjects:@"jpg", @"jpeg", @"png", @"tiff", @"bmp", nil]];
//        [openPanel setTitle:@"Select a New Image"];
//        [openPanel runModal];
//    }
}

- (void)windowWillClose:(NSNotification *)notification {
    if ([self.delegate respondsToSelector:@selector(cropWindowControllerWillClose:)]) {
        [self.delegate cropWindowControllerWillClose:self];
    }
}

- (void)showWindow:(id)sender {
    [super showWindow:sender];
    
    NSOpenPanel *openPanel = [[NSOpenPanel alloc] init];
    [openPanel setDelegate:self];
    [openPanel setAllowedFileTypes:[NSArray arrayWithObjects:@"jpg", @"jpeg", @"png", @"tiff", @"bmp", nil]];
    [openPanel setTitle:@"Select a New Image"];
    
    if ([openPanel runModal] == NSFileHandlingPanelCancelButton) {
        [self close];
    }
}

- (void)setImage:(NSImage *)image {
    _image = image;
    [self.cropView setImage:image];
    [self setAspectRatioFromCropSize:self.cropSize];
    [self.cropView setNeedsDisplay:YES];
}

- (IBAction)cropImage:(id)sender {
    if ([self.delegate respondsToSelector:@selector(cropWindowController:didCropImage:preserveBorder:)]) {
        NSRect cropRect = [self.cropView adjustedCropRect];
    
        NSImage *finalImage = [[NSImage alloc] initWithSize:NSMakeSize(self.cropSize.width*16.0, self.cropSize.height*16.0)];
        [finalImage lockFocus];
        [self.cropView.image drawInRect:NSMakeRect(0, 0, finalImage.size.width, finalImage.size.height) fromRect:cropRect operation:NSCompositeSourceOver fraction:1.0];
        [finalImage unlockFocus];
    
        [self.delegate cropWindowController:self didCropImage:finalImage preserveBorder:self.preserveBorderBox.state];
    }
}

#pragma mark Private Methods

- (void)setAspectRatioFromCropSize:(NSSize)cropSize {
    if (cropSize.width/cropSize.height == 1.0) {
        [self.cropView setAspectRatio:AspectRatio1to1];
    } else if (cropSize.width/cropSize.height == 1.0/2.0) {
        [self.cropView setAspectRatio:AspectRatio1to2];
    } else if (cropSize.width/cropSize.height == 2.0/1.0) {
        [self.cropView setAspectRatio:AspectRatio2to1];
    } else if (cropSize.width/cropSize.height == 4.0/3.0) {
        [self.cropView setAspectRatio:AspectRatio4to3];
    }
}

#pragma mark NSOpenSavePanelDelegate Methods

- (BOOL)panel:(id)sender validateURL:(NSURL *)url error:(NSError *__autoreleasing *)outError {
    NSImage *newImage = [[NSImage alloc] initWithContentsOfURL:url];
    if (newImage) {
        self.image = newImage;
        return YES;
    }
    return NO;
}

@end
