//
//  AppDelegate.m
//  Hatchet Demo
//
//  Created by Benjamin Pearson on 7/04/13.
//  Copyright (c) 2013 Inlight Media. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	[self redirectNSLogToDocuments];
	[[UIDevice currentDevice] setBatteryMonitoringEnabled:TRUE];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];

	_subscriber = [[HatchetSubscriber alloc] initWithHost:@"api.hatchet.io"];
	_subscriber.delegate = self;
	[_subscriber auth:@"demo" secret:@"sub-token"];
	[_subscriber watch:@"score-updated"];

	[NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(logBattery) userInfo:nil repeats:TRUE];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
	[_subscriber close];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	[_subscriber open];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {}
- (void)applicationWillEnterForeground:(UIApplication *)application {}
- (void)applicationWillTerminate:(UIApplication *)application {}


#pragma mark - HatchetIO Delegate Methods

- (void)hatchetEvent:(NSString *)event data:(NSDictionary *)data {
	NSLog(@"Event: %@ date: %@", event, [NSDate date]);
}

- (void)logBattery {
	NSLog(@"Time: %@ Battery: %f", [NSDate date], [[UIDevice currentDevice] batteryLevel]);
}

- (void)redirectNSLogToDocuments {
     NSArray *allPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
     NSString *documentsDirectory = [allPaths objectAtIndex:0];
     NSString *pathForLog = [documentsDirectory stringByAppendingPathComponent:@"nslog.txt"];

     freopen([pathForLog cStringUsingEncoding:NSASCIIStringEncoding],"a+",stderr);
}

@end
