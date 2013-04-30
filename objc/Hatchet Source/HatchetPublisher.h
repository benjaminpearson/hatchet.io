//
//  HatchetPublisher.h
//
//  Created by Benjamin Pearson on 10/02/13.
//  Copyright (c) 2013 Inlight Media. All rights reserved.
//

#import "Hatchet.h"

@interface HatchetPublisher : Hatchet {

}

- (id)initWithHost:(NSString *)hostName;

- (void)broadcast:(NSString *)event data:(NSDictionary *)data;
- (void)send:(NSString *)event target:(NSString *)target data:(NSDictionary *)data;
- (void)once:(NSString *)event data:(NSDictionary *)data;

@end
