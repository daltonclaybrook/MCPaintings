//
//  PaintingsWindowController.h
//  MCCustomPaintings
//
//  Created by Dalton Claybrook on 2/24/13.
//  Copyright (c) 2013 Claybrook Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PaintingsController.h"
#import "PaintingsView.h"

@interface PaintingsWindowController : NSWindowController

@property (nonatomic, strong) PaintingsController *paintingsController;
@property (weak) IBOutlet PaintingsView *paintingsView;

- (IBAction)previous:(id)sender;
- (IBAction)next:(id)sender;
- (IBAction)select:(id)sender;

@end
