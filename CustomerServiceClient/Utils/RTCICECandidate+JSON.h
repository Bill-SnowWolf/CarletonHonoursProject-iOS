//
//  RTCICECandidate+JSON.h
//  CustomerServiceClient
//
//  Created by Xingnan Zhou on 2015-04-14.
//  Copyright (c) 2015 SnowWolf. All rights reserved.
//

#import "RTCICECandidate.h"

@interface RTCICECandidate (JSON)

+ (RTCICECandidate *)candidateFromJSONDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)JSONDictionary;

@end
