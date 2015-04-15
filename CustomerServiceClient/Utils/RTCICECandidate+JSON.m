//
//  RTCICECandidate+JSON.m
//  CustomerServiceClient
//
//  Created by Xingnan Zhou on 2015-04-14.
//  Copyright (c) 2015 SnowWolf. All rights reserved.
//

#import "RTCICECandidate+JSON.h"

static NSString const *kRTCICECandidateTypeKey = @"type";
static NSString const *kRTCICECandidateTypeValue = @"candidate";
static NSString const *kRTCICECandidateMidKey = @"id";
static NSString const *kRTCICECandidateMLineIndexKey = @"label";
static NSString const *kRTCICECandidateSdpKey = @"candidate";

@implementation RTCICECandidate (JSON)

+ (RTCICECandidate *)candidateFromJSONDictionary:(NSDictionary *)dictionary {
    NSString *mid = dictionary[kRTCICECandidateMidKey];
    NSString *sdp = dictionary[kRTCICECandidateSdpKey];
    NSNumber *num = dictionary[kRTCICECandidateMLineIndexKey];
    NSInteger mLineIndex = [num integerValue];
    return [[RTCICECandidate alloc] initWithMid:mid index:mLineIndex sdp:sdp];
}

- (NSDictionary *)JSONDictionary {
    NSDictionary *json = @{
                           kRTCICECandidateTypeKey : kRTCICECandidateTypeValue,
                           kRTCICECandidateMLineIndexKey : @(self.sdpMLineIndex),
                           kRTCICECandidateMidKey : self.sdpMid,
                           kRTCICECandidateSdpKey : self.sdp
                           };
    return json;
}

@end
