//
//  HDConversionWindowController.m
//  MCCustomPaintings
//
//  Created by Dalton Claybrook on 3/18/13.
//  Copyright (c) 2013 Claybrook Software, LLC. All rights reserved.
//

#import "HDConversionWindowController.h"

@interface HDConversionWindowController ()

@end

@implementation HDConversionWindowController

@synthesize convert = _convert;

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
}

- (IBAction)yes:(id)sender {
    _convert = YES;
    [NSApp endSheet:self.window];
}

- (IBAction)no:(id)sender {
    _convert = NO;
    [NSApp endSheet:self.window];
}

@end
