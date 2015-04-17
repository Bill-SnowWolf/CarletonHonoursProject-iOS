//
//  RTCPeerConnectionDefaults.m
//  CustomerServiceClient
//
//  Created by Xingnan Zhou on 2015-04-17.
//  Copyright (c) 2015 SnowWolf. All rights reserved.
//

#import "RTCPeerConnectionDefaults.h"
#import "RTCMediaConstraints.h"
#import "RTCPair.h"
#import "RTCICEServer.h"

static NSString * const kARDDefaultSTUNServerUrl =
@"stun:stun.l.google.com:19302";

@implementation RTCPeerConnectionDefaults
#pragma mark - Defaults
+ (RTCMediaConstraints *)defaultMediaStreamConstraints {
    RTCMediaConstraints* constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:nil optionalConstraints:nil];
    return constraints;
}

+ (RTCMediaConstraints *)defaultPeerConnectionConstraints {
    NSArray *optionalConstraints = @[
                                     [[RTCPair alloc] initWithKey:@"DtlsSrtpKeyAgreement" value:@"true"]
                                     ];
    RTCMediaConstraints* constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:nil optionalConstraints:optionalConstraints];
    return constraints;
}

+ (RTCMediaConstraints *)defaultOfferConstraints {
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

+ (RTCICEServer *)defaultSTUNServer {
    NSURL *defaultSTUNServerURL = [NSURL URLWithString:kARDDefaultSTUNServerUrl];
    return [[RTCICEServer alloc] initWithURI:defaultSTUNServerURL
                                    username:@""
                                    password:@""];
}

@end
