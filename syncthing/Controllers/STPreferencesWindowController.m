//
//  PreferencesWindowController.m
//  syncthing-mac
//
//  Created by Jerry Jacobs on 12/06/16.
//  Copyright © 2016 Jerry Jacobs. All rights reserved.
//

#import "STPreferencesWindowController.h"
#import "STLoginItem.h"
#import "XGSyncthing.h"
#import "STApplication.h"

@interface STPreferencesWindowController ()

@property (nonatomic, strong) NSXMLParser* configParser;
@property (nonatomic, strong) NSMutableArray<NSString*>* parsing;

@end

@implementation STPreferencesWindowController

- (id)init {
    return [super initWithWindowNibName:@"STPreferencesWindow"];
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
        self.parsing = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)windowDidLoad {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [super windowDidLoad];
        
    [self.Syncthing_URI    setStringValue:[defaults objectForKey:@"URI"]];
    [self.Syncthing_ApiKey setStringValue:[defaults objectForKey:@"ApiKey"]];
	[self.StartAtLogin     setStringValue:[defaults objectForKey:@"StartAtLogin"]];
    [self.UseSynthing_inotify     setStringValue:[defaults objectForKey:@"UseInotify"]];
}

- (void)updateStartAtLogin:(NSUserDefaults *)defaults {
	STLoginItem *li = [STLoginItem alloc];

	if ([defaults integerForKey:@"StartAtLogin"]) {
		if (![li wasAppAddedAsLoginItem])
			[li addAppAsLoginItem];
	} else {
 		[li deleteAppFromLoginItem];
	}
}

- (IBAction)clickedDone:(id)sender {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:[self.Syncthing_URI stringValue] forKey:@"URI"];
    [defaults setObject:[self.Syncthing_ApiKey stringValue] forKey:@"ApiKey"];
	[defaults setObject:[self.StartAtLogin stringValue] forKey:@"StartAtLogin"];
    [defaults setObject:[self.UseSynthing_inotify stringValue] forKey:@"UseInotify"];
	
	[self updateStartAtLogin:defaults];
	
    [self close];
}

- (IBAction)clickedTest:(id)sender {
    
    XGSyncthing *st = [[XGSyncthing alloc] init];
    
	[st setURI:[self.Syncthing_URI stringValue]];
	[st setApiKey:[self.Syncthing_ApiKey stringValue]];

	[st ping:^(BOOL flag) {
        // Since we deal with UI need to be brough back to main thread
        dispatch_sync(dispatch_get_main_queue(), ^{
            NSAlert *alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle:@"OK"];

            [alert setMessageText:@"Syncthing test ping"];
            if (flag) {
                [alert setAlertStyle:NSInformationalAlertStyle];
                [alert setInformativeText:@"Ping successfull!"];
            } else {
                [alert setAlertStyle:NSWarningAlertStyle];
                [alert setInformativeText:@"Ping error, URI or API key incorrect?"];
            }
            [alert runModal];
        });
    }];

}
- (IBAction)autoPopulate:(id)sender {
    [self.Syncthing_URI    setStringValue:@""];
    [self.Syncthing_ApiKey setStringValue:@""];

    NSError* error;
    NSURL *supURL = [[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory
                                                           inDomain:NSUserDomainMask
                                                  appropriateForURL:nil
                                                             create:NO
                                                              error:&error];
    NSURL* configUrl = [supURL URLByAppendingPathComponent:@"/Syncthing/config.xml"];
    _configParser = [[ NSXMLParser alloc] initWithContentsOfURL:configUrl];
    _configParser.delegate = self;
    [_configParser parse];
    
}
- (IBAction)useInotifyChanged:(id)sender {
    [self.application useInotify:([self.UseSynthing_inotify intValue] == 1)];
}

- (IBAction)viewInotifyLog:(id)sender {
    [self.application showInotifyLog];
}

#pragma mark - NSXMLParserDelegate

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary<NSString *,NSString *> *)attributeDict {
    [self.parsing addObject:elementName];
    NSString *keyPath = [self.parsing componentsJoinedByString:@"."];
    if ([keyPath isEqualToString:@"configuration.gui"]) {
        if ([[[attributeDict objectForKey:@"tls"] lowercaseString] isEqualToString:@"true"]) {
            [self.Syncthing_URI setStringValue:@"https://"];
        } else {
            [self.Syncthing_URI setStringValue: @"http://"];
        }
    }
}

-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    [self.parsing removeLastObject];
}

-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    //TODO: Check for SSL and add https
    NSString *keyPath = [self.parsing componentsJoinedByString:@"."];
    
    if ([keyPath isEqualToString:@"configuration.gui.apikey"]) {
        NSString *key = [self.Syncthing_ApiKey.stringValue stringByAppendingString:string];
        [self.Syncthing_ApiKey setStringValue:key];
    } else if  ([keyPath isEqualToString:@"configuration.gui.address"]) {
        NSString *uri = [self.Syncthing_URI.stringValue stringByAppendingString:string];
        [self.Syncthing_URI    setStringValue:uri];
    } else {
        
    }
}



@end
