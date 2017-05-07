//
//  FinderSync.m
//  syncthing-ext
//
//  Created by Mario Couture on 2017-05-02.
//  Copyright © 2017 Jerry Jacobs. All rights reserved.
//

#import "FinderSync.h"
#import "XGSyncthing.h"

@interface FinderSync ()

@property NSSet<NSURL*> *myFolderURL;
@property XGSyncthing *syncthing;

@end

//#define TESTING
@implementation FinderSync

- (instancetype)init {
    self = [super init];

    _syncthing = [[XGSyncthing alloc] init];
    [_syncthing loadConfig];
    NSLog(@"%s launched from %@ ; compiled at %s", __PRETTY_FUNCTION__, [[NSBundle mainBundle] bundlePath], __TIME__);

    // Set up images for our badge identifiers.
    [[FIFinderSyncController defaultController] setBadgeImage:[NSImage imageNamed: @"syncthing-default"]  label:@"Syncthing File"  forBadgeIdentifier:@"File"];
    [[FIFinderSyncController defaultController] setBadgeImage:[NSImage imageNamed: @"syncthing.icns"]  label:@"Syncthing Share"  forBadgeIdentifier:@"Sync"];

    [_syncthing getFolders:^(id folders) {
        NSLog(@"FinderSync Got Folders:");
        NSMutableSet<NSURL*>* urls = [NSMutableSet setWithCapacity:10];
        for (id dir in folders) {
            NSString* path = [dir objectForKey:@"path"];
            if ([path hasSuffix:@"/"]) {
                path = [path substringToIndex:path.length-1];
            }
            NSLog(@"Finder Sync Ext will monitor: %@",path);
            NSURL *url =[NSURL fileURLWithPath:path];
            [urls addObject:url];            
            [[FIFinderSyncController defaultController] setBadgeIdentifier:@"Sync" forURL:url];
        }
        self.myFolderURL = urls;
        [FIFinderSyncController defaultController].directoryURLs = self.myFolderURL;
        
        [_syncthing closeSession];
    }];
    return self;
}
#pragma mark - context menu

-(NSMenu *)menuForMenuKind:(FIMenuKind)menu {

    NSMenu* syncMenu = [[NSMenu alloc] initWithTitle:@"Synching"];
    [syncMenu addItem:[[NSMenuItem alloc] initWithTitle:@"Share" action:@selector(shareFolder:) keyEquivalent:@""]];
    
    NSURL* currentSelection = [[FIFinderSyncController defaultController] targetedURL];
    
    NSLog(@"Selected URL is %@",currentSelection);
    
    return syncMenu;
    
}

- (IBAction)shareFolder:(id)sender {
    NSLog(@"So you want to share this!");
}

- (void)beginObservingDirectoryAtURL:(NSURL *)url {
    // The user is now seeing the container's contents.
    // If they see it in more than one view at a time, we're only told once.
    NSLog(@"beginObservingDirectoryAtURL:%@", url.filePathURL);
}


- (void)endObservingDirectoryAtURL:(NSURL *)url {
    // The user is no longer seeing the container's contents.
    NSLog(@"endObservingDirectoryAtURL:%@", url.filePathURL);
}

- (void)requestBadgeIdentifierForURL:(NSURL *)url {
    NSLog(@"requestBadgeIdentifierForURL:%@", url.filePathURL);
    [[FIFinderSyncController defaultController] setBadgeIdentifier:@"File" forURL:url];
}


#pragma mark - Menu and toolbar item support

- (NSString *)toolbarItemName {
    return @"syncthing-ext";
}

//- (NSString *)toolbarItemToolTip {
//    return @"syncthing-ext: Click the toolbar item for a menu.";
//}

//- (NSImage *)toolbarItemImage {
//    return [NSImage imageNamed:NSImageNameCaution];
//}
//
//- (NSMenu *)menuForMenuKind:(FIMenuKind)whichMenu {
//    // Produce a menu for the extension.
//    NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
//    [menu addItemWithTitle:@"Example Menu Item" action:@selector(sampleAction:) keyEquivalent:@""];
//
//    return menu;
//}
//
//- (IBAction)sampleAction:(id)sender {
//    NSURL* target = [[FIFinderSyncController defaultController] targetedURL];
//    NSArray* items = [[FIFinderSyncController defaultController] selectedItemURLs];
//
//    NSLog(@"sampleAction: menu item: %@, target = %@, items = ", [sender title], [target filePathURL]);
//    [items enumerateObjectsUsingBlock: ^(id obj, NSUInteger idx, BOOL *stop) {
//        NSLog(@"    %@", [obj filePathURL]);
//    }];
//}

@end

