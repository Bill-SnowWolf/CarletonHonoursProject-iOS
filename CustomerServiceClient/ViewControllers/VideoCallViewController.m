//
//  VideoCallViewController.m
//  CustomerServiceClient
//
//  Created by Xingnan Zhou on 2015-04-11.
//  Copyright (c) 2015 SnowWolf. All rights reserved.
//

#import "VideoCallViewController.h"
#import "VideoCallView.h"
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

@interface VideoCallViewController () <RTCPeerConnectionDelegate, RTCSessionDescriptionDelegate, PTPusherDelegate>
{
    RTCVideoTrack *localVideoTrack;
    RTCVideoTrack *remoteVideoTrack;
    BOOL isInitiator;
}
@property (nonatomic) VideoCallView *videoCallView;
@property (nonatomic) RTCPeerConnectionFactory *factory;
@property (nonatomic, weak) RTCMediaStream *localMediaStream;
@property (nonatomic) RTCPeerConnection *peerConnection;
@property (nonatomic) PTPusher *pusher;
@property (nonatomic) PTPusherPrivateChannel *privateChannel;
@property (nonatomic) RTCICEConnectionState connectionState;
@property (nonatomic) BOOL started;

@property (nonatomic) NSInteger roomNumber;
@property (nonatomic) NSInteger callId;
@property (nonatomic) NSMutableArray *iceServers;
@end

@implementation VideoCallViewController

static NSString * const kARDDefaultSTUNServerUrl =
@"stun:stun.l.google.com:19302";


- (id)init {
    self = [super init];
    if (self) {
        [self config];
        
        // Create Instance of RTCPeerConnection
        RTCMediaConstraints *constraints = [self defaultPeerConnectionConstraints];
        self.peerConnection = [_factory peerConnectionWithICEServers:nil//self.iceServers
                                                         constraints:constraints
                                                            delegate:self];
        
        isInitiator = NO;
        self.started = NO;
        
    }
    return self;
}

- (void)config {
    self.factory = [[RTCPeerConnectionFactory alloc] init];
    self.iceServers = [NSMutableArray arrayWithObject:[self defaultSTUNServer]];
}

- (void)loadView {
    self.title = @"Video Call View Controller";
    
    // Initialize WebRTC Views
    self.videoCallView = [[VideoCallView alloc] initWithFrame:CGRectZero];
    self.videoCallView.backgroundColor = [UIColor redColor];
    [self.videoCallView appendStatus:@"Looking for available representatives..."];
    self.view = self.videoCallView;
    
    self.localMediaStream = [self createLocalMediaStream];
    [self.peerConnection addStream:self.localMediaStream];
    
    [self request];
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newRepresentative:) name:@"com.carleton.webrtc.newuser" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"com.carleton.webrtc.newuser" object:nil];
    [self disconnect];
}

- (void)disconnect {
    [NetworkManager updateCallStatusWithId:self.callId room:self.roomNumber status:@"disconnected"];
    
    if (self.pusher != nil) {
        [self.pusher disconnect];
    }
    if (remoteVideoTrack) {
        [remoteVideoTrack removeRenderer:self.videoCallView.remoteVideoView];
        remoteVideoTrack = nil;
        [self.videoCallView.remoteVideoView renderFrame:nil];
    }
    if (localVideoTrack) {
        [localVideoTrack removeRenderer:self.videoCallView.localVideoView];
        localVideoTrack = nil;
        [self.videoCallView.localVideoView renderFrame:nil];
    }
    
    self.peerConnection = nil;
    self.pusher = nil;
}

- (void)makeCall:(NSInteger)roomId {
    self.started = YES;
    
    NSString *status = [NSString stringWithFormat:@"Representative %ld is picking your call. Connecting...", (long)roomId];
    [self.videoCallView appendStatus:status];
    
    // Initialize Pusher Signaling
    self.pusher = [PTPusher pusherWithKey:@"bb5a0d0fedc8e9367e47" delegate:self encrypted:YES];
    self.pusher.authorizationURL = [NSURL URLWithString:
                                    [NSString stringWithFormat:@"%@/pusher/auth_video", HOST]];
    [self.pusher connect];
    
    NSString *channelName = [NSString stringWithFormat:@"video-%ld", (long)roomId];
    self.privateChannel = [self.pusher subscribeToPrivateChannelNamed:channelName auth:@{@"room_number":@"1"}];
    
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
    
    isInitiator = YES;
    [self.peerConnection createOfferWithDelegate:self constraints:[self defaultMediaStreamConstraints]];
}

- (void)newRepresentative:(NSNotification *)notif {
    NSDictionary *obj = [notif object];
    self.roomNumber = [obj[@"room"] integerValue];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"New Representative available, please confirm to connect or cancel" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Connect", nil];
    [alertView show];
}

