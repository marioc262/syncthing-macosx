//
//  PreferencesWindowController.h
//  syncthing-mac
//
//  Created by Jerry Jacobs on 12/06/16.
//  Copyright © 2016 Jerry Jacobs. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class STAppDelegate;

@interface STPreferencesWindowController : NSWindowController<NSXMLParserDelegate>

@property (weak) IBOutlet NSTextField *Syncthing_URI;
@property (weak) IBOutlet NSTextField *Syncthing_ApiKey;
@property (weak) IBOutlet NSButton *StartAtLogin;
@property (weak) IBOutlet NSButton *UseSynthing_inotify;
@property (weak) STAppDelegate *application;

@end
