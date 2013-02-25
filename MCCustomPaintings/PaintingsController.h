//
//  PaintingsController.h
//  MCCustomPaintings
//
//  Created by Dalton Claybrook on 2/24/13.
//  Copyright (c) 2013 Claybrook Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Painting.h"

@interface PaintingsController : NSObject

@property (nonatomic, strong) NSImage *sourceImage;
@property (nonatomic, strong) NSArray *paintings;

- (id)initWithSourcePath:(NSString *)path;

@end
