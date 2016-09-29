#import "STApplication.h"
#import "STWindowController.h"
#import "XGSyncthing.h"
#import "XGXGSyncthingInotify.h"
#import "Controllers/STAboutWindowController.h"
#import "Controllers/STPreferencesWindowController.h"

@interface STAppDelegate ()

@property (nonatomic, strong, readwrite) NSStatusItem *statusItem;
@property (nonatomic, strong, readwrite) NSTimer *updateTimer;
@property (nonatomic, strong, readwrite) XGSyncthing *syncthing;
@property (nonatomic, strong, readwrite) XGXGSyncthingInotify *syncthingInotify;

@property (strong) STPreferencesWindowController *preferencesWindow;
@property (strong) STAboutWindowController *aboutWindow;
@property (strong) STWindowController *syncthingWindow;

@end

@implementation STAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    self.syncthing = [[XGSyncthing alloc] init];
    self.syncthingInotify = [[XGXGSyncthingInotify alloc] init];

    [self applicationLoadConfiguration];
    [self.syncthing runExecutable];
    [self useInotify:[defaults boolForKey:@"UseInotify"]];
    
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(updateStatusFromTimer) userInfo:nil repeats:YES];
}

- (void)clickedFolder:(id)sender
{
    NSString *path = [sender representedObject];
    [[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:@""];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
}

- (void) awakeFromNib {
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [self updateStatusIcon:@"StatusIconNotify"];

    self.statusItem.menu = self.Menu;
}

- (void)applicationLoadConfiguration
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSString *cfgExecutable  = [defaults stringForKey:@"Executable"];
    if (cfgExecutable) {
        [self.syncthing setExecutable:cfgExecutable];
    } else {
        [self.syncthing setExecutable:[NSString stringWithFormat:@"%@/%@",
                                       [[NSBundle mainBundle] resourcePath],
                                       @"syncthing/syncthing"]];
        [self.syncthingInotify setExecutable:[NSString stringWithFormat:@"%@/%@",
                                              [[NSBundle mainBundle] resourcePath],
                                              @"syncthing-inotify/syncthing-inotify"]];
    }


    NSString *cfgURI         = [defaults stringForKey:@"URI"];
    if (cfgURI) {
        [self.syncthing setURI:cfgURI];
    } else {
        [self.syncthing setURI:@"http://localhost:8384"];
        [defaults setObject:[self.syncthing URI] forKey:@"URI"];
    }

    NSString *cfgApiKey      = [defaults stringForKey:@"ApiKey"];
    if (cfgApiKey) {
        [self.syncthing setApiKey:cfgApiKey];
    } else {
        [self.syncthing setApiKey:@""];
        [defaults setObject:[self.syncthing ApiKey] forKey:@"ApiKey"];
    }
}

- (void) sendNotification:(NSString *) text
{
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = @"Syncthing";
    notification.informativeText = text;
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

- (void) updateStatusIcon:(NSString *) icon
{
	self.statusItem.button.image = [NSImage imageNamed:icon];
	[self.statusItem.button.image setTemplate:YES];
}

- (NSString *) formatInterval: (NSTimeInterval) interval
{
    unsigned long seconds = interval;
    unsigned long minutes = seconds / 60;
    seconds %= 60;
    unsigned long hours = minutes / 60;
    minutes %= 60;

    NSMutableString * result = [NSMutableString new];

    if(hours)
        [result appendFormat: @"%ld:", hours];

    [result appendFormat: @"%02ld:", minutes];
    [result appendFormat: @"%02ld", seconds];
    
    return result;
}

- (void)updateStatusFromTimer
{
    __weak STAppDelegate* weakself = self;
    [self.syncthing ping:^(BOOL flag) {
        if (flag) {
            [weakself updateStatusIcon:@"StatusIconDefault"];
            [weakself.syncthing getUptime:^(long uptime) {
                [weakself.statusItem setToolTip:[
                                             NSString stringWithFormat:@"Syncthing - Connected\n%@\nUptime %@",
                                             [weakself.syncthing URI],
                                             [weakself formatInterval:uptime]
                                             ]];
            }];
        } else {
            [weakself updateStatusIcon:@"StatusIconNotify"];
            [weakself.statusItem setToolTip:@"Syncthing - Not connected"];
        }
    }];
}

- (IBAction)clickedOpen:(id)sender
{
    //TODO: Add a configuration option to choose how to launch the GUI.
//    NSURL *URL = [NSURL URLWithString:[self.syncthing URI]];
//    [[NSWorkspace sharedWorkspace] openURL:URL];

    if (!self.syncthingWindow) {
        self.syncthingWindow  = [[STWindowController alloc] init];
        [self.syncthingWindow.window makeKeyAndOrderFront:nil];
        [self.syncthingWindow showWindow:nil];
    } else {
        [self.syncthingWindow.window makeKeyAndOrderFront:nil];
    }
    [NSApp activateIgnoringOtherApps:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(syncthingWindowWillClose:)
                                                 name:NSWindowWillCloseNotification
                                               object:[self.syncthingWindow window]];


}

- (void)syncthingWindowWillClose:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSWindowWillCloseNotification
                                                  object:[self.syncthingWindow window]];
    self.syncthingWindow = nil;
}

