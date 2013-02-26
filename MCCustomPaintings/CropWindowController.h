//
//  CropController.h
//  MCCustomPaintings
//
//  Created by Dalton Claybrook on 2/21/13.
//  Copyright (c) 2013 Claybrook Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CropView.h"

@protocol CropWindowControllerDelegate;

@interface CropWindowController : NSWindowController <NSOpenSavePanelDelegate, NSWindowDelegate>

@property (nonatomic, strong) id <CropWindowControllerDelegate> delegate;
@property (weak) IBOutlet CropView *cropView;
@property (weak) IBOutlet NSButton *preserveBorderBox;
@property (nonatomic, strong) NSImage *image;
@property (nonatomic) NSSize cropSize;

- (IBAction)cropImage:(id)sender;

@end

@protocol CropWindowControllerDelegate <NSObject>

@optional
- (void)cropWindowController:(CropWindowController *)cwc didCropImage:(NSImage *)image preserveBorder:(BOOL)preserve;
- (void)cropWindowControllerWillClose:(CropWindowController *)cwc;

@end