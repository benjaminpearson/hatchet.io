//
//  AppDelegate.h
//  Hatchet Demo
//
//  Created by Benjamin Pearson on 7/04/13.
//  Copyright (c) 2013 Inlight Media. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HatchetSubscriber.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, HatchetDelegate> {
	HatchetSubscriber *_subscriber;
}

@property (strong, nonatomic) UIWindow *window;

@end
