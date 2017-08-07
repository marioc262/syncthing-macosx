//
//  STWindowController.h
//  syncthing
//
//  Created by Mario Couture on 2016-09-24.
//  Copyright © 2016 Mario Couture. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface STWindowController : NSWindowController <WKNavigationDelegate,WKScriptMessageHandler>

    @property (strong) NSString* address;


    @end
