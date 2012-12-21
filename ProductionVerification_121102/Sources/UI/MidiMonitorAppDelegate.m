//
//  MidiMonitorAppDelegate.m
//  MidiMonitor
//
//  Created by Pete Goodliffe on 10/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MidiMonitorAppDelegate.h"

#import "MidiMonitorViewController.h"
#import "PGMidi.h"
#import "iOSVersionDetection.h"
#import "PGArc.h"

@implementation MidiMonitorAppDelegate

@synthesize window;
@synthesize viewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    if([[[UIDevice currentDevice]systemVersion]floatValue]>=4.0){//pre iOS 4.0 rootview problem, if not this way, no rotation will be enabled
        window.rootViewController = viewController;
    }else{
        [window addSubview:viewController.view];
    }
    [window makeKeyAndVisible];

    
    IF_IOS_HAS_COREMIDI
    (
        // We only create a MidiInput object on iOS versions that support CoreMIDI
        midi = [[PGMidi alloc] init];
//        [midi enableNetwork:YES];
        viewController.midi = midi;
    )

	return YES;
}

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
    
}

- (void) applicationWillResignActive:(UIApplication *)application
{
    NSUserDefaults *dataDefaults = [NSUserDefaults standardUserDefaults];
//  [dataDefaults setObject:nameField.text forKey:UserDefaultNameKey];
//  [dataDefaults setBool:YES forKey:UserDefaultBoolKey];
    [dataDefaults setObject:self.viewController.serialNumberConfig.text forKey:@"serialNumberKey"];
//    [dataDefaults setObject:self.viewController.displayCurrentDate.text forKey:@"currentDateKey"];
}

- (void) applicationDidBecomeActive:(UIApplication *)application
{
//      [dataDefaults objectForKey:NCUserDefaultNameKey]；
//        [dataDefaults boolForKey: UserDefaultBoolKey];
    NSUserDefaults *dataDefaults = [NSUserDefaults standardUserDefaults];
    self.viewController.serialNumberConfig.text = [dataDefaults objectForKey:@"serialNumberKey"];
//    self.viewController.displayCurrentDate.text = [dataDefaults objectForKey:@"currentDateKey"];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    
}


- (void)dealloc
{
#if ! PGMIDI_ARC
    [viewController release];
    [window release];
    [super dealloc];
#endif
}

@end
