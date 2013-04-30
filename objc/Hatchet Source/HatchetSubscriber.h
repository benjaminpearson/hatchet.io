//
//  HatchetSubscriber.h
//
//  Created by Benjamin Pearson on 10/02/13.
//  Copyright (c) 2013 Inlight Media. All rights reserved.
//

#import "Hatchet.h"

@interface HatchetSubscriber : Hatchet {
	NSMutableArray *_watching;
	NSString *_alias;
}

- (id)initWithHost:(NSString *)hostName;

- (void)watch:(NSString *)event;
- (void)unwatch:(NSString *)event;
- (void)alias:(NSString *)alias;

@end
