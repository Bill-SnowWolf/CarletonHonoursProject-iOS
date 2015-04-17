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
#import "RTCPeerConnectionDefaults.h"

#import <AVFoundation/AVFoundation.h>

@interface AppClient () <PTPusherDelegate, RTCPeerConnectionDelegate, RTCSessionDescriptionDelegate>
@property (nonatomic) RTCPeerConnectionFactory *factory;
@property (nonatomic) RTCMediaStream *localMediaStream;
@property (nonatomic) RTCPeerConnection *peerConnection;
@property (nonatomic) PTPusher *pusher;
@property (nonatomic) PTPusherPrivateChannel *privateChannel;
@property (nonatomic) RTCICEConnectionState connectionState;
@property (nonatomic) BOOL started;
@property (nonatomic, getter=isInitiator) BOOL initiator;

@property (nonatomic) NSMutableArray *iceServers;
@end

@implementation AppClient
- (id)initWithDelegate:(id<AppClientDelegate>)delegate {
    self = [super init];
    if (self) {
        self.delegate = delegate;
        self.initiator = NO;
        self.started = NO;
    }
    return self;
}

- (void)config {
    self.factory = [[RTCPeerConnectionFactory alloc] init];
    self.iceServers = [NSMutableArray arrayWithObject:[RTCPeerConnectionDefaults defaultSTUNServer]];
}

