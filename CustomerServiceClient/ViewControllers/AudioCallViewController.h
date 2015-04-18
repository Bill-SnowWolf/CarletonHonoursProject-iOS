//
//  VideoCallViewController.h
//  CustomerServiceClient
//
//  Created by Xingnan Zhou on 2015-04-11.
//  Copyright (c) 2015 SnowWolf. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AudioCallViewController : UIViewController <UIAlertViewDelegate>
//- (id)initWithRoomId:(NSInteger)roomId;
- (id)initWithCustomerData:(NSDictionary *)customerData;
@end
