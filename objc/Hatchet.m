//
//  Hatchet.m
//
//  Created by Benjamin Pearson on 10/02/13.
//  Copyright (c) 2013 Inlight Media. All rights reserved.
//

#import "Hatchet.h"

@interface Hatchet (Private)

- (void)updateState:(HatchetState)new;

@end

@implementation Hatchet

@synthesize delegate, state;

- (id)init {
	if ((self = [super init])) {
		_authenticated = FALSE;
	}
	return self;
}

#pragma mark - Custom Methods

- (BOOL)isActive {
	return [_socket isConnected] || [_socket isConnecting];
}

- (BOOL)isConnected {
	return [_socket isConnected];
}

- (void)auth:(NSString *)key secret:(NSString *)secret {
	if (!key || !secret) return;

	_credentials = @{
		@"channel": key,
		@"secret": secret
	};

	[self isActive] ? [_socket disconnect] : [self open];
}

- (void)open {
	if (!_credentials) return;
	_stayConnected = TRUE;
	[_socket connect];
}

- (void)close {
	_stayConnected = FALSE;
	[_socket disconnect];
}

- (void)updateState:(HatchetState)new {
	state = new;
	if (delegate && [delegate respondsToSelector:@selector(hatchetStateUpdated:)]) {
		[delegate hatchetStateUpdated:state];
	}
}

- (void)authenticated {

}


#pragma mark - Socket IO Delegate methods

- (void)socketIoClient:(SocketIoClient *)client didReceiveJSON:(id)json {}

- (void)socketIoClient:(SocketIoClient *)client didReceiveMessage:(NSString *)message {}

- (void)socketIoClient:(SocketIoClient *)client didReceiveEvent:(NSString *)event withData:(id)data {
	// On authentication send up all subscribe events
	if ([event isEqualToString:@"authenticated"]) {
		NSLog(@"authenticated");
		_authenticated = TRUE;
		[self authenticated];
		return;
	} else if ([event isEqualToString:@"deauthenticated"]) {
		NSLog(@"deauthenticated");
		return;
	} else if ([event isEqualToString:@"disconnect"]) {
		NSLog(@"disconnect");
		return;
	} else if ([event isEqualToString:@"reconnect_failed"]) {
		NSLog(@"reconnect_failed");
		return;
	} else if ([event isEqualToString:@"auth-error"]) {
		NSLog(@"auth-error");
		return;
	} else if ([event isEqualToString:@"auth-invalid"]) {
		NSLog(@"auth-invalid");
		return;
	} else if ([event isEqualToString:@"auth-invalid-perms"]) {
		NSLog(@"auth-invalid-perms");
		return;
	}

	if (!data || ![data isKindOfClass:[NSArray class]] || [data count] == 0) {
		NSLog(@"No data received or not NSArray class");
		return;
	}
	NSDictionary *payload = data[0];
	[self handleEvent:event withPayload:payload];
}

- (void)socketIoClientDidConnect:(SocketIoClient *)client {
	NSLog(@"socketIoClientDidConnect");
	[self updateState:HatchetStateConnected];
	[_socket sendEvent:@"authenticate" withData:_credentials];
}

- (void)socketIoClientDidDisconnect:(SocketIoClient *)client {
	NSLog(@"socketIoClientDidDisconnect");
	[self updateState:HatchetStateDisconnected];
	if (_stayConnected) {
		NSLog(@"socketIoClient Reconnecting....");
		[self updateState:HatchetStateReconnecting];
		[self open];
	}
}

- (void)socketIoClientDidDisconnectPermanently:(SocketIoClient *)client {
	NSLog(@"socketIoClientDidDisconnectPermanently");
	[self updateState:HatchetStateDisconnectedPermanently];
}

#pragma mark - Handle Responses

- (void)handleEvent:(NSString *)event withPayload:(NSDictionary *)payload {
	if (delegate && [delegate respondsToSelector:@selector(hatchetEvent:data:)]) {
		[delegate hatchetEvent:event data:payload];
	}
}

@end