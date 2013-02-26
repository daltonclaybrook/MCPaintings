//
//  NameSheetWindowController.h
//  MCCustomPaintings
//
//  Created by Dalton Claybrook on 2/26/13.
//  Copyright (c) 2013 Claybrook Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NameSheetWindowController : NSWindowController

@property (weak) IBOutlet NSTextField *nameField;
@property (weak) IBOutlet NSButton *doneButton;

- (IBAction)nameFieldReturn:(id)sender;
- (IBAction)done:(id)sender;

@end
