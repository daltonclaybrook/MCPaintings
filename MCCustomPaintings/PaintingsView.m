//
//  PaintingsView.m
//  MCCustomPaintings
//
//  Created by Dalton Claybrook on 2/24/13.
//  Copyright (c) 2013 Claybrook Software, LLC. All rights reserved.
//

#import "PaintingsView.h"

@implementation PaintingsView

@synthesize painting = _painting;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    if (self.painting) {
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationNone];
        [[NSGraphicsContext currentContext] setShouldAntialias:NO];
        
        NSSize viewSize = self.bounds.size;
        NSRect imageRect = NSZeroRect;
        imageRect.size = NSMakeSize(self.painting.image.size.width/(64.0f * self.painting.hdScaleFactor)*viewSize.width, self.painting.image.size.height/(64.0f * self.painting.hdScaleFactor)*viewSize.height);
        imageRect.origin = NSMakePoint((viewSize.width-imageRect.size.width)/2.0, (viewSize.height-imageRect.size.height)/2.0);
        
        [self.painting.image drawInRect:imageRect fromRect:NSMakeRect(0, 0, self.painting.image.size.width, self.painting.image.size.height) operation:NSCompositeSourceOver fraction:1.0];
    }
}

@end
