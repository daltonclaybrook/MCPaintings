//
//  CropController.h
//  MCCustomPaintings
//
//  Created by Dalton Claybrook on 2/21/13.
//  Copyright (c) 2013 Claybrook Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CropView.h"

@interface CropController : NSWindowController

@property (weak) IBOutlet CropView *cropView;
@property (nonatomic, strong) NSImage *image;

@end
