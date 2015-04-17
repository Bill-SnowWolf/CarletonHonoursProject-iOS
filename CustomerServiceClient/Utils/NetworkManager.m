//
//  NetworkManager.m
//  CustomerServiceClient
//
//  Created by Xingnan Zhou on 2015-04-15.
//  Copyright (c) 2015 SnowWolf. All rights reserved.
//

#import "NetworkManager.h"

@implementation NetworkManager

+ (void)sendServiceRequestWithCompletionHandler:(void (^)(NSDictionary *))completion {
//    NSString *credential = [[[NSString alloc] initWithFormat:@"%@:%@", email, password] base64EncodedString];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *requestDict = @{
        @"device_token": [userDefaults objectForKey:@"deviceToken"]
    };
//    NSDictionary *requestDict = [[NSDictionary alloc] initWithObjectsAndKeys:credential, @"user", nil];
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestDict options:0 error:nil];
    
    NSURLRequest *request = [NetworkManager createRequestWithMethod:@"POST" data:requestData api:@"/api/service_calls"];
    
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        @autoreleasepool {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (data != nil && httpResponse.statusCode == 200) {
                NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                ALog(@"%@", responseDict);
                completion(responseDict);
            } else {
                completion(nil);
            }
        }
    }] resume];
}

+ (void)updateCallStatusWithId:(NSString *)callId room:(NSString *)room status:(NSString *)status {
    NSDictionary *callDict = @{
                                  @"id": callId,
                                  @"room": room,
                                  @"status": status
                                  };
    NSDictionary *requestDict = @{
                                  @"service_call": callDict
                                  };
    
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestDict options:0 error:nil];
    
    NSURLRequest *request = [NetworkManager createRequestWithMethod:@"PUT" data:requestData api:
                             [NSString stringWithFormat:@"/api/service_calls/%@", callId]];
    
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        @autoreleasepool {

        }
    }] resume];

}

#pragma mark - Private Methods
+ (NSURLRequest *)createRequestWithMethod:(NSString *)method data:(NSData *)data api:(NSString *)api
{
    NSString *urlString = [[NSString alloc] initWithFormat:@"%@%@", HOST, api];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
    [request setHTTPMethod:method];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-type"];
    [request setHTTPBody:data];
    return (NSURLRequest *)request;
}

+ (NSURLRequest *)createGETRequestWithAPI:(NSString *)api
{
    NSString *urlString = [[NSString alloc] initWithFormat:@"%@%@", HOST, api];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
    [request setHTTPMethod:@"GET"];
    return (NSURLRequest *)request;
    
}

@end
