//
//  CropView.m
//  MCCustomPaintings
//
//  Created by Dalton Claybrook on 2/21/13.
//  Copyright (c) 2013 Claybrook Software, LLC. All rights reserved.
//

#import "CropView.h"
#import <QuartzCore/QuartzCore.h>

static CGFloat padding = 20.0f;
static CGFloat minRectWidth = 50.0f;
static CGFloat startingRectWidth = 200.0f;
static CGFloat cornerDotRadius = 5.0f;

static NSString *kTrackingAreaKey = @"trackingAreaKey";
static NSString *trackingAreaCorner = @"corner";
static NSString *trackingAreaRect = @"rect";

@interface CropView ()

@property (nonatomic, strong) NSArray *corners;
@property (nonatomic, strong) NSBezierPath *cropBlackPath;
@property (nonatomic, strong) NSBezierPath *cropWhitePath;
@property (nonatomic) NSRect imageRect;
@property (nonatomic) NSRect cropRect;
@property (nonatomic) BOOL resizing;
@property (nonatomic) BOOL moving;
@property (nonatomic) NSPoint startMovePoint;
@property (nonatomic) NSRect startMoveRect;
@property (nonatomic) BOOL mouseOverCorner;
@property (nonatomic) BOOL mouseOverRect;
@property (nonatomic) NSUInteger draggingCornerIndex;

- (void)setupCropRect;
- (void)refreshTrackingAreasWithMousePoint:(NSPoint)mousePoint;
- (void)resizeRectWithPoint:(NSPoint)point;
- (void)moveRectWithPoint:(NSPoint)point;
- (void)recreateCornersWithRect:(NSRect)rect;
- (NSSize)fixedBoxFromDynamic:(NSSize)box;

@end

@implementation CropView

@synthesize image = _image, aspectRatio = _aspectRatio;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        
    }
    
    return self;
}

- (void)awakeFromNib {
    _resizing = NO;
    _mouseOverCorner = NO;
}

- (void)drawRect:(NSRect)dirtyRect
{
    if (self.image) {
        [self.image drawInRect:self.imageRect fromRect:NSMakeRect(0, 0, self.image.size.width, self.image.size.height) operation:NSCompositeSourceOver fraction:1.0];
        
        if ((self.cropBlackPath == nil) || (self.cropWhitePath == nil) || (self.corners == nil)) {
            [self setupCropRect];
        }
        [[NSColor whiteColor] set];
        [self.cropWhitePath stroke];
        
        [[NSColor blackColor] set];
        if (self.resizing || self.moving) {
//            [[NSColor colorWithCalibratedRed:102.0/255.0 green:102.0/255.0 blue:153.0/255.0 alpha:1.0] setFill];
            [[NSColor colorWithCalibratedWhite:0.9 alpha:1.0] setFill];
        } else {
//            [[NSColor colorWithCalibratedRed:153.0/255.0 green:153.0/255.0 blue:187.0/255.0 alpha:1.0] setFill];
            [[NSColor whiteColor] setFill];
        }
        [self.cropBlackPath stroke];
        for (NSBezierPath *corner in self.corners) {
            [corner stroke];
            [corner fill];
        }
    }
}

- (void)setImage:(NSImage *)image {
    _image = image;
    CGSize paddedViewSize = CGSizeMake(self.bounds.size.width-(padding*2.0), self.bounds.size.height-(padding * 2.0));
    NSRect newRect = NSZeroRect;
    if (self.image.size.width/self.image.size.height >= paddedViewSize.width/paddedViewSize.height) {
        //Width is greater than ratio
        newRect.size = NSMakeSize(paddedViewSize.width, (self.image.size.height * paddedViewSize.width/self.image.size.width));
    } else {
        //Height is greater
        newRect.size = NSMakeSize((self.image.size.width * paddedViewSize.height/self.image.size.height), paddedViewSize.height);
    }
    newRect.origin = NSMakePoint((paddedViewSize.width-newRect.size.width)/2.0 + padding, (paddedViewSize.height-newRect.size.height)/2.0 + padding);
    self.imageRect = newRect;
}

- (void)setAspectRatio:(AspectRatio)aspectRatio {
    _aspectRatio = aspectRatio;
    [self setupCropRect];
}

- (NSRect)adjustedCropRect {
    NSRect cropRect = NSMakeRect(self.cropRect.origin.x-self.imageRect.origin.x, self.cropRect.origin.y-self.imageRect.origin.y, self.cropRect.size.width, self.cropRect.size.height);
    CGFloat modifier = self.image.size.width/self.imageRect.size.width;
    
    return NSMakeRect(cropRect.origin.x*modifier, cropRect.origin.y*modifier, cropRect.size.width*modifier, cropRect.size.height*modifier);
}

