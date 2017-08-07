//
//  STWindowController.m
//  syncthing
//
//  Created by Mario Couture on 2016-09-24.
//  Copyright © 2016 Mario Couture. All rights reserved.
//

#import "STWindowController.h"

@interface STWindowController ()
    {
        WKWebView* wkView;
        WKWebViewConfiguration* configuration;
    }

@end

@implementation STWindowController

- (instancetype)initWithAddress:(NSString*) address
{
    self = [super initWithWindowNibName:@"STWindowController"];
    if (self) {
        _address = address;
    }
    return self;
}

- (instancetype)init
{
    self = [self initWithAddress:@"https://127.0.0.1:8384"];
    return self;
}

#pragma mark - NSWindow managment

- (void)windowDidLoad {
    [super windowDidLoad];
    __weak STWindowController* weakself = self;

    configuration = [WKWebViewConfiguration new];
    [configuration.userContentController addScriptMessageHandler:weakself name:@"guiproxy"];
    configuration.preferences.javaScriptCanOpenWindowsAutomatically = NO;
    configuration.preferences.minimumFontSize = 12.0;
    NSError * error;
    NSString* extensionString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"STExtension" ofType:@"js"]
                                                    encoding:NSUTF8StringEncoding
                                                       error:&error];
    if (error == nil) {
        WKUserScript* userScript = [[WKUserScript alloc] initWithSource:extensionString injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
        [configuration.userContentController addUserScript:userScript];
    }

    wkView = [[WKWebView alloc] initWithFrame:self.window.contentView.bounds configuration: configuration];
    wkView.navigationDelegate = self;
    self.window.contentView = wkView;
    self.window.title = @"Syncthing";
}

-(void) showWindow:(id)sender {

    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:_address]];
    [wkView loadRequest:request];
}


#pragma mark - WKNavigationDelegate

-(void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {

    if (challenge.protectionSpace.serverTrust) {
        NSURLCredential* cred = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential,cred);
    }
}

-(void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self integrateControls];
}

#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    NSLog(@"++++ Reveived Message: %@",message.body);
    if ([message.body isEqualToString:@"selectFolder"]) {
        NSOpenPanel* panel = [NSOpenPanel openPanel];
        panel.canChooseDirectories = true;
        panel.canChooseFiles = false;
        panel.allowsMultipleSelection = false;
        NSInteger ret = [panel runModal];

        if (ret != NSModalResponseCancel) {
            NSString* folderPath = panel.URL.path;
            NSString* folderLabel = panel.URL.lastPathComponent;
            NSString* command = [NSString stringWithFormat:@"window.stExtension.setFolderPath('%@','%@');",folderPath,folderLabel];
            [wkView evaluateJavaScript:command
                     completionHandler:^(id _Nullable result, NSError * _Nullable error) {
                         if (error) {
                             NSLog(@"Error setting folder path: %@",error);
                         }
                     }];
        }

    }
}


#pragma mark - Custom Helpers

-(void) integrateControls {
    NSLog(@"++++ Setting up buttons now");
    [wkView evaluateJavaScript:@"window.stExtension.setupButtons();"
             completionHandler:^(id _Nullable result, NSError * _Nullable error) {
                 if (error) {
                     NSLog(@"Error integrating buttons: %@",error);
                 }
             }];
}

@end
