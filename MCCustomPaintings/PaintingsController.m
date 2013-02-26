//
//  PaintingsController.m
//  MCCustomPaintings
//
//  Created by Dalton Claybrook on 2/24/13.
//  Copyright (c) 2013 Claybrook Software, LLC. All rights reserved.
//

#import "PaintingsController.h"

static NSString *mcPath = @"Library/Application Support/minecraft/";
static NSString *temporaryFolder = @".MCPaintingsTemp/";

@interface PaintingsController ()

@property (nonatomic, strong) NSString *sourcePath;
@property (nonatomic, strong) NSString *texturePackFolderPath;

- (void)loadSourceFromJARPath:(NSString *)path;
- (void)extractArchiveAndLoadSource:(NSString *)path;
- (NSImage *)loadSourceFromFolderPath:(NSString *)path;
- (NSArray *)loadPaintingsFromSource:(NSImage *)source;
- (NSImage *)maxImageRepOfSource:(NSImage *)source;

@end

@implementation PaintingsController

@synthesize delegate = _delegate, sourceImage = _sourceImage, paintings = _paintings;

- (id)initWithSourcePath:(NSString *)path delegate:(id <PaintingsControllerDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
        if (path) {
            self.sourcePath = path;
            BOOL isDirectory;
            if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory]) {
                NSImage *sourceImage = nil;
                if (isDirectory) {
                    sourceImage = [self loadSourceFromFolderPath:path];
                    _sourceImage = [self maxImageRepOfSource:sourceImage];
                    _paintings = [self loadPaintingsFromSource:self.sourceImage];
                    if ([self.delegate respondsToSelector:@selector(paintingsController:loadedSource:)]) {
                        [self.delegate paintingsController:self loadedSource:self.sourceImage];
                    }
                } else {
                    if ([[[path pathExtension] lowercaseString] isEqualToString:@"jar"]) {
                        [self loadSourceFromJARPath:path];
                    } else {
                        [self extractArchiveAndLoadSource:path];
                    }
                }
            }
        }
    }
    return self;
}

- (void)setTexturePackName:(NSString *)name {
    self.texturePackFolderPath = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@texturepacks/%@", mcPath, name]];
}

- (BOOL)saveSourceWithPainting:(Painting *)painting preserveFrame:(BOOL)preserve {
    CGFloat padding = (preserve) ? 1.0 : 0.0;
    [self.sourceImage lockFocus];
    [painting.image drawInRect:NSMakeRect(painting.rect.origin.x*16.0+padding, painting.rect.origin.y*16.0+padding, painting.rect.size.width*16.0-padding*2.0, painting.rect.size.height*16.0-padding*2.0) fromRect:NSMakeRect(0, 0, painting.image.size.width, painting.image.size.height) operation:NSCompositeSourceOver fraction:1.0];
    [self.sourceImage unlockFocus];
    
    NSData *imageData = [self.sourceImage TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
    imageData = [imageRep representationUsingType:NSJPEGFileType properties:imageProps];
    //[imageData writeToFile:@"/Users/daltonclaybrook/Desktop/file.jpg" atomically:NO];
    
    if (self.texturePackFolderPath) {
        return [imageData writeToFile:[self.texturePackFolderPath stringByAppendingPathComponent:@"art/kz.png"] atomically:NO];
    }
    return NO;
}

#pragma mark Private Methods

- (void)loadSourceFromJARPath:(NSString *)path {
    self.texturePackFolderPath = nil;
    NSTask *extractFile = [[NSTask alloc] init];
    NSString *tempFolderPath = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:temporaryFolder];
    extractFile.launchPath = @"/usr/bin/unzip";
    extractFile.arguments = [NSArray arrayWithObjects:@"-j", path, @"art/kz.png", @"-d", tempFolderPath, nil];
    extractFile.terminationHandler = ^(NSTask *task) {
        NSImage *image = nil;
        if (task.terminationStatus == 0) {
            image = [[NSImage alloc] initWithContentsOfFile:[tempFolderPath stringByAppendingPathComponent:@"kz.png"]];
            [[NSFileManager defaultManager] removeItemAtPath:tempFolderPath error:NULL];
        } else {
            image = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"kz" ofType:@"png"]];
        }
        self.sourceImage = [self maxImageRepOfSource:image];
        self.paintings = [self loadPaintingsFromSource:self.sourceImage];
        dispatch_async (dispatch_get_main_queue (), ^(void) {
            if ([self.delegate respondsToSelector:@selector(paintingsController:loadedSource:)]) {
                [self.delegate paintingsController:self loadedSource:self.sourceImage];
            }
        });
    };
    [extractFile launch];
}

- (void)extractArchiveAndLoadSource:(NSString *)path {
    NSTask *extractFile = [[NSTask alloc] init];
    self.texturePackFolderPath = [path substringToIndex:path.length-([[path pathExtension] length]+1)];
    extractFile.launchPath = @"/usr/bin/unzip";
    extractFile.arguments = [NSArray arrayWithObjects:@"-o", path, @"-d", self.texturePackFolderPath, nil];
    extractFile.terminationHandler = ^(NSTask *task) {
        NSImage *image = nil;
        if (task.terminationStatus == 0) {
            image = [[NSImage alloc] initWithContentsOfFile:[self.texturePackFolderPath stringByAppendingPathComponent:@"art/kz.png"]];
            [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
        }
        if (!image) image = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"kz" ofType:@"png"]];
        self.sourceImage = [self maxImageRepOfSource:image];
        self.paintings = [self loadPaintingsFromSource:self.sourceImage];
        dispatch_async (dispatch_get_main_queue (), ^(void) {
            if ([self.delegate respondsToSelector:@selector(paintingsController:loadedSource:)]) {
                [self.delegate paintingsController:self loadedSource:self.sourceImage];
            }
        });
    };
    [extractFile launch];
}

- (NSImage *)loadSourceFromFolderPath:(NSString *)path {
    self.texturePackFolderPath = path;
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

- (NSImage *)maxImageRepOfSource:(NSImage *)source {
    NSInteger width = 0;
    NSInteger height = 0;
    for (NSImageRep * imageRep in [source representations]) {
        if ([imageRep pixelsWide] > width) width = [imageRep pixelsWide];
        if ([imageRep pixelsHigh] > height) height = [imageRep pixelsHigh];
    }
    NSImage *bigImage = [[NSImage alloc] initWithSize:NSMakeSize((CGFloat)width, (CGFloat)height)];
    [bigImage addRepresentations:[source representations]];
    return bigImage;
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