#pragma mark Mouse Tracking

- (void)mouseEntered:(NSEvent *)theEvent {
    NSDictionary *info = (NSDictionary *)theEvent.userData;
    if ([[info objectForKey:kTrackingAreaKey] isEqualToString:trackingAreaCorner]) {
        [[NSCursor crosshairCursor] set];
        self.mouseOverCorner = YES;
    } else {
        if (!self.mouseOverCorner) [[NSCursor openHandCursor] set];
        self.mouseOverRect = YES;
    }
}

- (void)mouseExited:(NSEvent *)theEvent {
    NSDictionary *info = (NSDictionary *)theEvent.userData;
    if ([[info objectForKey:kTrackingAreaKey] isEqualToString:trackingAreaCorner]) {
        if (!self.mouseOverRect) {
            [[NSCursor arrowCursor] set];
        } else {
            [[NSCursor openHandCursor] set];
        }
        self.mouseOverCorner = NO;
    } else {
        if (!self.mouseOverCorner) {
            [[NSCursor arrowCursor] set];
        } else {
            [[NSCursor crosshairCursor] set];
        }
        self.mouseOverRect = NO;
    }
}

- (void)cursorUpdate:(NSEvent *)event {
    //Needed for some reason.
}

- (void)mouseDown:(NSEvent *)theEvent {
    NSPoint mousePoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    if (self.mouseOverCorner) {
        for (int i=0; i<self.corners.count; i++) {
            if (NSPointInRect(mousePoint, [[self.corners objectAtIndex:i] controlPointBounds])) {
                self.draggingCornerIndex = i;
                break;
            }
        }
        self.resizing = YES;
        for (NSTrackingArea *area in self.trackingAreas) {
            [self removeTrackingArea:area];
        }
        [self setNeedsDisplay:YES];
    } else if (self.mouseOverRect) {
        [[NSCursor closedHandCursor] set];
        self.moving = YES;
        self.startMovePoint = mousePoint;
        self.startMoveRect = self.cropRect;
        for (NSTrackingArea *area in self.trackingAreas) {
            [self removeTrackingArea:area];
        }
        [self setNeedsDisplay:YES];
    }
}

- (void)mouseDragged:(NSEvent *)theEvent {
    NSPoint mousePoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    if (self.resizing) {
        [self resizeRectWithPoint:mousePoint];
    } else if (self.moving) {
        [self moveRectWithPoint:mousePoint];
    }
}

- (void)mouseUp:(NSEvent *)theEvent {
    if (self.resizing) {
        self.resizing = NO;
        NSPoint mousePoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        [self refreshTrackingAreasWithMousePoint:mousePoint];
        [self setNeedsDisplay:YES];
    } else if (self.moving) {
        self.moving = NO;
        NSPoint mousePoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        [self refreshTrackingAreasWithMousePoint:mousePoint];
        [self setNeedsDisplay:YES];
    }
}

#pragma mark Private Methods

