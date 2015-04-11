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

#import <AVFoundation/AVFoundation.h>

@interface VideoCallViewController () <RTCPeerConnectionDelegate>
{
    RTCVideoTrack *localVideoTrack;
    RTCVideoTrack *remoteVideoTrack;
}
@property (nonatomic) VideoCallView *videoCallView;
@property (nonatomic) RTCPeerConnectionFactory *factory;
@property (nonatomic) RTCMediaStream *localMediaStream;
@end

@implementation VideoCallViewController

- (id)initWithRoomId:(NSInteger)roomId {
    self = [super init];
    if (self) {
        self.factory = [[RTCPeerConnectionFactory alloc] init];
    }
    return self;
}

- (void)loadView {
    self.title = @"Video Call View Controller";
    
    self.videoCallView = [[VideoCallView alloc] initWithFrame:CGRectZero];
    self.videoCallView.backgroundColor = [UIColor redColor];
//    self.videoCallView.delegate = self;
//    self.videoCallView.statusLabel.text = [self statusTextForState:RTCICEConnectionNew];
    self.view = self.videoCallView;
    
    ALog(@"Load View");
    
    self.localMediaStream = [self createLocalMediaStream];
    
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

// Get Stream
- (RTCMediaStream *)createLocalMediaStream {
    ALog(@"");
    RTCMediaStream* localStream = [self.factory mediaStreamWithLabel:@"ARDAMS"];
//    RTCVideoTrack* localVideoTrack = nil;
    
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
//    [_delegate appClient:self didReceiveLocalVideoTrack:localVideoTrack];
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
        //    if (stream.videoTracks.count) {
        //      RTCVideoTrack *videoTrack = stream.videoTracks[0];
        //      [_delegate appClient:self didReceiveRemoteVideoTrack:videoTrack];
        //    }
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
        ALog(@"8");
//        ARDICECandidateMessage *message =
//        [[ARDICECandidateMessage alloc] initWithCandidate:candidate];
//        [self sendSignalingMessage:message];
    });
}

- (void)peerConnection:(RTCPeerConnection*)peerConnection
    didOpenDataChannel:(RTCDataChannel*)dataChannel {
}



@end
