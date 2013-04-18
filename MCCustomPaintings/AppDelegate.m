//
//  AppDelegate.m
//  MCCustomPaintings
//
//  Created by Dalton Claybrook on 2/21/13.
//  Copyright (c) 2013 Claybrook Software, LLC. All rights reserved.
//

#import "AppDelegate.h"
#import "NameSheetWindowController.h"
#import "HDConversionWindowController.h"
#import <QuartzCore/QuartzCore.h>

static NSString *mcPath = @"Library/Application Support/minecraft/";
static NSString *existingTexturePackCellID = @"existingTexturePack";
static NSString *newTexturePackCellID = @"newTexturePack";

@interface AppDelegate ()

@property (nonatomic, strong) PaintingsController *paintingsController;
@property (nonatomic, strong) PaintingsWindowController *paintingsWindow;
@property (nonatomic, strong) CropWindowController *cropWindow;
@property (nonatomic, strong) NameSheetWindowController *nameSheet;
@property (nonatomic, strong) HDConversionWindowController *hdSheet;
@property (nonatomic, strong) Painting *painting;

- (BOOL)loadTexturePackFolder;
- (void)showNameSheet;
- (void)showHDSheetPreservingBorder:(BOOL)border;
- (void)didEndNameSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
- (void)didEndHDSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;

@end

@implementation AppDelegate

@synthesize texturePacks = _texturePacks;

#pragma mark NSApplicationDelegate Methods

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    if ([self loadTexturePackFolder]) {
        [self.tableView reloadData];
    }
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

#pragma mark Public Methods

