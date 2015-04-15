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

#import <AVFoundation/AVFoundation.h>

@interface VideoCallViewController () <RTCPeerConnectionDelegate, RTCSessionDescriptionDelegate, PTPusherDelegate>
{
    RTCVideoTrack *localVideoTrack;
    RTCVideoTrack *remoteVideoTrack;
    BOOL isInitiator;
}
@property (nonatomic) VideoCallView *videoCallView;
@property (nonatomic) RTCPeerConnectionFactory *factory;
@property (nonatomic) RTCMediaStream *localMediaStream;
@property (nonatomic) RTCPeerConnection *peerConnection;
@property (nonatomic) PTPusher *pusher;
@property (nonatomic) PTPusherPrivateChannel *privateChannel;
@end

@implementation VideoCallViewController

- (id)initWithRoomId:(NSInteger)roomId {
    self = [super init];
    if (self) {
        self.factory = [[RTCPeerConnectionFactory alloc] init];
        
        // Create Instance of RTCPeerConnection
        RTCMediaConstraints *constraints = [self defaultPeerConnectionConstraints];
        self.peerConnection = [_factory peerConnectionWithICEServers:nil
                                                         constraints:constraints
                                                            delegate:self];
        
        isInitiator = NO;
        
        
        // Initialize Pusher Signaling
        
        self.pusher = [PTPusher pusherWithKey:@"bb5a0d0fedc8e9367e47" delegate:self encrypted:YES];
        self.pusher.authorizationURL = [NSURL URLWithString:@"http://192.168.1.119:3000/pusher/auth_video"];
        [self.pusher connect];
        
        self.privateChannel = [self.pusher subscribeToPrivateChannelNamed:@"video-1" auth:@{@"room_number":@"1"}];
        
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
            [self.peerConnection setRemoteDescriptionWithDelegate:self sessionDescription:remoteDescription];
        }];
        
        [self.privateChannel bindToEventNamed:@"client-icecandidate" handleWithBlock:^(PTPusherEvent *event) {
            NSLog(@"Client-IceCandidate %@", event.data);
            
            NSDictionary *jsonDictionary = [NSDictionary dictionaryWithDictionary:event.data];
            
            RTCICECandidate *iceCandidate = [RTCICECandidate candidateFromJSONDictionary:jsonDictionary];
            [self.peerConnection addICECandidate:iceCandidate];
            
        }];
        
//        [channel bindToEventNamed:@"pusher:subscription_succeeded" handleWithBlock:^(PTPusherEvent *event) {
//            NSLog(@"Subscription succeeded");
//        }];
        
    }
    return self;
}

- (void)loadView {
    self.title = @"Video Call View Controller";
    
    UIBarButtonItem *startBarItem = [[UIBarButtonItem alloc] initWithTitle:@"Call" style:UIBarButtonItemStylePlain target:self action:@selector(makeCall)];
    self.navigationItem.rightBarButtonItem = startBarItem;
    
    
    // Initialize WebRTC Views
    self.videoCallView = [[VideoCallView alloc] initWithFrame:CGRectZero];
    self.videoCallView.backgroundColor = [UIColor redColor];
    self.videoCallView.statusLabel.text = [self statusTextForState:RTCICEConnectionNew];
    self.view = self.videoCallView;
    
    ALog(@"Load View");
    
    self.localMediaStream = [self createLocalMediaStream];
    [self.peerConnection addStream:self.localMediaStream];
}

- (void)makeCall {
    isInitiator = YES;
    [self.peerConnection createOfferWithDelegate:self constraints:[self defaultMediaStreamConstraints]];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

// Get Stream
- (RTCMediaStream *)createLocalMediaStream {
    ALog(@"");
    RTCMediaStream* localStream = [self.factory mediaStreamWithLabel:@"ARDAMS"];
    
    // The iOS simulator doesn't provide any sort of camera capture
    // support or emulation (http://goo.gl/rHAnC1) so don't bother
    // trying to open a local stream.
#if !TARGET_IPHONE_SIMULATOR && TARGET_OS_IPHONE
    NSString *cameraID = nil;
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
    ALog(@"%@", localVideoTrack);
    if (localVideoTrack) {
        [localStream addVideoTrack:localVideoTrack];
    }
#endif
    [localStream addAudioTrack:[self.factory audioTrackWithID:@"ARDAMSa0"]];
    
    [localVideoTrack addRenderer:self.videoCallView.localVideoView];
    
    return localStream;
}

- (NSString *)statusTextForState:(RTCICEConnectionState)state {
    switch (state) {
        case RTCICEConnectionNew:
        case RTCICEConnectionChecking:
            return @"Connecting...";
        case RTCICEConnectionConnected:
        case RTCICEConnectionCompleted:
        case RTCICEConnectionFailed:
        case RTCICEConnectionDisconnected:
        case RTCICEConnectionClosed:
            return nil;
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
                                      [[RTCPair alloc] initWithKey:@"OfferToReceiveVideo" value:@"true"]
                                      ];
    RTCMediaConstraints* constraints =
    [[RTCMediaConstraints alloc]
     initWithMandatoryConstraints:mandatoryConstraints
     optionalConstraints:nil];
    return constraints;
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
        //      [_delegate appClient:self didReceiveRemoteVideoTrack:videoTrack];
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
    ALog(@"ICE state changed: %d", newState);
    dispatch_async(dispatch_get_main_queue(), ^{
//        [_delegate appClient:self didChangeConnectionState:newState];
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
//        ARDICECandidateMessage *message =
//        [[ARDICECandidateMessage alloc] initWithCandidate:candidate];
//        [self sendSignalingMessage:message];
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
//            [self disconnect];
//            NSDictionary *userInfo = @{
//                                       NSLocalizedDescriptionKey: @"Failed to create session description.",
//                                       };
//            NSError *sdpError =
//            [[NSError alloc] initWithDomain:kARDAppClientErrorDomain
//                                       code:kARDAppClientErrorCreateSDP
//                                   userInfo:userInfo];
//            [_delegate appClient:self didError:sdpError];
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
//            [self disconnect];
//            NSDictionary *userInfo = @{
//                                       NSLocalizedDescriptionKey: @"Failed to set session description.",
//                                       };
//            NSError *sdpError =
//            [[NSError alloc] initWithDomain:kARDAppClientErrorDomain
//                                       code:kARDAppClientErrorSetSDP
//                                   userInfo:userInfo];
//            [_delegate appClient:self didError:sdpError];
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