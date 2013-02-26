//
//  PaintingsWindowController.m
//  MCCustomPaintings
//
//  Created by Dalton Claybrook on 2/24/13.
//  Copyright (c) 2013 Claybrook Software, LLC. All rights reserved.
//

#import "PaintingsWindowController.h"
#import <QuartzCore/QuartzCore.h>

@interface PaintingsWindowController ()

@property (nonatomic) NSInteger currentIndex;
@property (nonatomic, strong) PaintingsView *currentView;

@end

@implementation PaintingsWindowController

@synthesize delegate = _delegate;

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
    if (self.currentView == nil) {
        self.currentView = [[PaintingsView alloc] initWithFrame:NSMakeRect(20, 68, 400, 400)];
        [self.currentView setWantsLayer:YES];
    }
}

- (void)windowDidLoad
{
    [super windowDidLoad];    
}

- (void)showWindow:(id)sender {
    [super showWindow:sender];
    self.currentIndex = 0;
    if (self.paintingsController.sourceImage) {
        NSImage *painting = [[self.paintingsController.paintings objectAtIndex:self.currentIndex] image];
        self.sizeLabel.stringValue = [NSString stringWithFormat:@"%i x %i", (int)painting.size.width, (int)painting.size.height];
        self.currentView.painting = painting;
        [self.window.contentView addSubview:self.currentView];
        [self.currentView setNeedsDisplay:YES];
    }
}

- (void)windowWillClose:(NSNotification *)notification {
    if ([self.delegate respondsToSelector:@selector(paintingsWindowControllerWillClose:)]) {
        [self.delegate paintingsWindowControllerWillClose:self];
    }
}

- (IBAction)previous:(id)sender {
    self.currentIndex--;
    if (self.currentIndex < 0) self.currentIndex = self.paintingsController.paintings.count-1;
    NSImage *painting = [[self.paintingsController.paintings objectAtIndex:self.currentIndex] image];
    self.sizeLabel.stringValue = [NSString stringWithFormat:@"%i x %i", (int)painting.size.width, (int)painting.size.height];
    
    CGFloat duration = 0.4;
    NSView *oldView = self.currentView;
    oldView.layer.opacity = 0.0;
    self.currentView = [[PaintingsView alloc] initWithFrame:oldView.frame];
    self.currentView.painting = painting;
    [self.currentView setWantsLayer:YES];
    [self.window.contentView addSubview:self.currentView];
    
    CABasicAnimation *destinationRotation = [CABasicAnimation animationWithKeyPath:@"transform"];
    destinationRotation.duration = duration;
    destinationRotation.fromValue = [NSValue valueWithCATransform3D:CATransform3DMakeRotation(M_PI/24.0, 0.0, 0.0, 1.0)];
    destinationRotation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeRotation(0.0, 0.0, 0.0, 1.0)];
    
    CABasicAnimation *destinationOpacity = [CABasicAnimation animationWithKeyPath:@"opacity"];
    destinationOpacity.duration = duration;
    destinationOpacity.fromValue = [NSNumber numberWithFloat:0.0];
    destinationOpacity.toValue = [NSNumber numberWithFloat:1.0];
    
    CABasicAnimation *currentRotation = [CABasicAnimation animationWithKeyPath:@"transform"];
    currentRotation.duration = duration;
    currentRotation.fromValue = [NSValue valueWithCATransform3D:CATransform3DMakeRotation(0.0, 0.0, 0.0, 1.0)];
    currentRotation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeRotation(M_PI/24.0, 0.0, 0.0, -1.0)];
    
    CABasicAnimation *currentOpacity = [CABasicAnimation animationWithKeyPath:@"opacity"];
    currentOpacity.duration = duration;
    currentOpacity.fromValue = [NSNumber numberWithFloat:1.0];
    currentOpacity.toValue = [NSNumber numberWithFloat:0.0];
    
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        [oldView removeFromSuperview];
    }];
    [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
    [self.currentView.layer addAnimation:destinationRotation forKey:@"destinationRotation"];
    [self.currentView.layer addAnimation:destinationOpacity forKey:@"destinationOpacity"];
    [oldView.layer addAnimation:currentRotation forKey:@"currentRotation"];
    [oldView.layer addAnimation:currentOpacity forKey:@"currentOpacity"];
    [CATransaction commit];
}

- (IBAction)next:(id)sender {
    self.currentIndex++;
    if (self.currentIndex >= self.paintingsController.paintings.count) self.currentIndex = 0;
    NSImage *painting = [[self.paintingsController.paintings objectAtIndex:self.currentIndex] image];
    self.sizeLabel.stringValue = [NSString stringWithFormat:@"%i x %i", (int)painting.size.width, (int)painting.size.height];
    
    CGFloat duration = 0.4;
    NSView *oldView = self.currentView;
    oldView.layer.opacity = 0.0;
    self.currentView = [[PaintingsView alloc] initWithFrame:oldView.frame];
    self.currentView.painting = painting;
    [self.currentView setWantsLayer:YES];
    [self.window.contentView addSubview:self.currentView];
    
    CABasicAnimation *destinationRotation = [CABasicAnimation animationWithKeyPath:@"transform"];
    destinationRotation.duration = duration;
    destinationRotation.fromValue = [NSValue valueWithCATransform3D:CATransform3DMakeRotation(M_PI/24.0, 0.0, 0.0, -1.0)];
    destinationRotation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeRotation(0.0, 0.0, 0.0, 1.0)];
    
    CABasicAnimation *destinationOpacity = [CABasicAnimation animationWithKeyPath:@"opacity"];
    destinationOpacity.duration = duration;
    destinationOpacity.fromValue = [NSNumber numberWithFloat:0.0];
    destinationOpacity.toValue = [NSNumber numberWithFloat:1.0];
    
    CABasicAnimation *currentRotation = [CABasicAnimation animationWithKeyPath:@"transform"];
    currentRotation.duration = duration;
    currentRotation.fromValue = [NSValue valueWithCATransform3D:CATransform3DMakeRotation(0.0, 0.0, 0.0, 1.0)];
    currentRotation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeRotation(M_PI/24.0, 0.0, 0.0, 1.0)];
    
    CABasicAnimation *currentOpacity = [CABasicAnimation animationWithKeyPath:@"opacity"];
    currentOpacity.duration = duration;
    currentOpacity.fromValue = [NSNumber numberWithFloat:1.0];
    currentOpacity.toValue = [NSNumber numberWithFloat:0.0];
    
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        [oldView removeFromSuperview];
    }];
    [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
    [self.currentView.layer addAnimation:destinationRotation forKey:@"destinationRotation"];
    [self.currentView.layer addAnimation:destinationOpacity forKey:@"destinationOpacity"];
    [oldView.layer addAnimation:currentRotation forKey:@"currentRotation"];
    [oldView.layer addAnimation:currentOpacity forKey:@"currentOpacity"];
    [CATransaction commit];
}

- (IBAction)select:(id)sender {
    Painting *painting = [self.paintingsController.paintings objectAtIndex:self.currentIndex];
    if ([self.delegate respondsToSelector:@selector(paintingsWindowController:selectedPainting:)]) {
        [self.delegate paintingsWindowController:self selectedPainting:painting];
    }
}

@end
