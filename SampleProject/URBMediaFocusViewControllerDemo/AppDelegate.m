//
//  AppDelegate.m
//  URBMediaFocusViewControllerDemo
//
//  Created by Nicholas Shipes on 11/3/13.
//  Copyright (c) 2013 Urban10 Interactive. All rights reserved.
//

#import "AppDelegate.h"
#import "DemoViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
	DemoViewController *controller = [[DemoViewController alloc] initWithNibName:nil bundle:nil];
	self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:controller];
	
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
