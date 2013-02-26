//
//  NameSheetWindowController.m
//  MCCustomPaintings
//
//  Created by Dalton Claybrook on 2/26/13.
//  Copyright (c) 2013 Claybrook Software, LLC. All rights reserved.
//

#import "NameSheetWindowController.h"

@interface NameSheetWindowController ()

@end

@implementation NameSheetWindowController

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
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)nameFieldReturn:(id)sender {
    [self.doneButton performClick:self];
}

- (IBAction)done:(id)sender {
    if ([self.nameField.stringValue isEqualToString:@""]) {
        [self.nameField setBackgroundColor:[NSColor redColor]];
        [self.nameField setTextColor:[NSColor whiteColor]];
    } else {
        [NSApp endSheet:self.window];
    }
}

@end
