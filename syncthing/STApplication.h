//
//  AppDelegate.h
//  syncthing-mac
//
//  Created by Jerry Jacobs on 12/06/16.
//  Copyright © 2016 Jerry Jacobs. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface STAppDelegate : NSObject <NSApplicationDelegate>

@property (weak) IBOutlet NSMenu *Menu;
@property (nonatomic, readonly) NSStatusItem *statusItem;

-(void) useInotify:(BOOL) flag;
-(void) showInotifyLog;

@end