-(void)menuWillOpen:(NSMenu *)menu{
    __block NSMenu* folderMenu = menu;
    folderMenu.menuChangedMessagesEnabled = YES;
	if([[menu title] isEqualToString:@"Folders"]){
		[self.syncthing getFolders:^(id folders) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [folderMenu removeAllItems];
                for (id dir in folders) {
                    NSLog(@"id: %@", [dir objectForKey:@"id"]);
                    NSMenuItem *item = [[NSMenuItem alloc] init];
                    [item setTitle:[dir objectForKey:@"label"]];
                    [item setRepresentedObject:[dir objectForKey:@"path"]];
                    [item setAction:@selector(clickedFolder:)];
                    [item setToolTip:[dir objectForKey:@"path"]];
                    [folderMenu addItem:item];
                    [folderMenu update];
                }
            });
        }];
	}
}

- (IBAction)clickedQuit:(id)sender
{
    // Stop update timer
    [self.updateTimer invalidate];
    self.updateTimer = nil;
    
    // Set icon and remove menu
    [self updateStatusIcon:@"StatusIconNotify"];
    [self.statusItem setToolTip:@""];
    self.statusItem.menu = nil;
    
    [self.syncthing stopExecutable];
    [self.syncthingInotify stopExecutable];
    [NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:1.0];
}

- (IBAction)clickedPreferences:(NSMenuItem *)sender
{
    self.preferencesWindow = [[STPreferencesWindowController alloc] init];
    self.preferencesWindow.application = self;
    [self.preferencesWindow.window setLevel:NSFloatingWindowLevel];
    
    [NSApp activateIgnoringOtherApps:YES];
    [self.preferencesWindow showWindow:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(preferencesWillClose:)
                                                 name:NSWindowWillCloseNotification
                                               object:[self.preferencesWindow window]];
}

- (IBAction)clickedAbout:(NSMenuItem *)sender
{
	self.aboutWindow = [[STAboutWindowController alloc] init];
	[self.aboutWindow.window setLevel:NSFloatingWindowLevel];
	[NSApp activateIgnoringOtherApps:YES];
	[self.aboutWindow showWindow:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(preferencesWillClose:)
												 name:NSWindowWillCloseNotification
											   object:[self.aboutWindow window]];
}

- (void)preferencesWillClose:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSWindowWillCloseNotification
                                                  object:[self.preferencesWindow window]];
    self.preferencesWindow = nil;
}

#pragma mark - iNotify support

-(void) useInotify:(BOOL) flag {
    if (!flag && self.syncthingInotify.isRunning) {
        //Need to stop it
        [self.syncthingInotify stopExecutable];
    } else if (flag && !self.syncthingInotify.isRunning) {
        //Need to start it
        [self.syncthingInotify runExecutable];
    }
    // else there is nothing to do.
}

-(void) showInotifyLog {
    [[NSWorkspace sharedWorkspace] openFile:self.syncthingInotify.logPath];
}

@end
