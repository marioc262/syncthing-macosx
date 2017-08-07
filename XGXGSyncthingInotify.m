//
//  XGXGSyncthingInotify.m
//  syncthing
//
//  Created by Mario Couture on 2016-09-27.
//  Copyright © 2016 Jerry Jacobs. All rights reserved.
//

#import "XGXGSyncthingInotify.h"

@interface XGXGSyncthingInotify()

@property (nonatomic, strong) NSTask *_stTask;
@property (nonatomic, strong) NSPipe *_outputPipe;
@property (nonatomic, strong) NSDateFormatter *_dateFormatter;

@end


@implementation XGXGSyncthingInotify

- (instancetype)init
{
    self = [super init];
    if (self) {
        self._dateFormatter = [[NSDateFormatter alloc] init];
        self._dateFormatter.timeStyle = NSDateFormatterNoStyle;
        self._dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        NSError* error;
        NSURL *libURL = [[NSFileManager defaultManager] URLForDirectory:NSLibraryDirectory
                                                            inDomain:NSUserDomainMask
                                                   appropriateForURL:nil
                                                              create:NO
                                                               error:&error];
        
        self.logPath = [libURL.path stringByAppendingPathComponent:@"Logs/syncthing-inotify"];
    }
    return self;
}

- (void)runExecutable {

    __weak XGXGSyncthingInotify* weakself = self;

    dispatch_queue_t taskQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(taskQueue, ^{

        weakself.isRunning = YES;

        @try {
            if (self.logPath) {
                [[NSFileManager defaultManager] createDirectoryAtPath:self.logPath withIntermediateDirectories:YES attributes:nil error:nil];
            }

            weakself._stTask            = [[NSTask alloc] init];
            weakself._stTask.launchPath = weakself.executable;
//            weakself._stTask.arguments  = arguments;

            // Output Handling
            weakself._outputPipe = [[NSPipe alloc] init];
            weakself._stTask.standardOutput = weakself._outputPipe;
            weakself._stTask.standardError  = weakself._outputPipe;

            [[weakself._outputPipe fileHandleForReading] waitForDataInBackgroundAndNotify];

            [[NSNotificationCenter defaultCenter] addObserverForName:NSFileHandleDataAvailableNotification object:[weakself._outputPipe fileHandleForReading] queue:nil usingBlock:^(NSNotification *notification){

                NSData *output = [[weakself._outputPipe fileHandleForReading] availableData];
                NSString *outStr = [[NSString alloc] initWithData:output encoding:NSUTF8StringEncoding];
                if (self.logPath) {
                    NSString* logFile = [weakself logFilePathForDate:[NSDate date]];
//                    NSLog(@"Log file at:%@",logFile);
                    NSFileHandle * fileHandle = [NSFileHandle fileHandleForWritingAtPath:logFile];
                    if (!fileHandle) {
                        [outStr writeToFile:logFile atomically:YES encoding:NSUTF8StringEncoding error:nil];
                    } else {
                        [fileHandle seekToEndOfFile];
                        [fileHandle writeData:output];
                        [fileHandle closeFile];
                    }
                }

//               dispatch_sync(dispatch_get_main_queue(), ^{
//                    weakself.outputText.string = [weakself.outputText.string stringByAppendingString:[NSString stringWithFormat:@"\n%@", outStr]];
//                    // Scroll to end of outputText field
//                    NSRange range;
//                    range = NSMakeRange([weakself.outputText.string length], 0);
//                    [weakself._outputText scrollRangeToVisible:range];
//                });

                [[weakself._outputPipe fileHandleForReading] waitForDataInBackgroundAndNotify];
            }];

            [weakself._stTask launch];

            [weakself._stTask waitUntilExit];
        }
        @catch (NSException *exception) {
            NSLog(@"Problem Running Task: %@", [exception description]);
        }
        @finally {
            weakself.isRunning = NO;
            weakself._stTask = nil;
        }
    });
}

// Interrupts syncthing and block-waits until exit
- (void)stopExecutable {
    if (!self._stTask)
        return;

    [self._stTask interrupt];
    [self._stTask waitUntilExit];
}


#pragma mark - Helpers
-(NSString*) logFilePathForDate: (NSDate*) date
{
    NSString* logFile = [[[[self._dateFormatter stringFromDate:date] stringByReplacingOccurrencesOfString:@" " withString:@"_"] stringByReplacingOccurrencesOfString:@"," withString:@""] stringByAppendingString:@".log"];
    return [self.logPath stringByAppendingPathComponent:logFile];
}

@end
