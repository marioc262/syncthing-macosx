//
//  XGXGSyncthingInotify.h
//  syncthing
//
//  Created by Mario Couture on 2016-09-27.
//  Copyright © 2016 Jerry Jacobs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XGXGSyncthingInotify : NSObject

@property (nonatomic, copy) NSString *executable;
@property (nonatomic, copy) NSString *logPath;

@property (nonatomic,assign) BOOL isRunning;

- (void)runExecutable;
// Interrupts syncthing and block-waits until exit
- (void)stopExecutable;

@end
