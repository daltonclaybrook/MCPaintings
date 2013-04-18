//
//  HDConversionWindowController.h
//  MCCustomPaintings
//
//  Created by Dalton Claybrook on 3/18/13.
//  Copyright (c) 2013 Claybrook Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface HDConversionWindowController : NSWindowController

@property (nonatomic, readonly) BOOL convert;

- (IBAction)yes:(id)sender;
- (IBAction)no:(id)sender;

@end
