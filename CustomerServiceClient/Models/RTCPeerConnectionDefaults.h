//
//  RTCPeerConnectionDefaults.h
//  CustomerServiceClient
//
//  Created by Xingnan Zhou on 2015-04-17.
//  Copyright (c) 2015 SnowWolf. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RTCMediaConstraints.h"
#import "RTCIceServer.h"
#import "RTCPair.h"

@interface RTCPeerConnectionDefaults : NSObject
+ (RTCMediaConstraints *)defaultMediaStreamConstraints;
+ (RTCMediaConstraints *)defaultPeerConnectionConstraints;
+ (RTCMediaConstraints *)defaultOfferConstraints;
+ (RTCICEServer *)defaultSTUNServer;
@end