- (void)setupCropRect {    
    CGFloat rectWidth = startingRectWidth;
    CGFloat rectHeight = 0;
    switch (self.aspectRatio) {
        case AspectRatio1to1: {
            rectHeight = rectWidth;
            break;
        } case AspectRatio1to2: {
            rectHeight = rectWidth*2.0;
            break;
        } case AspectRatio2to1: {
            rectHeight = rectWidth/2.0;
            break;
        } case AspectRatio4to3: {
            rectHeight = rectWidth/4.0*3.0;
            break;
        }
    }
    
    CGFloat dashes[] = {
        5.0, 5.0
    };
    
    NSRect cropRect = NSMakeRect(0, 0, (int)rectWidth, (int)rectHeight);
    if (self.imageRect.size.width < rectWidth) {
        cropRect.size = NSMakeSize((int)self.imageRect.size.width, (int)(self.imageRect.size.width/rectWidth*rectHeight));
    } else if (self.imageRect.size.height < rectHeight) {
        cropRect.size = NSMakeSize((int)(self.imageRect.size.height/rectHeight*rectWidth), (int)self.imageRect.size.height);
    }
    cropRect.origin = NSMakePoint((int)(self.imageRect.origin.x + (self.imageRect.size.width-cropRect.size.width)/2.0f) + 0.5f, (int)(self.imageRect.origin.y + (self.imageRect.size.height-cropRect.size.height)/2.0f) + 0.5f);
    self.cropRect = cropRect;
    
    if (self.cropBlackPath == nil) {
        self.cropBlackPath = [NSBezierPath bezierPathWithRect:self.cropRect];
        [self.cropBlackPath setLineWidth:1.0];
        [self.cropBlackPath setLineDash:dashes count:2 phase:0.0];
    } else {
        [self.cropBlackPath removeAllPoints];
        [self.cropBlackPath appendBezierPath:[NSBezierPath bezierPathWithRect:self.cropRect]];
    }
    
    if (self.cropWhitePath == nil) {
        self.cropWhitePath = [NSBezierPath bezierPathWithRect:self.cropRect];
        [self.cropWhitePath setLineWidth:1.0];
        [self.cropBlackPath setLineDash:dashes count:2 phase:5.0];
    } else {
        [self.cropWhitePath removeAllPoints];
        [self.cropWhitePath appendBezierPath:[NSBezierPath bezierPathWithRect:self.cropRect]];
    }
    
    NSBezierPath *corner1 = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(self.cropRect.origin.x-cornerDotRadius, self.cropRect.origin.y-cornerDotRadius, cornerDotRadius*2.0, cornerDotRadius*2.0)];
    [corner1 setLineWidth:1.0f];
    NSBezierPath *corner2 = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(self.cropRect.origin.x+self.cropRect.size.width-cornerDotRadius, self.cropRect.origin.y-cornerDotRadius, cornerDotRadius*2.0, cornerDotRadius*2.0)];
    [corner2 setLineWidth:1.0f];
    NSBezierPath *corner3 = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(self.cropRect.origin.x+self.cropRect.size.width-cornerDotRadius, self.cropRect.origin.y+self.cropRect.size.height-cornerDotRadius, cornerDotRadius*2.0, cornerDotRadius*2.0)];
    [corner3 setLineWidth:1.0f];
    NSBezierPath *corner4 = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(self.cropRect.origin.x-cornerDotRadius, self.cropRect.origin.y+self.cropRect.size.height-cornerDotRadius, cornerDotRadius*2.0, cornerDotRadius*2.0)];
    [corner4 setLineWidth:1.0f];
    self.corners = [[NSArray alloc] initWithObjects:corner1, corner2, corner3, corner4, nil];
    
    NSPoint base = [self.window convertScreenToBase:[NSEvent mouseLocation]];
    NSPoint mousePoint = [self convertPoint:base fromView:nil];
    [self refreshTrackingAreasWithMousePoint:mousePoint];
}

- (void)refreshTrackingAreasWithMousePoint:(NSPoint)mousePoint {
    NSTrackingArea *corner1Area = [[NSTrackingArea alloc] initWithRect:NSMakeRect(self.cropRect.origin.x-cornerDotRadius, self.cropRect.origin.y-cornerDotRadius, cornerDotRadius*2.0, cornerDotRadius*2.0) options:NSTrackingMouseEnteredAndExited+NSTrackingCursorUpdate+NSTrackingActiveInKeyWindow owner:self userInfo:[NSDictionary dictionaryWithObject:trackingAreaCorner forKey:kTrackingAreaKey]];
    
    NSTrackingArea *corner2Area = [[NSTrackingArea alloc] initWithRect:NSMakeRect(self.cropRect.origin.x+self.cropRect.size.width-cornerDotRadius, self.cropRect.origin.y-cornerDotRadius, cornerDotRadius*2.0, cornerDotRadius*2.0) options:NSTrackingMouseEnteredAndExited+NSTrackingCursorUpdate+NSTrackingActiveInKeyWindow owner:self userInfo:[NSDictionary dictionaryWithObject:trackingAreaCorner forKey:kTrackingAreaKey]];
    
    NSTrackingArea *corner3Area = [[NSTrackingArea alloc] initWithRect:NSMakeRect(self.cropRect.origin.x+self.cropRect.size.width-cornerDotRadius, self.cropRect.origin.y+self.cropRect.size.height-cornerDotRadius, cornerDotRadius*2.0, cornerDotRadius*2.0) options:NSTrackingMouseEnteredAndExited+NSTrackingCursorUpdate+NSTrackingActiveInKeyWindow owner:self userInfo:[NSDictionary dictionaryWithObject:trackingAreaCorner forKey:kTrackingAreaKey]];
    
    NSTrackingArea *corner4Area = [[NSTrackingArea alloc] initWithRect:NSMakeRect(self.cropRect.origin.x-cornerDotRadius, self.cropRect.origin.y+self.cropRect.size.height-cornerDotRadius, cornerDotRadius*2.0, cornerDotRadius*2.0) options:NSTrackingMouseEnteredAndExited+NSTrackingCursorUpdate+NSTrackingActiveInKeyWindow owner:self userInfo:[NSDictionary dictionaryWithObject:trackingAreaCorner forKey:kTrackingAreaKey]];
    
    NSTrackingArea *cropRectArea = [[NSTrackingArea alloc] initWithRect:self.cropRect options:NSTrackingMouseEnteredAndExited+NSTrackingCursorUpdate+NSTrackingActiveInKeyWindow owner:self userInfo:[NSDictionary dictionaryWithObject:trackingAreaRect forKey:kTrackingAreaKey]];
    
    [self addTrackingArea:corner1Area];
    [self addTrackingArea:corner2Area];
    [self addTrackingArea:corner3Area];
    [self addTrackingArea:corner4Area];
    [self addTrackingArea:cropRectArea];
    
    NSCursor *currentCursor = [NSCursor arrowCursor];
    if (NSPointInRect(mousePoint, self.cropRect)) {
        currentCursor = [NSCursor openHandCursor];
        self.mouseOverRect = YES;
    } else {
        self.mouseOverRect = NO;
    }
    self.mouseOverCorner = NO;
    for (int i=0; i<self.corners.count; i++) {
        if (NSPointInRect(mousePoint, [[self.corners objectAtIndex:i] controlPointBounds])) {
            currentCursor = [NSCursor crosshairCursor];
            self.mouseOverCorner = YES;
            break;
        }
    }
    [currentCursor set];
}