- (IBAction)start:(id)sender {
    NSString *fullPath = nil;
    if (self.paintingsWindow == nil) {
        self.paintingsWindow = [[PaintingsWindowController alloc] initWithWindowNibName:@"PaintingsWindowController"];
        [self.paintingsWindow setDelegate:self];
    }
    if ([self.tableView selectedRow] == 0) {
        [self showNameSheet];
        //fullPath = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@bin/minecraft.jar", mcPath]];
    } else {
        fullPath = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@texturepacks/%@", mcPath, [self.texturePacks objectAtIndex:self.tableView.selectedRow-1]]];
        self.paintingsController = [[PaintingsController alloc] initWithSourcePath:fullPath delegate:self];
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
                if ([[[file pathExtension] lowercaseString] isEqualToString:@"zip"]) {
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

- (void)showNameSheet {
    if (self.nameSheet == nil) {
        self.nameSheet = [[NameSheetWindowController alloc] initWithWindowNibName:@"NameSheetWindowController"];
    }
    [NSApp beginSheet:[self.nameSheet window] modalForWindow:self.window modalDelegate:self didEndSelector:@selector(didEndNameSheet:returnCode:contextInfo:) contextInfo:nil];
}

- (void)didEndNameSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    [sheet orderOut:self];
    self.paintingsController = [[PaintingsController alloc] initWithSourcePath:[NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@bin/minecraft.jar", mcPath]] delegate:self];
    [self.paintingsController setTexturePackName:self.nameSheet.nameField.stringValue];
}

- (void)showHDSheetPreservingBorder:(BOOL)border {
    if (self.hdSheet == nil) {
        self.hdSheet = [[HDConversionWindowController alloc] initWithWindowNibName:@"HDConversionWindowController"];
    }
    [NSApp beginSheet:[self.hdSheet window] modalForWindow:self.window modalDelegate:self didEndSelector:@selector(didEndHDSheet:returnCode:contextInfo:) contextInfo:(__bridge void *)([NSNumber numberWithBool:border])];
}

- (void)didEndHDSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    [sheet orderOut:self];
    BOOL preserveBorder = [(__bridge NSNumber *)contextInfo boolValue];
    BOOL makeHD = self.hdSheet.convert;
    NSAlert *alert = [[NSAlert alloc] init];
    if ([self.paintingsController saveSourceWithPainting:self.painting preserveFrame:preserveBorder makeHD:makeHD]) {
        [alert setMessageText:@"Success!"];
    } else {
        [alert setMessageText:@"Failed to save image"];
    }
    if ([self loadTexturePackFolder]) {
        [self.tableView reloadData];
    }
    [alert runModal];
}

#pragma mark PaintingsControllerDelegate

- (void)paintingsController:(PaintingsController *)pc loadedSource:(NSImage *)source {
    [self.paintingsWindow setPaintingsController:pc];
    [self.paintingsWindow showWindow:self];
    [self.window close];
}

#pragma mark PaintingsWindowControllerDelegate Methods

- (void)paintingsWindowController:(PaintingsWindowController *)pwc selectedPainting:(Painting *)painting {
    self.painting = painting;
    if (self.cropWindow == nil) {
        self.cropWindow = [[CropWindowController alloc] initWithWindowNibName:@"CropWindowController"];
        [self.cropWindow setDelegate:self];
    }
    [self.cropWindow setCropSize:painting.rect.size];
    [self.cropWindow showWindow:self];
    [pwc close];
}

- (void)paintingsWindowControllerWillClose:(PaintingsWindowController *)pwc {
    if (![self.cropWindow.window isVisible]) {
        [self.tableView deselectAll:self];
        [self.window makeKeyAndOrderFront:self];
        if ([self loadTexturePackFolder]) {
            [self.tableView reloadData];
        }
    }
}

#pragma mark CropWindowControllerDelegate Methods

- (void)cropWindowController:(CropWindowController *)cwc didCropImage:(NSImage *)image preserveBorder:(BOOL)preserve {
    self.painting.image = image;
    [cwc close];
    [self.tableView deselectAll:self];
    [self.window makeKeyAndOrderFront:self];
    if (![self.paintingsController isHDSourceImage]) {
        [self showHDSheetPreservingBorder:preserve];
    } else {
        NSAlert *alert = [[NSAlert alloc] init];
        if ([self.paintingsController saveSourceWithPainting:self.painting preserveFrame:preserve makeHD:YES]) {
            [alert setMessageText:@"Success!"];
        } else {
            [alert setMessageText:@"Failed to save image"];
        }
        if ([self loadTexturePackFolder]) {
            [self.tableView reloadData];
        }
        [alert runModal];
    }
}

- (void)cropWindowControllerWillClose:(CropWindowController *)cwc {
    if (![self.window isVisible]) {
        [self.tableView deselectAll:self];
        [self.window makeKeyAndOrderFront:self];
        if ([self loadTexturePackFolder]) {
            [self.tableView reloadData];
        }
    }
}

#pragma mark NSTableViewDelegate and DataSource Methods

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSTableRowView *cell = nil;
    NSTextField *textField = nil;
    NSInteger kTextFieldTag = 1;
    
    if (row > 0) {
        cell = [tableView makeViewWithIdentifier:existingTexturePackCellID owner:self];
        
        if (!cell) {
            cell = [[NSTableRowView alloc] initWithFrame:NSMakeRect(0, 0, 146.0, 43.0f)];
            cell.wantsLayer = YES;
            cell.identifier = existingTexturePackCellID;
            
//            CAGradientLayer *gradient = [CAGradientLayer layer];
//            gradient.frame = cell.bounds;
//            gradient.colors = [NSArray arrayWithObjects:(id)[[NSColor whiteColor] CGColor], (id)[[NSColor colorWithCalibratedWhite:0.8 alpha:1.0] CGColor], nil];
//            [cell.layer addSublayer:gradient];
            
            textField = [[NSTextField alloc] initWithFrame:NSMakeRect(10, 13.0, 126.0f, 17.0f)];
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
            cell = [[NSTableRowView alloc] initWithFrame:NSMakeRect(0, 0, 146.0, 43.0f)];
            cell.identifier = newTexturePackCellID;
            
            textField = [[NSTextField alloc] initWithFrame:NSMakeRect(34, 13.0, 102.0f, 17.0f)];
            [textField setEditable:NO];
            [textField setBordered:NO];
            [textField setBackgroundColor:[NSColor clearColor]];
            [textField setTag:kTextFieldTag];
            [cell addSubview:textField];
            
            NSImageView *imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(10.0, 11.0, 20.0, 20.0)];
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
