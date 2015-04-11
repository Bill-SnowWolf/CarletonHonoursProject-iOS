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

@interface VideoCallViewController ()
{
    RTCVideoTrack *localVideoTrack;
    RTCVideoTrack *remoteVideoTrack;
}
@property (nonatomic) VideoCallView *videoCallView;
@end

@implementation VideoCallViewController

- (id)initWithRoomId:(NSInteger)roomId {
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)loadView {
    self.videoCallView = [[VideoCallView alloc] initWithFrame:CGRectZero];
//    self.videoCallView.delegate = self;
    self.videoCallView.statusLabel.text =
    [self statusTextForState:RTCICEConnectionNew];
    self.view = _videoCallView;
    
    ALog(@"Load View");

}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


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



@end
