//
//  VideoCallViewController.m
//  CustomerServiceClient
//
//  Created by Xingnan Zhou on 2015-04-11.
//  Copyright (c) 2015 SnowWolf. All rights reserved.
//

#import "VideoCallViewController.h"
#import "VideoCallView.h"
#import "AppClient.h"

#import <AVFoundation/AVFoundation.h>

@interface VideoCallViewController () <AppClientDelegate>
@property (nonatomic) VideoCallView *videoCallView;
@property (nonatomic) AppClient *appClient;
@end

@implementation VideoCallViewController

- (id)init {
    self = [super init];
    if (self) {
        self.appClient = [[AppClient alloc] initWithDelegate:self];
    }
    return self;
}

- (void)loadView {
    self.title = @"Video Call View Controller";
    
    // Initialize WebRTC Views
    self.videoCallView = [[VideoCallView alloc] initWithFrame:CGRectZero];
    self.videoCallView.backgroundColor = [UIColor redColor];
    [self.videoCallView appendStatus:@"Looking for available representatives..."];
    self.view = self.videoCallView;
    
    [self.appClient checkAvailableRepresentatives];
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newRepresentative:) name:@"com.carleton.webrtc.newuser" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"com.carleton.webrtc.newuser" object:nil];
    [self.appClient disconnect];
}

- (void)newRepresentative:(NSNotification *)notif {
    NSDictionary *dict = [notif object];
    self.appClient.roomNumber = dict[@"room"];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"New Representative available, please confirm to connect or cancel" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Connect", nil];
    [alertView show];
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        // Cancel
    } else {
        // Connect
        [self.appClient connectToRoomWithId:self.appClient.roomNumber];
    }
}

#pragma mark <AppClientDelegate>
- (void)appClient:(AppClient *)client didChangeState:(AppClientState)state object:(NSObject *)object {
    switch (state) {
        case kAppClientStateWaiting: {
            NSString *count = (NSString *)object;
            NSString *status = [NSString stringWithFormat:@"Sorry, all representatives are on the line. Please wait... There are %@ in front of you", count];
            [self.videoCallView appendStatus:status];

            break;
        }
        case kAppClientStateConnecting: {
            NSString *roomId = (NSString *)object;
            NSString *status = [NSString stringWithFormat:@"Representative %@ is picking your call. Connecting...", roomId];
            [self.videoCallView appendStatus:status];
            break;
        }
            
        case kAppClientStateConnected: {
            [self.videoCallView appendStatus:@"You are connected to representative now!"];
            break;
        }
            
        case kAppClientStateDisconnected: {
            [self.videoCallView appendStatus:@"Your call is disconnected."];
        }
            
        default:
            break;
    }
}

- (void)appClient:(AppClient *)client didError:(NSError *)error {
    
}

@end