//
//  AppDelegate.m
//  Hatchet Demo
//
//  Created by Benjamin Pearson on 7/04/13.
//  Copyright (c) 2013 Inlight Media. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
	
	_subscriber = [[HatchetSubscriber alloc] init];
	_subscriber.delegate = self;
	
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
	if (_subscriber) {
		[_subscriber close];
	}
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	if (_subscriber) {
		[_subscriber auth:@"demo" secret:@"sub-token"];
		[_subscriber watch:@"user-login"];	
		[_subscriber watch:@"user-signup"];
	
		//[_subscriber alias:@"userId"];
	}
}

- (void)applicationDidEnterBackground:(UIApplication *)application {}
- (void)applicationWillEnterForeground:(UIApplication *)application {}
- (void)applicationWillTerminate:(UIApplication *)application {}


#pragma mark - HatchetIO Delegate Methods

- (void)hatchetEvent:(NSString *)event data:(NSDictionary *)data {
	NSLog(@"%@: %@", event, data);
}

- (void)hatchetStateUpdated:(HatchetState)state {
	NSLog(@"hatchetStateUpdated");
}


@end
