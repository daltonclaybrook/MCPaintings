//
//  PaintingsController.m
//  MCCustomPaintings
//
//  Created by Dalton Claybrook on 2/24/13.
//  Copyright (c) 2013 Claybrook Software, LLC. All rights reserved.
//

#import "PaintingsController.h"

static NSString *temporaryFolder = @".MCPaintingsTemp/";

@interface PaintingsController ()

- (NSImage *)loadSourceFromArchivePath:(NSString *)path;
- (NSImage *)loadSourceFromFolderPath:(NSString *)path;
- (NSArray *)loadPaintingsFromSource:(NSImage *)source;

@end

@implementation PaintingsController

@synthesize sourceImage = _sourceImage, paintings = _paintings;

- (id)initWithSourcePath:(NSString *)path {
    self = [super init];
    if (self) {
        if (path) {
            BOOL isDirectory;
            if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory]) {
                NSImage *sourceImage = nil;
                if (isDirectory) {
                    sourceImage = [self loadSourceFromFolderPath:path];
                } else {
                    sourceImage = [self loadSourceFromArchivePath:path];
                }
                
                NSInteger width = 0;
                NSInteger height = 0;
                for (NSImageRep * imageRep in [sourceImage representations]) {
                    if ([imageRep pixelsWide] > width) width = [imageRep pixelsWide];
                    if ([imageRep pixelsHigh] > height) height = [imageRep pixelsHigh];
                }
                _sourceImage = [[NSImage alloc] initWithSize:NSMakeSize((CGFloat)width, (CGFloat)height)];
                [self.sourceImage addRepresentations:[sourceImage representations]];
                _paintings = [self loadPaintingsFromSource:self.sourceImage];
            }
        }
    }
    return self;
}

#pragma mark Private Methods

- (NSImage *)loadSourceFromArchivePath:(NSString *)path {
    NSTask *extractFile = [[NSTask alloc] init];
    NSString *tempFolderPath = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:temporaryFolder];
    extractFile.launchPath = @"/usr/bin/unzip";
    extractFile.arguments = [NSArray arrayWithObjects:@"-j", path, @"art/kz.png", @"-d", tempFolderPath, nil];
    [extractFile launch];
    [extractFile waitUntilExit];
    
    NSImage *sourceImage;
    if ([extractFile terminationStatus] == 0) {
        sourceImage = [[NSImage alloc] initWithContentsOfFile:[tempFolderPath stringByAppendingPathComponent:@"kz.png"]];
        NSError *tempDeleteError = NULL;
        [[NSFileManager defaultManager] removeItemAtPath:tempFolderPath error:&tempDeleteError];
        if (tempDeleteError) {
            NSLog(@"error: %@", [tempDeleteError description]);
        } else {
            NSLog(@"No Error");
        }
    } else {
        sourceImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"kz" ofType:@"png"]];
    }
    return sourceImage;
}

- (NSImage *)loadSourceFromFolderPath:(NSString *)path {
    NSImage *sourceImage = [[NSImage alloc] initWithContentsOfFile:[path stringByAppendingPathComponent:@"art/kz.png"]];
    if (!sourceImage) {
        sourceImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"kz" ofType:@"png"]];
    }
    return sourceImage;
}

- (NSArray *)loadPaintingsFromSource:(NSImage *)source {
    NSMutableArray *paintings = [NSMutableArray array];
    NSUInteger numSections = 7;
    NSUInteger sectionCounts[] = {
        //Number of images in each section
        7, 5, 2, 1, 6, 2, 3
    };
    
    NSRect sectionBoxes[] = {
        //Rect containing each image section in the source image
        //Measured in 16px x 16px blocks
        NSMakeRect(0, 0, 12, 2),
        NSMakeRect(0, 2, 12, 2),
        NSMakeRect(0, 4, 12, 2),
        NSMakeRect(0, 6, 12, 2),
        NSMakeRect(0, 8, 12, 4),
        NSMakeRect(12, 4, 4, 6),
        NSMakeRect(0, 12, 16, 4)
    };
    NSSize imageSizes[] = {
        //Size of the images in each section
        //Measured in 16px x 16px blocks
        NSMakeSize(1, 1),
        NSMakeSize(2, 1),
        NSMakeSize(1, 2),
        NSMakeSize(4, 2),
        NSMakeSize(2, 2),
        NSMakeSize(4, 3),
        NSMakeSize(4, 4)
    };
    
    for (int i=0; i<numSections; i++) {
        for (int j=0; j<sectionCounts[i]; j++) {
            Painting *painting = [[Painting alloc] initWithSourceImage:source coordinates:NSMakeRect((int)sectionBoxes[i].origin.x + (int)(j*imageSizes[i].width)%(int)(sectionBoxes[i].size.width), (source.size.height/16-imageSizes[i].height) - ((int)sectionBoxes[i].origin.y + floorf((j*imageSizes[i].width)/sectionBoxes[i].size.width) * imageSizes[i].height), imageSizes[i].width, imageSizes[i].height)];
            [paintings addObject:painting];
        }
    }
    
    return (NSArray *)paintings;
}

