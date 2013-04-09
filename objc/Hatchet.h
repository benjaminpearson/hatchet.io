//
//  Hatchet.h
//
//  Created by Benjamin Pearson on 10/02/13.
//  Copyright (c) 2013 Inlight Media. All rights reserved.
//

#import "SocketIoClient.h"

typedef enum {
	HatchetStateConnected = 1,
	HatchetStateDisconnected = 2,
	HatchetStateReconnecting = 3,
	HatchetStateDisconnectedPermanently = 4
} HatchetState;

@protocol HatchetDelegate;

@interface Hatchet : NSObject <SocketIoClientDelegate> {
	SocketIoClient *_socket;
	NSDictionary *_credentials;
	BOOL _stayConnected;
	HatchetState state;
	BOOL _authenticated;
	__weak id <HatchetDelegate> delegate;
}

@property (nonatomic, readonly) HatchetState state;
@property (nonatomic, weak) id <HatchetDelegate> delegate;

- (BOOL)isActive; // Connected or trying to connect
- (BOOL)isConnected;

- (void)auth:(NSString *)key secret:(NSString *)secret;
- (void)open;
- (void)close;
- (void)authenticated;
- (void)handleEvent:(NSString *)event withPayload:(NSDictionary *)payload;

@end

@protocol HatchetDelegate <NSObject>

@optional

- (void)hatchetEvent:(NSString *)event data:(NSDictionary *)data;
- (void)hatchetStateUpdated:(HatchetState)state;

@end
