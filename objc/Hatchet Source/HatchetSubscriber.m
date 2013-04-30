//
//  HatchetSubscriber.m
//
//  Created by Benjamin Pearson on 10/02/13.
//  Copyright (c) 2013 Inlight Media. All rights reserved.
//

#import "HatchetSubscriber.h"

@interface HatchetSubscriber (Private)

@end

@implementation HatchetSubscriber

@dynamic delegate;

- (id)initWithHost:(NSString *)hostName {
	if ((self = [super init])) {
		_watching = [[NSMutableArray alloc] init];
		_socket = [[SocketIoClient alloc] initWithHost:hostName port:5223];
		_socket.secureConnection = FALSE;
		_socket.delegate = self;
	}
	return self;
}

#pragma mark - Custom Methods

- (void)watch:(NSString *)event {
	if (!event) return;

	if (![_watching containsObject:event]) {
		[_watching addObject:event];
		if (_authenticated && state == HatchetStateConnected) {
			[_socket sendEvent:@"subscribe" withData:event];
		}
	}
}

- (void)unwatch:(NSString *)event {
	if (!event) return;

	if ([_watching containsObject:event]) {
		[_watching removeObject:event];
		if (_authenticated && state == HatchetStateConnected) {
			[_socket sendEvent:@"unsubscribe" withData:event];
		}
	}
}

- (void)alias:(NSString *)alias {
	if (!alias || (_alias && [_alias isEqualToString:alias])) return;

	_alias = alias;
	if (_authenticated && state == HatchetStateConnected) {
		[_socket sendEvent:@"alias" withData:_alias];
	}
}

- (void)authenticated {
	[super authenticated];
	if ([_watching count]) {
		for (NSString *event in _watching) {
			[_socket sendEvent:@"subscribe" withData:event];
		}
	}
	
	if (_alias) {
		[_socket sendEvent:@"alias" withData:_alias];
	}
}

@end