- (void)request {
    [NetworkManager sendServiceRequestWithCompletionHandler:^(NSDictionary *responseDict) {
        dispatch_async(dispatch_get_main_queue(), ^() {
            self.roomNumber = [responseDict[@"room"] integerValue];
            self.callId = [responseDict[@"id"] integerValue];
            
            if ([responseDict[@"code"] isEqualToString:@"AVAILABLE"]) {
                [self makeCall:[responseDict[@"room"] integerValue]];
            } else {
                NSString *status = [NSString stringWithFormat:@"Sorry, all representatives are on the line. Please wait... There are %@ in front of you", responseDict[@"waiting_count"]];
                [self.videoCallView appendStatus:status];
            }
        });
    }];
}

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

- (NSString *)statusTextForState:(RTCICEConnectionState)state {
    switch (state) {
//        case RTCICEConnectionNew:
//        case RTCICEConnectionChecking:
//            return @"Connecting...";
        case RTCICEConnectionConnected:
        case RTCICEConnectionCompleted:
            return @"You are connected to representative now!";
        case RTCICEConnectionFailed:
        case RTCICEConnectionDisconnected:
        case RTCICEConnectionClosed:
            return @"Your call is disconnected.";
        default:
            return nil;
    }
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        // Cancel
    } else {
        // Connect
        [self makeCall:self.roomNumber];
    }
}


#pragma mark - Defaults

- (RTCMediaConstraints *)defaultMediaStreamConstraints {
    RTCMediaConstraints* constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:nil optionalConstraints:nil];
    return constraints;
}

- (RTCMediaConstraints *)defaultPeerConnectionConstraints {
    NSArray *optionalConstraints = @[
                                     [[RTCPair alloc] initWithKey:@"DtlsSrtpKeyAgreement" value:@"true"]
                                     ];
    RTCMediaConstraints* constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:nil optionalConstraints:optionalConstraints];
    return constraints;
}

- (RTCMediaConstraints *)defaultOfferConstraints {
    NSArray *mandatoryConstraints = @[
                                      [[RTCPair alloc] initWithKey:@"OfferToReceiveAudio" value:@"true"],
                                      [[RTCPair alloc] initWithKey:@"OfferToReceiveVideo" value:@"false"]
                                      ];
    RTCMediaConstraints* constraints =
    [[RTCMediaConstraints alloc]
     initWithMandatoryConstraints:mandatoryConstraints
     optionalConstraints:nil];
    return constraints;
}

- (RTCICEServer *)defaultSTUNServer {
    NSURL *defaultSTUNServerURL = [NSURL URLWithString:kARDDefaultSTUNServerUrl];
    return [[RTCICEServer alloc] initWithURI:defaultSTUNServerURL
                                    username:@""
                                    password:@""];
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
        if (stream.videoTracks.count) {
            remoteVideoTrack = stream.videoTracks[0];
            [remoteVideoTrack addRenderer:self.videoCallView.remoteVideoView];
        }
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
                [NetworkManager updateCallStatusWithId:self.callId room:self.roomNumber status:@"connected"];
                [self.videoCallView appendStatus:[self statusTextForState:newState]];
                break;
            case RTCICEConnectionClosed:
            case RTCICEConnectionDisconnected:
            case RTCICEConnectionFailed:
                [self.videoCallView appendStatus:[self statusTextForState:newState]];
                [self disconnect];
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
        if (!isInitiator && !self.peerConnection.localDescription) {
            ALog(@"7");
            [self.peerConnection createAnswerWithDelegate:self constraints:[self defaultOfferConstraints]];
        }
    });
}

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
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Authorization Failed" message:[NSString stringWithFormat:@"Client with socket ID %@ could not be authorized to join channel %@", pusher.connection.socketID, channel.name] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

- (void)pusher:(PTPusher *)pusher didReceiveErrorEvent:(PTPusherErrorEvent *)errorEvent
{
    NSLog(@"[pusher-%@] Received error event %@", pusher.connection.socketID, errorEvent);
}

/* The sample app uses HTTP basic authentication.
 
 This demonstrates how we can intercept the authorization request to configure it for our app's
 authentication/authorisation needs.
 */
- (void)pusher:(PTPusher *)pusher willAuthorizeChannelWithRequest:(NSMutableURLRequest *)request
{
    NSLog(@"[pusher-%@] Authorizing channel access...", pusher.connection.socketID);
    //    [request setHTTPBasicAuthUsername:CHANNEL_AUTH_USERNAME password:CHANNEL_AUTH_PASSWORD];
}

@end