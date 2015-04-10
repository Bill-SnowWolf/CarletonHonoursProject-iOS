////
////  VideoCallView.m
////  CustomerServiceClient
////
////  Created by Xingnan Zhou on 2015-04-02.
////  Copyright (c) 2015 SnowWolf. All rights reserved.
////
//
//#import "VideoCallView.h"
//
//#import <AVFoundation/AVFoundation.h>
//
//static CGFloat const kHangupButtonPadding = 16;
//static CGFloat const kHangupButtonSize = 48;
//static CGFloat const kLocalVideoViewWidth = 90;
//static CGFloat const kLocalVideoViewHeight = 120;
//static CGFloat const kLocalVideoViewPadding = 8;
//
//@interface VideoCallView () <RTCEAGLVideoViewDelegate>
//{
//    CGSize _localVideoSize;
//    CGSize _remoteVideoSize;
//}
//@end
//
//@implementation VideoCallView
//
//- (id)initWithFrame:(CGRect)frame {
//    if (self = [super initWithFrame:frame]) {
//        _remoteVideoView = [[RTCEAGLVideoView alloc] initWithFrame:CGRectZero];
//        _remoteVideoView.delegate = self;
//        [self addSubview:_remoteVideoView];
//        
//        _localVideoView = [[RTCEAGLVideoView alloc] initWithFrame:CGRectZero];
//        _localVideoView.transform = CGAffineTransformMakeScale(-1, 1);
//        _localVideoView.delegate = self;
//        [self addSubview:_localVideoView];
//        
//        _statusLabel = [[UILabel alloc] initWithFrame:CGRectZero];
//        _statusLabel.font = [UIFont fontWithName:@"Roboto" size:16];
//        _statusLabel.textColor = [UIColor whiteColor];
//        [self addSubview:_statusLabel];
//    }
//    return self;
//}
//
//- (void)layoutSubviews {
//    CGRect bounds = self.bounds;
//    if (_remoteVideoSize.width > 0 && _remoteVideoSize.height > 0) {
//        // Aspect fill remote video into bounds.
//        CGRect remoteVideoFrame =
//        AVMakeRectWithAspectRatioInsideRect(_remoteVideoSize, bounds);
//        CGFloat scale = 1;
//        if (remoteVideoFrame.size.width > remoteVideoFrame.size.height) {
//            // Scale by height.
//            scale = bounds.size.height / remoteVideoFrame.size.height;
//        } else {
//            // Scale by width.
//            scale = bounds.size.width / remoteVideoFrame.size.width;
//        }
//        remoteVideoFrame.size.height *= scale;
//        remoteVideoFrame.size.width *= scale;
//        _remoteVideoView.frame = remoteVideoFrame;
//        _remoteVideoView.center =
//        CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
//    } else {
//        _remoteVideoView.frame = bounds;
//    }
//    
//    CGRect localVideoFrame = CGRectZero;
//    localVideoFrame.origin.x =
//    CGRectGetMaxX(bounds) - kLocalVideoViewWidth - kLocalVideoViewPadding;
//    localVideoFrame.origin.y =
//    CGRectGetMaxY(bounds) - kLocalVideoViewHeight - kLocalVideoViewPadding;
//    localVideoFrame.size.width = kLocalVideoViewWidth;
//    localVideoFrame.size.height = kLocalVideoViewHeight;
//    _localVideoView.frame = localVideoFrame;
//    
//    [_statusLabel sizeToFit];
//    _statusLabel.center =
//    CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
//}
//
//#pragma mark - RTCEAGLVideoViewDelegate
//
//- (void)videoView:(RTCEAGLVideoView*)videoView didChangeVideoSize:(CGSize)size {
//    if (videoView == _localVideoView) {
//        _localVideoSize = size;
//    } else if (videoView == _remoteVideoView) {
//        _remoteVideoSize = size;
//    }
//    [self setNeedsLayout];
//}
//
//#pragma mark - Private
//
//@end
