#import "XGSyncthing.h"

@interface XGSyncthing()

@property NSTask *_StTask;
@property NSURLSession* syncthingSession;

@end

@implementation XGSyncthing {}

@synthesize Executable = _Executable;
@synthesize URI = _URI;
@synthesize ApiKey = _apiKey;

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.syncthingSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                              delegate:self
                                                         delegateQueue:nil];
    }
    return self;
}
- (bool)runExecutable
{
    self._StTask = [[NSTask alloc] init];
    [self._StTask setLaunchPath:_Executable];
    [self._StTask setArguments:@[@"-no-browser"]];
    [self._StTask launch];

    return true;
}

- (void)stopExecutable
{
    if (!self._StTask)
        return;
    
    [self._StTask interrupt];
    [self._StTask waitUntilExit];
}

- (void)ping:(void (^)(BOOL flag))completionBlock
{
//	NSURLResponse *serverResponse = nil;
	NSMutableURLRequest *theRequest=[NSMutableURLRequest
	 requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", _URI, @"/rest/system/ping"]]
	 cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0];

	[theRequest setHTTPMethod:@"GET"];
	[theRequest setValue:_apiKey forHTTPHeaderField:@"X-API-Key"];

    NSURLSessionDataTask* dataTask = [self.syncthingSession dataTaskWithRequest:theRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
          NSError *myError = nil;
          BOOL result = false;

          if (!error) {

          id json = [NSJSONSerialization JSONObjectWithData:data options:
                     NSJSONReadingMutableContainers error:&myError];

          if ([[json objectForKey:@"ping"] isEqualToString:@"pong"])
              result = true;

          }
          completionBlock(result);

    }];
    [dataTask resume];
}

- (void)getUptime:(void (^)(long uptime))completionBlock
{
    NSMutableURLRequest *theRequest=[NSMutableURLRequest
                                     requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", _URI, @"/rest/system/status"]]
                                     cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0];
    
    [theRequest setHTTPMethod:@"GET"];
    [theRequest setValue:_apiKey forHTTPHeaderField:@"X-API-Key"];

    NSURLSessionDataTask* dataTask = [self.syncthingSession dataTaskWithRequest:theRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {

        NSError *myError = nil;
        if (!error) {

            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&myError];
            completionBlock( [[json objectForKey:@"uptime"] longValue]);
            return;
        }
        completionBlock(0);
    }];
    [dataTask resume];
}

- (void)getFolders:(void (^)(id folders))completionBlock
{
//    NSData *serverData = nil;
//    NSURLResponse *serverResponse = nil;
    NSMutableURLRequest *theRequest=[NSMutableURLRequest
                                     requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", _URI, @"/rest/system/config"]]
                                     cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0];
    
    [theRequest setHTTPMethod:@"GET"];
    [theRequest setValue:_apiKey forHTTPHeaderField:@"X-API-Key"];
    NSURLSessionDataTask* dataTask = [self.syncthingSession dataTaskWithRequest:theRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSError *myError = nil;

        if (!error) {
            id json = [NSJSONSerialization JSONObjectWithData:data options:
                       NSJSONReadingMutableContainers error:&myError];
            completionBlock ([json objectForKey:@"folders"]);
        } else {
            completionBlock(nil);
        }
    }];
    [dataTask resume];
}

- (void) URLSession:(NSURLSession *)session
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
  completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {

    // Accept selfsign certificates
    if (challenge.protectionSpace.serverTrust) {
        NSURLCredential* cred = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential,cred);
    }

}

-(void)dealloc {
    NSLog(@"XGSyncthing got dealloc: %@",self);
}
@end
