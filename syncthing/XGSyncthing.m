#import "XGSyncthing.h"

@interface XGSyncthing()<NSURLSessionDelegate>

@property NSTask *StTask;
@property (nonatomic, strong) NSXMLParser *configParser;
@property (nonatomic, strong) NSMutableArray<NSString *> *parsing;
@property (nonatomic, strong) NSURLSession* syncthingSession;
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


#pragma mark - API setup


- (void) URLSession:(NSURLSession *)session
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
  completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    
    // Accept self-signed certificates
    if (challenge.protectionSpace.serverTrust) {
        NSURLCredential* cred = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential,cred);
    }
    
}

#pragma mark - API 

- (bool) runExecutable
{
    _StTask = [[NSTask alloc] init];
    
    [_StTask setLaunchPath:_Executable];
    [_StTask setArguments:@[@"-no-browser"]];
    [_StTask setQualityOfService:NSQualityOfServiceBackground];
    [_StTask launch];
    
    return true;
}

- (void) stopExecutable
{
    if (!_StTask)
        return;
    
    [_StTask interrupt];
    [_StTask waitUntilExit];
}

- (void)ping:(void (^)(BOOL flag))completionBlock
{
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

//- (id)getUptime
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

- (void) getMyID:(void (^)(id folders))completionBlock
{
    NSMutableURLRequest *theRequest=[NSMutableURLRequest
                                     requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", _URI, @"/rest/system/status"]]
                                     cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0];
    
    [theRequest setHTTPMethod:@"GET"];
    [theRequest setValue:_apiKey forHTTPHeaderField:@"X-API-Key"];
    
    NSURLSessionDataTask* dataTask = [self.syncthingSession dataTaskWithRequest:theRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSError *myError = nil;
        
        if (!error) {
            id json = [NSJSONSerialization JSONObjectWithData:data options:
                       NSJSONReadingMutableContainers error:&myError];
            completionBlock ([json objectForKey:@"myID"]);
        } else {
            completionBlock(nil);
        }
    }];
    [dataTask resume];
    
}

- (void)getFolders:(void (^)(id folders))completionBlock
{
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

#pragma mark - Config File handling

- (void)loadConfigurationFromXML
{
    NSError* error;
    NSURL *supURL = [[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory
                                                           inDomain:NSUserDomainMask
                                                  appropriateForURL:nil
                                                             create:NO
                                                              error:&error];
    NSURL* configUrl = [supURL URLByAppendingPathComponent:@"Syncthing/config.xml"];
    _configParser = [[NSXMLParser alloc] initWithContentsOfURL:configUrl];
    [_configParser setDelegate:self];
    [_configParser parse];
}

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary<NSString *,NSString *> *)attributeDict {
    [_parsing addObject:elementName];
    NSString *keyPath = [_parsing componentsJoinedByString:@"."];
    
    if ([keyPath isEqualToString:@"configuration.gui"]) {
        if ([[[attributeDict objectForKey:@"tls"] lowercaseString] isEqualToString:@"true"]) {
            _URI = @"https://";
        } else {
            _URI = @"http://";
        }
    }
}

-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    [_parsing removeLastObject];
}

-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    NSString *keyPath = [_parsing componentsJoinedByString:@"."];
    
    if ([keyPath isEqualToString:@"configuration.gui.apikey"]) {
        _apiKey = [_apiKey stringByAppendingString:string];
    } else if  ([keyPath isEqualToString:@"configuration.gui.address"]) {
        _URI = [_URI stringByAppendingString:string];
    }
}

@end
