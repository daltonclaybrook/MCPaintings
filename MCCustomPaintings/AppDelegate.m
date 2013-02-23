//
//  AppDelegate.m
//  MCCustomPaintings
//
//  Created by Dalton Claybrook on 2/21/13.
//  Copyright (c) 2013 Claybrook Software, LLC. All rights reserved.
//

#import "AppDelegate.h"
#import "CropController.h"
#import <QuartzCore/QuartzCore.h>

static NSString *mcPath = @"Library/Application Support/minecraft/";
static NSString *existingTexturePackCellID = @"existingTexturePack";
static NSString *newTexturePackCellID = @"newTexturePack";

@interface AppDelegate ()

@property (nonatomic, strong) CropController *cropController;

- (BOOL)loadTexturePackFolder;

@end

@implementation AppDelegate

@synthesize texturePacks = _texturePacks;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    if ([self loadTexturePackFolder]) {
        NSLog(@"packs: %@", [self.texturePacks description]);
        [self.tableView reloadData];
    }
}

- (IBAction)showCrop:(id)sender {
    self.cropController = [[CropController alloc] initWithWindowNibName:@"CropController"];
    NSImage *image = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"two" ofType:@"jpg"]];
    [self.cropController setImage:image];
    [self.cropController showWindow:self];
}

- (IBAction)start:(id)sender {
    if ([self.tableView selectedRow] == 0) {
        
    } else {
        NSString *fullPath = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@texturepacks/%@", mcPath, [self.texturePacks objectAtIndex:self.tableView.selectedRow-1]]];
        NSLog(@"path: %@", fullPath);
    }
}

#pragma mark Private Methods

- (BOOL)loadTexturePackFolder {
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:mcPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSString *textureFolder = [path stringByAppendingPathComponent:@"texturepacks/"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:textureFolder]) {
            NSError *directoryCreateError = NULL;
            [[NSFileManager defaultManager] createDirectoryAtPath:textureFolder withIntermediateDirectories:NO attributes:nil error:&directoryCreateError];
            if (directoryCreateError) {
                return NO;
            }
        }

        NSError *directoryContentsError = NULL;
        NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:textureFolder error:&directoryContentsError];
        if (!directoryContentsError) {
            NSMutableArray *texturePacks = [NSMutableArray array];
            for (NSString *file in contents) {
                if ([[file pathExtension] isEqualToString:@"zip"]) {
                    [texturePacks addObject:file];
                } else {
                    BOOL directory;
                    if ([[NSFileManager defaultManager] fileExistsAtPath:[textureFolder stringByAppendingPathComponent:file] isDirectory:&directory]) {
                        if (directory) {
                            [texturePacks addObject:file];
                        }
                    }
                }
            }
            self.texturePacks = (NSArray *)texturePacks;
            return YES;
        }
    }
    return NO;
}

#pragma mark NSTableViewDelegate and DataSource Methods

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSTableRowView *cell = nil;
    NSTextField *textField = nil;
    NSInteger kTextFieldTag = 1;
    
    if (row > 0) {
        cell = [tableView makeViewWithIdentifier:existingTexturePackCellID owner:self];
        
        if (!cell) {
            cell = [[NSTableRowView alloc] initWithFrame:NSMakeRect(0, 0, 146.0, 54.0f)];
            cell.wantsLayer = YES;
            cell.identifier = existingTexturePackCellID;
            
            CAGradientLayer *gradient = [CAGradientLayer layer];
            gradient.frame = cell.bounds;
            gradient.colors = [NSArray arrayWithObjects:(id)[[NSColor whiteColor] CGColor], (id)[[NSColor colorWithCalibratedWhite:0.8 alpha:1.0] CGColor], nil];
            [cell.layer addSublayer:gradient];
            
            textField = [[NSTextField alloc] initWithFrame:NSMakeRect(10, 18.0, 126.0f, 17.0f)];
            [textField setEditable:NO];
            [textField setBordered:NO];
            [textField setBackgroundColor:[NSColor clearColor]];
            [textField setTag:kTextFieldTag];
            [cell addSubview:textField];
        } else {
            textField = (NSTextField *)[cell viewWithTag:kTextFieldTag];
        }
        
        textField.stringValue = [[[self.texturePacks objectAtIndex:row-1] componentsSeparatedByString:@".zip"] objectAtIndex:0];
    } else {
        cell = [tableView makeViewWithIdentifier:newTexturePackCellID owner:self];
        
        if (!cell) {
            cell = [[NSTableRowView alloc] initWithFrame:NSMakeRect(0, 0, 146.0, 54.0f)];
            cell.identifier = newTexturePackCellID;
            
            textField = [[NSTextField alloc] initWithFrame:NSMakeRect(34, 18.0, 102.0f, 17.0f)];
            [textField setEditable:NO];
            [textField setBordered:NO];
            [textField setBackgroundColor:[NSColor clearColor]];
            [textField setTag:kTextFieldTag];
            [cell addSubview:textField];
            
            NSImageView *imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(10.0, 17.0, 20.0, 20.0)];
            [imageView setImage:[NSImage imageNamed:@"plus.png"]];
            [cell addSubview:imageView];
        } else {
            textField = (NSTextField *)[cell viewWithTag:kTextFieldTag];
        }
        
        textField.stringValue = @"Create New";
    }
        
    return cell;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.texturePacks.count+1;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    if ([self.tableView selectedRow] == -1) {
        [self.startButton setEnabled:NO];
    } else {
        [self.startButton setEnabled:YES];
    }
}

@end
