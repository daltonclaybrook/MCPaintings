//
//  AppDelegate.h
//  MCCustomPaintings
//
//  Created by Dalton Claybrook on 2/21/13.
//  Copyright (c) 2013 Claybrook Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PaintingsWindowController.h"
#import "CropWindowController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, NSTableViewDelegate, NSTableViewDataSource, PaintingsWindowControllerDelegate, CropWindowControllerDelegate, PaintingsControllerDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet NSButton *startButton;
@property (nonatomic, strong) NSArray *texturePacks;

- (IBAction)start:(id)sender;

@end
