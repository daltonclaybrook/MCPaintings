//
//  AppDelegate.m
//  MCCustomPaintings
//
//  Created by Dalton Claybrook on 2/21/13.
//  Copyright (c) 2013 Claybrook Software, LLC. All rights reserved.
//

#import "AppDelegate.h"
#import "CropController.h"

@interface AppDelegate ()

@property (nonatomic, strong) CropController *cropController;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSString *mcPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/minecraft/"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:mcPath]) {
        NSString *textureFolder = [mcPath stringByAppendingPathComponent:@"texturepacks/"];
        NSError *textureFolderError = NULL;
        NSArray *texturePacks = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:textureFolder error:&textureFolderError];
        if (!textureFolderError) {
            NSLog(@"texture packs: %@", [texturePacks description]);
        } else {
            NSLog(@"texture error: %@", [textureFolderError description]);
        }
    } else {
        NSLog(@"Could not locate minecraft directory.");
    }
}

- (IBAction)showCrop:(id)sender {
    self.cropController = [[CropController alloc] initWithWindowNibName:@"CropController"];
    NSImage *image = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"two" ofType:@"jpg"]];
    [self.cropController setImage:image];
    [self.cropController showWindow:self];
}

@end
