//
//  SignalingMessage.h
//  CustomerServiceClient
//
//  Created by Xingnan Zhou on 2015-04-11.
//  Copyright (c) 2015 SnowWolf. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RTCICECandidate.h"
#import "RTCSessionDescription.h"

typedef enum {
    kSignalingMessageTypeCandidate,
    kSignalingMessageTypeOffer,
    kSignalingMessageTypeAnswer,
    kSignalingMessageTypeBye,
} SignalingMessageType;

@interface SignalingMessage : NSObject
@property(nonatomic, readonly) SignalingMessageType type;

+ (SignalingMessage *)messageFromJSONString:(NSString *)jsonString;
- (NSData *)JSONData;

@end

@interface ICECandidateMessage : SignalingMessage

@property(nonatomic, readonly) RTCICECandidate *candidate;

- (instancetype)initWithCandidate:(RTCICECandidate *)candidate;

@end

@interface SessionDescriptionMessage : SignalingMessage

@property(nonatomic, readonly) RTCSessionDescription *sessionDescription;

- (instancetype)initWithDescription:(RTCSessionDescription *)description;

@end
