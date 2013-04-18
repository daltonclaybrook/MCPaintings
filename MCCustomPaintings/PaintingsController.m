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
static CGFloat hdWidth = 2048.0f;

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
    NSLog(@"name: %@", self.texturePackFolderPath);
}

- (BOOL)saveSourceWithPainting:(Painting *)painting preserveFrame:(BOOL)preserve makeHD:(BOOL)hd {
    CGFloat hdModifier = (hd) ? (hdWidth / 256.0f) : 1.0f;
    CGFloat padding = (preserve) ? hdModifier : 0.0;
    if (hd && (![self isHDSourceImage])) {
        NSImage *newSource = [[NSImage alloc] initWithSize:NSMakeSize(hdWidth, hdWidth)];
        [newSource lockFocus];
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationNone];
        [[NSGraphicsContext currentContext] setShouldAntialias:NO];
        [self.sourceImage drawInRect:NSMakeRect(0, 0, hdWidth, hdWidth) fromRect:NSMakeRect(0, 0, self.sourceImage.size.width, self.sourceImage.size.height) operation:NSCompositeSourceOver fraction:1.0f];
        [newSource unlockFocus];
        self.sourceImage = newSource;
    }
    [self.sourceImage lockFocus];
    //[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationNone];
    //[[NSGraphicsContext currentContext] setShouldAntialias:NO];
    [painting.image drawInRect:NSMakeRect(painting.rect.origin.x*16.0*hdModifier+padding, painting.rect.origin.y*16.0*hdModifier+padding, painting.rect.size.width*16.0*hdModifier-padding*2.0, painting.rect.size.height*16.0*hdModifier-padding*2.0) fromRect:NSMakeRect(0, 0, painting.image.size.width, painting.image.size.height) operation:NSCompositeSourceOver fraction:1.0];
    [self.sourceImage unlockFocus];
    
    NSData *imageData = [self.sourceImage TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
    imageData = [imageRep representationUsingType:NSJPEGFileType properties:imageProps];
    
    if (self.texturePackFolderPath) {
        NSString *artFolder = [self.texturePackFolderPath stringByAppendingPathComponent:@"art/"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:artFolder]) {
            if (![[NSFileManager defaultManager] createDirectoryAtPath:artFolder withIntermediateDirectories:YES attributes:nil error:NULL]) return NO;
        }
        if (![[NSFileManager defaultManager] fileExistsAtPath:[self.texturePackFolderPath stringByAppendingPathComponent:@"pack.txt"]]) {
            if (![@"Made with MCPaintings" writeToFile:[self.texturePackFolderPath stringByAppendingPathComponent:@"pack.txt"] atomically:NO encoding:NSUTF8StringEncoding error:NULL]) return NO;
        }
        return [imageData writeToFile:[artFolder stringByAppendingPathComponent:@"kz.png"] atomically:NO];
    }
    return NO;
}

- (BOOL)isHDSourceImage {
    if (self.sourceImage.size.width < hdWidth) {
        return NO;
    }
    return YES;
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
    CGFloat sizeModifier = source.size.width / 256.0f;
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
            NSRect lowDefRect = NSMakeRect((int)sectionBoxes[i].origin.x + (int)(j*imageSizes[i].width)%(int)(sectionBoxes[i].size.width), ((source.size.height/sizeModifier)/16-imageSizes[i].height) - ((int)sectionBoxes[i].origin.y + floorf((j*imageSizes[i].width)/sectionBoxes[i].size.width) * imageSizes[i].height), imageSizes[i].width, imageSizes[i].height);
            Painting *painting = [[Painting alloc] initWithSourceImage:source coordinates:lowDefRect];
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

@end
