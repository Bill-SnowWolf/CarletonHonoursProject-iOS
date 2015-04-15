//
//  ViewController.m
//  CustomerServiceClient
//
//  Created by Xingnan Zhou on 2015-03-14.
//  Copyright (c) 2015 SnowWolf. All rights reserved.
//

#import "ViewController.h"
#import "VideoCallViewController.h"
#import "NetworkManager.h"

@interface ViewController ()
//@property (nonatomic, strong) PTPusher *client;

- (IBAction)prepare:(id)sender;
- (IBAction)request:(id)sender;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];    
}

- (IBAction)prepare:(id)sender {
    VideoCallViewController *viewController = [[VideoCallViewController alloc] init];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (IBAction)request:(id)sender {
    [NetworkManager sendServiceRequestWithCompletionHandler:^(NSDictionary *responseDict) {
        dispatch_async(dispatch_get_main_queue(), ^() {
            
        });
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//#pragma mark <PTPusherPresenceChannelDelegate>
//- (void)presenceChannel:(PTPusherPresenceChannel *)channel memberAdded:(PTPusherChannelMember *)member {
//    NSLog(@"Member Added");
//}
//
//- (void)presenceChannel:(PTPusherPresenceChannel *)channel memberRemoved:(PTPusherChannelMember *)member {
//    NSLog(@"Member Removed");
//}
//
//- (void)presenceChannelDidSubscribe:(PTPusherPresenceChannel *)channel {
//     NSLog(@"Did Subscribe");
//}
/*
#pragma mark - PTPusherDelegate methods

- (BOOL)pusher:(PTPusher *)pusher connectionWillConnect:(PTPusherConnection *)connection
{
    NSLog(@"[pusher] Pusher client connecting...");
    return YES;
}

- (void)pusher:(PTPusher *)pusher connectionDidConnect:(PTPusherConnection *)connection
{
    NSLog(@"[pusher-%@] Pusher client connected", connection.socketID);
    

}

- (void)pusher:(PTPusher *)pusher connection:(PTPusherConnection *)connection failedWithError:(NSError *)error
{
    NSLog(@"[pusher] Pusher Connection failed with error: %@", error);
    if ([error.domain isEqualToString:(NSString *)kCFErrorDomainCFNetwork]) {
//        [self startReachabilityCheck];
    }
}

- (void)pusher:(PTPusher *)pusher connection:(PTPusherConnection *)connection didDisconnectWithError:(NSError *)error willAttemptReconnect:(BOOL)willAttemptReconnect
{
    NSLog(@"[pusher-%@] Pusher Connection disconnected with error: %@", pusher.connection.socketID, error);
    
    if (willAttemptReconnect) {
        NSLog(@"[pusher-%@] Client will attempt to reconnect automatically", pusher.connection.socketID);
    }
    else {
        if (![error.domain isEqualToString:PTPusherErrorDomain]) {
//            [self startReachabilityCheck];
        }
    }
}

- (BOOL)pusher:(PTPusher *)pusher connectionWillAutomaticallyReconnect:(PTPusherConnection *)connection afterDelay:(NSTimeInterval)delay
{
    NSLog(@"[pusher-%@] Client automatically reconnecting after %d seconds...", pusher.connection.socketID, (int)delay);
    return YES;
}

- (void)pusher:(PTPusher *)pusher didSubscribeToChannel:(PTPusherChannel *)channel
{
    NSLog(@"[pusher-%@] Subscribed to channel %@", pusher.connection.socketID, channel);
}

- (void)pusher:(PTPusher *)pusher didFailToSubscribeToChannel:(PTPusherChannel *)channel withError:(NSError *)error
{
    NSLog(@"[pusher-%@] Authorization failed for channel %@", pusher.connection.socketID, channel);
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Authorization Failed" message:[NSString stringWithFormat:@"Client with socket ID %@ could not be authorized to join channel %@", pusher.connection.socketID, channel.name] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

- (void)pusher:(PTPusher *)pusher didReceiveErrorEvent:(PTPusherErrorEvent *)errorEvent
{
    NSLog(@"[pusher-%@] Received error event %@", pusher.connection.socketID, errorEvent);
}

*/
@end
