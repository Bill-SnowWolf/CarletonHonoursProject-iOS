//
//  SignalingMessage.m
//  CustomerServiceClient
//
//  Created by Xingnan Zhou on 2015-04-11.
//  Copyright (c) 2015 SnowWolf. All rights reserved.
//

#import "SignalingMessage.h"

//#import "RTCICECandidate+JSON.h"
#import "RTCSessionDescription+JSON.h"

static NSString const *kSignalingMessageTypeKey = @"type";

@implementation SignalingMessage

- (id)initWithType:(SignalingMessageType)type {
    if (self = [super init]) {
        _type = type;
    }
    return self;
}

- (NSString *)description {
    return [[NSString alloc] initWithData:[self JSONData]
                                 encoding:NSUTF8StringEncoding];
}

+ (SignalingMessage *)messageFromJSONString:(NSString *)jsonString {
//    NSDictionary *values = [NSDictionary dictionaryWithJSONString:jsonString];
//    if (!values) {
//        NSLog(@"Error parsing signaling message JSON.");
//        return nil;
//    }
//    
//    NSString *typeString = values[kARDSignalingMessageTypeKey];
//    ARDSignalingMessage *message = nil;
//    if ([typeString isEqualToString:@"candidate"]) {
//        RTCICECandidate *candidate =
//        [RTCICECandidate candidateFromJSONDictionary:values];
//        message = [[ARDICECandidateMessage alloc] initWithCandidate:candidate];
//    } else if ([typeString isEqualToString:@"offer"] ||
//               [typeString isEqualToString:@"answer"]) {
//        RTCSessionDescription *description =
//        [RTCSessionDescription descriptionFromJSONDictionary:values];
//        message =
//        [[ARDSessionDescriptionMessage alloc] initWithDescription:description];
//    } else if ([typeString isEqualToString:@"bye"]) {
//        message = [[ARDByeMessage alloc] init];
//    } else {
//        NSLog(@"Unexpected type: %@", typeString);
//    }
//    return message;
    return nil;
}

- (NSData *)JSONData {
    return nil;
}

@end

@implementation ICECandidateMessage

//- (instancetype)initWithCandidate:(RTCICECandidate *)candidate {
//    if (self = [super initWithType:kARDSignalingMessageTypeCandidate]) {
//        _candidate = candidate;
//    }
//    return self;
//}
//
//- (NSData *)JSONData {
//    return [_candidate JSONData];
//}

@end

@implementation SessionDescriptionMessage

- (id)initWithDescription:(RTCSessionDescription *)description {
    SignalingMessageType type = kSignalingMessageTypeOffer;
    NSString *typeString = description.type;
    if ([typeString isEqualToString:@"offer"]) {
        type = kSignalingMessageTypeOffer;
    } else if ([typeString isEqualToString:@"answer"]) {
        type = kSignalingMessageTypeAnswer;
    } else {
        NSAssert(NO, @"Unexpected type: %@", typeString);
    }
    if (self = [super initWithType:type]) {
        _sessionDescription = description;
    }
    return self;
}

- (NSData *)JSONData {
    return [_sessionDescription JSONData];
}

@end

