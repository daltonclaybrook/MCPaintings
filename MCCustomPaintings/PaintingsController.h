//
//  PaintingsController.h
//  MCCustomPaintings
//
//  Created by Dalton Claybrook on 2/24/13.
//  Copyright (c) 2013 Claybrook Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Painting.h"

@protocol PaintingsControllerDelegate;

@interface PaintingsController : NSObject

@property (nonatomic, strong) id <PaintingsControllerDelegate> delegate;
@property (nonatomic, strong) NSImage *sourceImage;
@property (nonatomic, strong) NSArray *paintings;

- (id)initWithSourcePath:(NSString *)path delegate:(id <PaintingsControllerDelegate>)delegate;
- (void)setTexturePackName:(NSString *)name;
- (BOOL)saveSourceWithPainting:(Painting *)painting preserveFrame:(BOOL)preserve;

@end

@protocol PaintingsControllerDelegate <NSObject>

@optional
- (void)paintingsController:(PaintingsController *)pc loadedSource:(NSImage *)source;

@end