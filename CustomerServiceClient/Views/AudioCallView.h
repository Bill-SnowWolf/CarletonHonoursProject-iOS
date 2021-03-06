//
//  VideoCallView.h
//  CustomerServiceClient
//
//  Created by Xingnan Zhou on 2015-04-02.
//  Copyright (c) 2015 SnowWolf. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RTCEAGLVideoView.h"

@interface AudioCallView : UIView

//@property (nonatomic, readonly) UILabel *statusLabel;
//@property (nonatomic, readonly) RTCEAGLVideoView *localVideoView;
//@property (nonatomic, readonly) RTCEAGLVideoView *remoteVideoView;

- (void)appendStatus:(NSString *)status;
@end
