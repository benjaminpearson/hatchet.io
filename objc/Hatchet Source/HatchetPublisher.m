//
//  HatchetPublisher.m
//
//  Created by Benjamin Pearson on 10/02/13.
//  Copyright (c) 2013 Inlight Media. All rights reserved.
//

#import "HatchetPublisher.h"

@interface HatchetPublisher (Private)

- (void)push:(NSDictionary *)data;

@end

@implementation HatchetPublisher

@dynamic delegate;

- (id)initWithHost:(NSString *)hostName {
	if ((self = [super init])) {
		_socket = [[SocketIoClient alloc] initWithHost:hostName port:5224];
		_socket.secureConnection = FALSE;
		_socket.delegate = self;
	}
	return self;
}

#pragma mark - Custom Methods

- (void)push:(NSDictionary *)data {
	if (!data) return;
	[_socket sendEvent:@"push" withData:data];
}

- (void)broadcast:(NSString *)event data:(NSDictionary *)data {
	if (!event || !data) return;
	[self push:@{ @"event": event, @"data": data }];
}

- (void)send:(NSString *)event target:(NSString *)target data:(NSDictionary *)data {
	if (!event || !target || !data) return;
	[self push:@{ @"event": event, @"target": target, @"data": data }];
}

- (void)once:(NSString *)event data:(NSDictionary *)data {
	if (!event || !data) return;
	[self push:@{ @"event": event, @"once": @(TRUE), @"data": data }];
}

@end