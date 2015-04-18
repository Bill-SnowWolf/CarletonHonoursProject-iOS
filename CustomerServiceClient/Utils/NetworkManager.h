//
//  NetworkManager.h
//  CustomerServiceClient
//
//  Created by Xingnan Zhou on 2015-04-15.
//  Copyright (c) 2015 SnowWolf. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NetworkManager : NSObject
+ (void)sendServiceRequestWithCustomerData:(NSDictionary *)customerData completionHandler:(void(^)(NSDictionary *responseDict))completion;
+ (void)updateCallStatusWithId:(NSString *)callId status:(NSString *)status;
@end
