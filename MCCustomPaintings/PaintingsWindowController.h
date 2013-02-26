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

@protocol PaintingsWindowControllerDelegate;

@interface PaintingsWindowController : NSWindowController <NSWindowDelegate>

@property (nonatomic, strong) id <PaintingsWindowControllerDelegate> delegate;
@property (nonatomic, strong) PaintingsController *paintingsController;
//@property (weak) IBOutlet PaintingsView *paintingsView;
@property (weak) IBOutlet NSTextField *sizeLabel;

- (IBAction)previous:(id)sender;
- (IBAction)next:(id)sender;
- (IBAction)select:(id)sender;

@end

@protocol PaintingsWindowControllerDelegate <NSObject>

@optional
- (void)paintingsWindowController:(PaintingsWindowController *)pwc selectedPainting:(Painting *)painting;
- (void)paintingsWindowControllerWillClose:(PaintingsWindowController *)pwc;

@end