- (void)resizeRectWithPoint:(NSPoint)point {
    if (point.x < self.imageRect.origin.x) point.x = (int)self.imageRect.origin.x + 0.5f;   //Add .5 to prevent blur
    if (point.x > self.imageRect.origin.x+self.imageRect.size.width) point.x = (int)(self.imageRect.origin.x+self.imageRect.size.width) - 0.5f;
    if (point.y < self.imageRect.origin.y) point.y = (int)self.imageRect.origin.y + 0.5f;
    if (point.y > self.imageRect.origin.y+self.imageRect.size.height) point.y = (int)(self.imageRect.origin.y+self.imageRect.size.height) - 0.5f;
    
    NSRect newRect = NSZeroRect;
    switch (self.draggingCornerIndex) {
        case 0: {
            //fixed point: bottom right.
            NSPoint fixedPoint = NSMakePoint(self.cropRect.origin.x+self.cropRect.size.width, self.cropRect.origin.y+self.cropRect.size.height);
            NSSize dynamicSize = NSMakeSize(fixedPoint.x-point.x, fixedPoint.y-point.y);
            NSSize fixedSize = [self fixedBoxFromDynamic:dynamicSize];
            if ((fixedSize.width < minRectWidth) || (dynamicSize.width < 0.0) || (dynamicSize.height < 0.0)) return;
            newRect = NSMakeRect(fixedPoint.x-fixedSize.width, fixedPoint.y-fixedSize.height, fixedSize.width, fixedSize.height);
            break;
        } case 1: {
            //bottom left
            NSPoint fixedPoint = NSMakePoint(self.cropRect.origin.x, self.cropRect.origin.y + self.cropRect.size.height);
            NSSize dynamicSize = NSMakeSize(point.x-fixedPoint.x, fixedPoint.y-point.y);
            NSSize fixedSize = [self fixedBoxFromDynamic:dynamicSize];
            if ((fixedSize.width < minRectWidth) || (dynamicSize.width < 0.0) || (dynamicSize.height < 0.0)) return;
            newRect = NSMakeRect(fixedPoint.x, fixedPoint.y-fixedSize.height, fixedSize.width, fixedSize.height);
            break;
        } case 2: {
            //top left
            NSPoint fixedPoint = self.cropRect.origin;
            NSSize dynamicSize = NSMakeSize(point.x-fixedPoint.x, point.y-fixedPoint.y);
            NSSize fixedSize = [self fixedBoxFromDynamic:dynamicSize];
            if ((fixedSize.width < minRectWidth) || (dynamicSize.width < 0.0) || (dynamicSize.height < 0.0)) return;
            newRect = NSMakeRect(fixedPoint.x, fixedPoint.y, fixedSize.width, fixedSize.height);
            break;
        } case 3: {
            //top right
            NSPoint fixedPoint = NSMakePoint(self.cropRect.origin.x + self.cropRect.size.width, self.cropRect.origin.y);
            NSSize dynamicSize = NSMakeSize(fixedPoint.x-point.x, point.y-fixedPoint.y);
            NSSize fixedSize = [self fixedBoxFromDynamic:dynamicSize];
            if ((fixedSize.width < minRectWidth) || (dynamicSize.width < 0.0) || (dynamicSize.height < 0.0)) return;
            newRect = NSMakeRect(fixedPoint.x-fixedSize.width, fixedPoint.y, fixedSize.width, fixedSize.height);
            break;
        }
    }
        
    self.cropRect = newRect;
    [self.cropBlackPath removeAllPoints];
    [self.cropBlackPath appendBezierPathWithRect:newRect];
    [self.cropWhitePath removeAllPoints];
    [self.cropWhitePath appendBezierPathWithRect:newRect];
    [self recreateCornersWithRect:newRect];
    [self setNeedsDisplay:YES];
}