//- (NSArray *)loadPaintingsFromSource:(NSImage *)source {
//    NSMutableArray *paintings = [NSMutableArray array];
//    NSRect sectionBox = NSMakeRect(0, 0, 12, 2);
//    NSSize imageSize = NSMakeSize(1, 1);
//    
//    NSRect sectionBoxes[] = {NSMakeRect(0, 0, 12, 2), NSMakeRect(0, 2, 12, 2)};
//    
//    for (int i=0; i<imageCount1; i++) {
//        Painting *painting = [[Painting alloc] initWithSourceImage:source coordinates:NSMakeRect((int)sectionBox.origin.x + (int)(i*imageSize.width)%(int)(sectionBox.size.width), (source.size.height/16-imageSize.height) - ((int)sectionBox.origin.y + floorf((i*imageSize.width)/sectionBox.size.width) * imageSize.height), imageSize.width, imageSize.height)];
//        [paintings addObject:painting];
//    }
//    sectionBox = NSMakeRect(0, 2, 12, 2);
//    imageSize = NSMakeSize(2, 1);
//    for (int i=0; i<imageCount2; i++) {
//        Painting *painting = [[Painting alloc] initWithSourceImage:source coordinates:NSMakeRect((int)sectionBox.origin.x + (int)(i*imageSize.width)%(int)(sectionBox.size.width), (source.size.height/16-imageSize.height) - ((int)sectionBox.origin.y + floorf((i*imageSize.width)/sectionBox.size.width) * imageSize.height), imageSize.width, imageSize.height)];
//        [paintings addObject:painting];
//    }
//    sectionBox = NSMakeRect(0, 4, 12, 2);
//    imageSize = NSMakeSize(1, 2);
//    for (int i=0; i<imageCount3; i++) {
//        Painting *painting = [[Painting alloc] initWithSourceImage:source coordinates:NSMakeRect((int)sectionBox.origin.x + (int)(i*imageSize.width)%(int)(sectionBox.size.width), (source.size.height/16-imageSize.height) - ((int)sectionBox.origin.y + floorf((i*imageSize.width)/sectionBox.size.width) * imageSize.height), imageSize.width, imageSize.height)];
//        [paintings addObject:painting];
//    }
//    sectionBox = NSMakeRect(0, 6, 12, 2);
//    imageSize = NSMakeSize(4, 2);
//    for (int i=0; i<imageCount4; i++) {
//        Painting *painting = [[Painting alloc] initWithSourceImage:source coordinates:NSMakeRect((int)sectionBox.origin.x + (int)(i*imageSize.width)%(int)(sectionBox.size.width), (source.size.height/16-imageSize.height) - ((int)sectionBox.origin.y + floorf((i*imageSize.width)/sectionBox.size.width) * imageSize.height), imageSize.width, imageSize.height)];
//        [paintings addObject:painting];
//    }
//    sectionBox = NSMakeRect(0, 8, 12, 4);
//    imageSize = NSMakeSize(2, 2);
//    for (int i=0; i<imageCount5; i++) {
//        Painting *painting = [[Painting alloc] initWithSourceImage:source coordinates:NSMakeRect((int)sectionBox.origin.x + (int)(i*imageSize.width)%(int)(sectionBox.size.width), (source.size.height/16-imageSize.height) - ((int)sectionBox.origin.y + floorf((i*imageSize.width)/sectionBox.size.width) * imageSize.height), imageSize.width, imageSize.height)];
//        [paintings addObject:painting];
//    }
//    sectionBox = NSMakeRect(12, 4, 4, 6);
//    imageSize = NSMakeSize(4, 3);
//    for (int i=0; i<imageCount6; i++) {
//        Painting *painting = [[Painting alloc] initWithSourceImage:source coordinates:NSMakeRect((int)sectionBox.origin.x + (int)(i*imageSize.width)%(int)(sectionBox.size.width), (source.size.height/16-imageSize.height) - ((int)sectionBox.origin.y + floorf((i*imageSize.width)/sectionBox.size.width) * imageSize.height), imageSize.width, imageSize.height)];
//        [paintings addObject:painting];
//    }
//    sectionBox = NSMakeRect(0, 12, 16, 4);
//    imageSize = NSMakeSize(4, 4);
//    for (int i=0; i<imageCount7; i++) {
//        Painting *painting = [[Painting alloc] initWithSourceImage:source coordinates:NSMakeRect((int)sectionBox.origin.x + (int)(i*imageSize.width)%(int)(sectionBox.size.width), (source.size.height/16-imageSize.height) - ((int)sectionBox.origin.y + floorf((i*imageSize.width)/sectionBox.size.width) * imageSize.height), imageSize.width, imageSize.height)];
//        [paintings addObject:painting];
//    }
//    
//    return (NSArray *)paintings;
//}

@end