- (void)checkAvailableRepresentatives {
    [NetworkManager sendServiceRequestWithCompletionHandler:^(NSDictionary *responseDict) {
        dispatch_async(dispatch_get_main_queue(), ^() {
            self.roomNumber = responseDict[@"room"];
            self.callId = responseDict[@"id"];
            
            if ([responseDict[@"code"] isEqualToString:@"AVAILABLE"]) {
                _state = kAppClientStateConnecting;
                [self.delegate appClient:self didChangeState:kAppClientStateConnecting object:self.roomNumber];
//                [self.delegate appClient:self didFindAvailableRepresentative:self.roomNumber];
                [self connectToRoomWithId:self.roomNumber];
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

- (void)connectToRoomWithId:(NSString *)roomId {
    [self config];
    
    // Create Instance of RTCPeerConnection
    RTCMediaConstraints *constraints = [RTCPeerConnectionDefaults defaultPeerConnectionConstraints];
    self.peerConnection = [_factory peerConnectionWithICEServers:self.iceServers
                                                     constraints:constraints
                                                        delegate:self];
    
    
    self.started = YES;
    self.localMediaStream = [self createLocalMediaStream];
    [self.peerConnection addStream:self.localMediaStream];

    // Initialize Pusher Signaling
    self.pusher = [PTPusher pusherWithKey:@"bb5a0d0fedc8e9367e47" delegate:self encrypted:YES];
    self.pusher.authorizationURL = [NSURL URLWithString:
                                    [NSString stringWithFormat:@"%@/pusher/auth_video", HOST]];
    [self.pusher connect];

    NSString *channelName = [NSString stringWithFormat:@"video-%@", roomId];
    NSDictionary *auth = @{@"room_number": roomId};
    self.privateChannel = [self.pusher subscribeToPrivateChannelNamed:channelName auth:auth];

    [self.privateChannel bindToEventNamed:@"client-offer" handleWithBlock:^(PTPusherEvent *event) {
        // Receive Offer from web
        NSDictionary *offer = [NSDictionary dictionaryWithDictionary:event.data];
        ALog(@"Client-Offer %@", offer);
        RTCSessionDescription *remoteDescription = [RTCSessionDescription descriptionFromJSONDictionary:offer];
        [self.peerConnection setRemoteDescriptionWithDelegate:self sessionDescription:remoteDescription];
    }];
    
    [self.privateChannel bindToEventNamed:@"client-answer" handleWithBlock:^(PTPusherEvent *event) {
        NSDictionary *answer = [NSDictionary dictionaryWithDictionary:event.data];
        RTCSessionDescription *remoteDescription = [RTCSessionDescription descriptionFromJSONDictionary:answer];
        ALog(@"Remote Description: %@", answer);
        [self.peerConnection setRemoteDescriptionWithDelegate:self sessionDescription:remoteDescription];
    }];
    
    [self.privateChannel bindToEventNamed:@"client-icecandidate" handleWithBlock:^(PTPusherEvent *event) {
        NSLog(@"Client-IceCandidate %@", event.data);
        
        NSDictionary *jsonDictionary = [NSDictionary dictionaryWithDictionary:event.data];
        
        RTCICECandidate *iceCandidate = [RTCICECandidate candidateFromJSONDictionary:jsonDictionary];
        [self.peerConnection addICECandidate:iceCandidate];
        
    }];
    
    self.initiator = YES;
    [self.peerConnection createOfferWithDelegate:self constraints:[RTCPeerConnectionDefaults defaultMediaStreamConstraints]];
}

- (void)disconnect {
    [NetworkManager updateCallStatusWithId:self.callId room:self.roomNumber status:@"disconnected"];
    
    if (self.pusher != nil) {
        [self.pusher disconnect];
    }
    self.peerConnection = nil;
    self.pusher = nil;
}

#pragma mark - Private
// Get Stream
- (RTCMediaStream *)createLocalMediaStream {
    RTCMediaStream* localStream = [self.factory mediaStreamWithLabel:@"ARDAMS"];
    
#if !TARGET_IPHONE_SIMULATOR && TARGET_OS_IPHONE
    /* NSString *cameraID = nil;
     for (AVCaptureDevice *captureDevice in
     [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
     if (captureDevice.position == AVCaptureDevicePositionFront) {
     cameraID = [captureDevice localizedName];
     break;
     }
     }
     NSAssert(cameraID, @"Unable to get the front camera id");
     
     RTCVideoCapturer *capturer = [RTCVideoCapturer capturerWithDeviceName:cameraID];
     RTCMediaConstraints *mediaConstraints = [self defaultMediaStreamConstraints];
     RTCVideoSource *videoSource = [self.factory videoSourceWithCapturer:capturer
     constraints:mediaConstraints];
     localVideoTrack = [self.factory videoTrackWithID:@"ARDAMSv0" source:videoSource];
     if (localVideoTrack) {
     [localStream addVideoTrack:localVideoTrack];
     }*/
#endif
    [localStream addAudioTrack:[self.factory audioTrackWithID:@"ARDAMSa0"]];
    
    //    [localVideoTrack addRenderer:self.videoCallView.localVideoView];
    
    return localStream;
}

//- (RTCICEServer *)defaultSTUNServer {
//    NSURL *defaultSTUNServerURL = [NSURL URLWithString:defaultSTUNServerURL];
//    return [[RTCICEServer alloc] initWithURI:defaultSTUNServerURL
//                                    username:@""
//                                    password:@""];
//}


#pragma mark - Pusher Signaling
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
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Authorization Failed" message:[NSString stringWithFormat:@"Client with socket ID %@ could not be authorized to join channel %@", pusher.connection.socketID, channel.name] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
//    [alert show];
}

- (void)pusher:(PTPusher *)pusher didReceiveErrorEvent:(PTPusherErrorEvent *)errorEvent
{
    NSLog(@"[pusher-%@] Received error event %@", pusher.connection.socketID, errorEvent);
}

#pragma mark - <RTCPeerConnection>
// Callbacks for this delegate occur on non-main thread and need to be
// dispatched back to main queue as needed.

- (void)peerConnection:(RTCPeerConnection *)peerConnection
 signalingStateChanged:(RTCSignalingState)stateChanged {
    ALog(@"Signaling state changed: %d", stateChanged);
}

// onaddstream
- (void)peerConnection:(RTCPeerConnection *)peerConnection
           addedStream:(RTCMediaStream *)stream {
    dispatch_async(dispatch_get_main_queue(), ^{
        ALog(@"Received %lu video tracks and %lu audio tracks",
             (unsigned long)stream.videoTracks.count,
             (unsigned long)stream.audioTracks.count);
    });
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
         removedStream:(RTCMediaStream *)stream {
    ALog(@"Stream was removed.");
}

- (void)peerConnectionOnRenegotiationNeeded:
(RTCPeerConnection *)peerConnection {
    ALog(@"WARNING: Renegotiation needed but unimplemented.");
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
  iceConnectionChanged:(RTCICEConnectionState)newState {
    dispatch_async(dispatch_get_main_queue(), ^{
        ALog(@"ICE state changed: %d", newState);
        self.connectionState = newState;
        switch (newState) {
            case RTCICEConnectionConnected:
                _state = kAppClientStateConnected;
                [self.delegate appClient:self didChangeState:kAppClientStateConnected object:nil];
//                [NetworkManager updateCallStatusWithId:self.callId room:self.roomNumber status:@"connected"];
//                [self.videoCallView appendStatus:[self statusTextForState:newState]];
                break;
            case RTCICEConnectionClosed:
            case RTCICEConnectionDisconnected:
            case RTCICEConnectionFailed:
                _state = kAppClientStateDisconnected;
                [self.delegate appClient:self didChangeState:kAppClientStateDisconnected object:nil];
//                [self.videoCallView appendStatus:[self statusTextForState:newState]];
//                [self disconnect];
                break;
            default:
                break;
                
        }
    });
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
   iceGatheringChanged:(RTCICEGatheringState)newState {
    NSLog(@"ICE gathering state changed: %d", newState);
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
       gotICECandidate:(RTCICECandidate *)candidate {
    // onicecandidate
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *dict = [candidate JSONDictionary];
        ALog(@"8 %@", dict);
        [self.privateChannel triggerEventNamed:@"client-icecandidate" data:dict];
    });
}

- (void)peerConnection:(RTCPeerConnection*)peerConnection
    didOpenDataChannel:(RTCDataChannel*)dataChannel {
}

#pragma mark - <RTCSessionDescriptionDelegate>
// Callbacks for this delegate occur on non-main thread and need to be
// dispatched back to main queue as needed.

- (void)peerConnection:(RTCPeerConnection *)peerConnection didCreateSessionDescription:(RTCSessionDescription *)sdp error:(NSError *)error {
    
    ALog(@"4");
    dispatch_async(dispatch_get_main_queue(), ^{
        if (error) {
            ALog(@"Failed to create session description. Error: %@", error);
            return;
        }
        [self.peerConnection setLocalDescriptionWithDelegate:self
                                          sessionDescription:sdp];
        ALog(@"6 type: %@", sdp.type);
        NSString *eventName = [NSString stringWithFormat:@"client-%@", sdp.type];
        [self.privateChannel triggerEventNamed:eventName data:[sdp JSONDictionary]];
    });
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
didSetSessionDescriptionWithError:(NSError *)error {
    ALog(@"5");
    dispatch_async(dispatch_get_main_queue(), ^{
        if (error) {
            ALog(@"Failed to set session description. Error: %@", error);
            return;
        }
        // If we're answering and we've just set the remote offer we need to create
        // an answer and set the local description.
        if (!self.isInitiator && !self.peerConnection.localDescription) {
            ALog(@"7");
            [self.peerConnection createAnswerWithDelegate:self constraints:[RTCPeerConnectionDefaults defaultOfferConstraints]];
        }
    });
}

@end
