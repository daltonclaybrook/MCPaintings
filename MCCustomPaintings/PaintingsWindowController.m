//
//  PaintingsWindowController.m
//  MCCustomPaintings
//
//  Created by Dalton Claybrook on 2/24/13.
//  Copyright (c) 2013 Claybrook Software, LLC. All rights reserved.
//

#import "PaintingsWindowController.h"

@interface PaintingsWindowController ()

@property (nonatomic) NSInteger currentIndex;

@end

@implementation PaintingsWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)awakeFromNib {
    self.currentIndex = 0;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    if (self.paintingsController.sourceImage) {
        self.paintingsView.painting = [[self.paintingsController.paintings objectAtIndex:self.currentIndex] image];
        [self.paintingsView setNeedsDisplay:YES];
    }
}

- (IBAction)previous:(id)sender {
    self.currentIndex--;
    if (self.currentIndex < 0) self.currentIndex = self.paintingsController.paintings.count-1;
    self.paintingsView.painting = [[self.paintingsController.paintings objectAtIndex:self.currentIndex] image];
    [self.paintingsView setNeedsDisplay:YES];
}

- (IBAction)next:(id)sender {
    self.currentIndex++;
    if (self.currentIndex >= self.paintingsController.paintings.count) self.currentIndex = 0;
    self.paintingsView.painting = [[self.paintingsController.paintings objectAtIndex:self.currentIndex] image];
    [self.paintingsView setNeedsDisplay:YES];
}

- (IBAction)select:(id)sender {
    
}

@end
