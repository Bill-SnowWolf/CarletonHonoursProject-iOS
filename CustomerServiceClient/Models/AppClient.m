//
//  AppClient.m
//  CustomerServiceClient
//
//  Created by Xingnan Zhou on 2015-04-17.
//  Copyright (c) 2015 SnowWolf. All rights reserved.
//

#import "AppClient.h"
#import "RTCVideoTrack.h"
#import "RTCMediaStream.h"
#import "RTCPeerConnectionDelegate.h"
#import "RTCPeerConnectionFactory.h"
#import "RTCVideoCapturer.h"
#import "RTCMediaConstraints.h"
#import "RTCPair.h"
#import "RTCPeerConnection.h"
#import "RTCSessionDescriptionDelegate.h"
#import "RTCICECandidate+JSON.h"
#import "RTCSessionDescription+JSON.h"
#import "Pusher.h"
#import "RTCICEServer.h"
#import "NetworkManager.h"

#import <AVFoundation/AVFoundation.h>

@interface AppClient ()
@property (nonatomic) RTCPeerConnectionFactory *factory;
@property (nonatomic) RTCMediaStream *localMediaStream;
@property (nonatomic) RTCPeerConnection *peerConnection;
@property (nonatomic) PTPusher *pusher;
@property (nonatomic) PTPusherPrivateChannel *privateChannel;
@property (nonatomic) RTCICEConnectionState connectionState;
@property (nonatomic) BOOL started;

@property (nonatomic) NSMutableArray *iceServers;
@end

@implementation AppClient
- (id)initWithDelegate:(id<AppClientDelegate>)delegate {
    self = [super init];
    if (self) {
        self.delegate = delegate;
    }
    return self;
}

- (void)checkAvailableRepresentatives {
    [NetworkManager sendServiceRequestWithCompletionHandler:^(NSDictionary *responseDict) {
        dispatch_async(dispatch_get_main_queue(), ^() {
            self.roomNumber = [responseDict[@"room"] integerValue];
            self.callId = [responseDict[@"id"] integerValue];
            
            if ([responseDict[@"code"] isEqualToString:@"AVAILABLE"]) {
                _state = kAppClientStateConnecting;
                [self.delegate appClient:self didChangeState:kAppClientStateConnecting object:responseDict[@"room"]];
//                [self.delegate appClient:self didFindAvailableRepresentative:self.roomNumber];
//                [self connectToRoomWithId:self.roomNumber];
//                [self makeCall:[responseDict[@"room"] integerValue]];
            } else {
                _state = kAppClientStateWaiting;
                [self.delegate appClient:self didChangeState:kAppClientStateWaiting object:responseDict[@"waiting_count"]];
//                NSString *status = [NSString stringWithFormat:@"Sorry, all representatives are on the line. Please wait... There are %@ in front of you", responseDict[@"waiting_count"]];
//                [self.videoCallView appendStatus:status];
            }
        });
    }];
}

- (void)connectToRoomWithId:(NSInteger)roomId {
    
}

- (void)disconnect {
    
}

#pragma mark - Custom Setters

@end
