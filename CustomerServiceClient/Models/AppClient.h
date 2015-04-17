//
//  AppClient.h
//  CustomerServiceClient
//
//  Created by Xingnan Zhou on 2015-04-17.
//  Copyright (c) 2015 SnowWolf. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, AppClientState) {
    // Disconnected from servers.
    kAppClientStateDisconnected,
    // Connecting to servers.
    kAppClientStateConnecting,
    // Connected to servers.
    kAppClientStateConnected,
    // Waiting in the queue
    kAppClientStateWaiting,
    // Checking available representatives
    kAppClientStateChecking,
};

@class AppClient;

@protocol AppClientDelegate <NSObject>

- (void)appClient:(AppClient *)client didChangeState:(AppClientState)state object:(NSObject *)object;
- (void)appClient:(AppClient *)client didError:(NSError *)error;

@end

@interface AppClient : NSObject
@property (nonatomic, readonly) AppClientState state;
@property (nonatomic, weak) id<AppClientDelegate> delegate;
@property (nonatomic) NSString *roomNumber;
@property (nonatomic) NSString *callId;

- (id)initWithDelegate:(id<AppClientDelegate>)delegate;
- (void)checkAvailableRepresentatives;
- (void)connectToRoomWithId:(NSString *)roomId;
- (void)disconnect;

@end
