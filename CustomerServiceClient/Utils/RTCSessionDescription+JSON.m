//
//  SessionDescription+JSON.m
//  CustomerServiceClient
//
//  Created by Xingnan Zhou on 2015-04-11.
//  Copyright (c) 2015 SnowWolf. All rights reserved.
//

#import "RTCSessionDescription+JSON.h"

static NSString const *kRTCSessionDescriptionTypeKey = @"type";
static NSString const *kRTCSessionDescriptionSdpKey = @"sdp";

@implementation RTCSessionDescription (JSON)

+ (RTCSessionDescription *)descriptionFromJSONDictionary:
(NSDictionary *)dictionary {
    NSString *type = dictionary[kRTCSessionDescriptionTypeKey];
    NSString *sdp = dictionary[kRTCSessionDescriptionSdpKey];
    return [[RTCSessionDescription alloc] initWithType:type sdp:sdp];
}

- (NSDictionary *)JSONDictionary {
    NSDictionary *json = @{
                           kRTCSessionDescriptionTypeKey : self.type,
                           kRTCSessionDescriptionSdpKey : self.description
                           };
    return json;
}

@end