- (void)moveRectWithPoint:(NSPoint)point {
    NSPoint pointDifference = NSMakePoint((int)(point.x-self.startMovePoint.x), (int)(point.y-self.startMovePoint.y));
    NSRect newRect = NSMakeRect(self.startMoveRect.origin.x+pointDifference.x, self.startMoveRect.origin.y+pointDifference.y, self.startMoveRect.size.width, self.startMoveRect.size.height);
    
    if (newRect.origin.x < self.imageRect.origin.x) newRect.origin.x = (int)self.imageRect.origin.x + 0.5f; //Add .5 to prevent blur
    if (newRect.origin.y < self.imageRect.origin.y) newRect.origin.y = (int)self.imageRect.origin.y + 0.5f;
    if (newRect.origin.x+newRect.size.width > self.imageRect.origin.x+self.imageRect.size.width) newRect.origin.x = (int)(self.imageRect.origin.x+self.imageRect.size.width-newRect.size.width) - 0.5f;
    if (newRect.origin.y+newRect.size.height > self.imageRect.origin.y+self.imageRect.size.height) newRect.origin.y = (int)(self.imageRect.origin.y+self.imageRect.size.height-newRect.size.height) - 0.5f;
    
    self.cropRect = newRect;
    [self.cropBlackPath removeAllPoints];
    [self.cropBlackPath appendBezierPathWithRect:newRect];
    [self.cropWhitePath removeAllPoints];
    [self.cropWhitePath appendBezierPathWithRect:newRect];
    [self recreateCornersWithRect:newRect];
    [self setNeedsDisplay:YES];
}

- (void)recreateCornersWithRect:(NSRect)rect {
    for (NSBezierPath *corner in self.corners) {
        [corner removeAllPoints];
    }
    
    [[self.corners objectAtIndex:0] appendBezierPathWithOvalInRect:NSMakeRect(rect.origin.x-cornerDotRadius, rect.origin.y-cornerDotRadius, cornerDotRadius*2.0, cornerDotRadius*2.0)];
    [[self.corners objectAtIndex:1] appendBezierPathWithOvalInRect:NSMakeRect(rect.origin.x+rect.size.width-cornerDotRadius, rect.origin.y-cornerDotRadius, cornerDotRadius*2.0, cornerDotRadius*2.0)];
    [[self.corners objectAtIndex:2] appendBezierPathWithOvalInRect:NSMakeRect(rect.origin.x+rect.size.width-cornerDotRadius, rect.origin.y+rect.size.height-cornerDotRadius, cornerDotRadius*2.0, cornerDotRadius*2.0)];
    [[self.corners objectAtIndex:3] appendBezierPathWithOvalInRect:NSMakeRect(rect.origin.x-cornerDotRadius, rect.origin.y+rect.size.height-cornerDotRadius, cornerDotRadius*2.0, cornerDotRadius*2.0)];
}

- (NSSize)fixedBoxFromDynamic:(NSSize)box {
    switch (self.aspectRatio) {
        case AspectRatio1to1: {
            CGFloat smallest = (box.width <= box.height) ? box.width : box.height;
            return NSMakeSize((int)smallest, (int)smallest);
        } case AspectRatio1to2: {
            if ((box.width/box.height) >= 1.0/2.0) {
                //Width is greater than ratio
                return NSMakeSize((int)(box.height/2.0), (int)(box.height));
            } else {
                return NSMakeSize((int)(box.width), (int)(box.width*2.0));
            }
        } case AspectRatio2to1: {
            if ((box.width/box.height) >= 2.0/1.0) {
                //Width is greater than ratio
                return NSMakeSize((int)(box.height*2.0), (int)(box.height));
            } else {
                return NSMakeSize((int)(box.width), (int)(box.width/2.0));
            }
        } case AspectRatio4to3: {
            if ((box.width/box.height) >= 4.0/3.0) {
                //Width is greater than ratio
                return NSMakeSize((int)(box.height/3.0*4.0), (int)(box.height));
            } else {
                return NSMakeSize((int)(box.width), (int)(box.width/4.0*3.0));
            }
        }
    }
}

@end
