//
//  IMAppDelegate.m
//  iBeaconTemplate
//
//  Created by James Nick Sears on 5/29/14.
//  Copyright (c) 2014 iBeaconModules.us. All rights reserved.
//

#import "IMAppDelegate.h"
#import "IMViewController.h"
#import <CoreLocation/CoreLocation.h>

@interface IMAppDelegate ()
@property (nonatomic, strong) NSString *lastMessage;
@end

@implementation IMAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    NSUUID *beaconUUID = [[NSUUID alloc] initWithUUIDString:@"EBEFD083-70A2-47C8-9837-E7B5634DF524"];
    NSString *regionIdentifier = @"us.iBeaconModules";
    CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:beaconUUID identifier:regionIdentifier];

    switch ([CLLocationManager authorizationStatus]) {
        case kCLAuthorizationStatusAuthorizedAlways:
            NSLog(@"Authorized Always");
            break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            NSLog(@"Authorized when in use");
            break;
        case kCLAuthorizationStatusDenied:
            NSLog(@"Denied");
            break;
        case kCLAuthorizationStatusNotDetermined:
            NSLog(@"Not determined");
            break;
        case kCLAuthorizationStatusRestricted:
            NSLog(@"Restricted");
            break;
            
        default:
            break;
    }
    
    self.locationManager = [[CLLocationManager alloc] init];
    if([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [self.locationManager requestAlwaysAuthorization];
    }
    self.locationManager.delegate = self;
    self.locationManager.pausesLocationUpdatesAutomatically = NO;
    [self.locationManager startMonitoringForRegion:beaconRegion];
    [self.locationManager startRangingBeaconsInRegion:beaconRegion];
    [self.locationManager startUpdatingLocation];

	// ask for permission for local notifications
	if([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
		[application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil]];
	}

    return YES;
}

-(void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    [manager startRangingBeaconsInRegion:(CLBeaconRegion*)region];
    [self.locationManager startUpdatingLocation];
    
    NSLog(@"You entered the region.");
    [self sendLocalNotificationWithMessage:@"You entered the region." withSound:NO];
}

-(void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    [manager stopRangingBeaconsInRegion:(CLBeaconRegion*)region];
    [self.locationManager stopUpdatingLocation];
    
    NSLog(@"You exited the region.");
    [self sendLocalNotificationWithMessage:@"You exited the region." withSound:NO];
}

-(void)sendLocalNotificationWithMessage:(NSString*)message withSound:(BOOL)withSound {
	BOOL allowsLocationNotifications = YES;
	
	if([[UIApplication sharedApplication] respondsToSelector:@selector(currentUserNotificationSettings)]) {
		if(([UIApplication sharedApplication].currentUserNotificationSettings.types | UIUserNotificationTypeNone) == UIUserNotificationTypeNone) {
			allowsLocationNotifications = NO;
		}
	}
	
	if(allowsLocationNotifications) {
		UILocalNotification *notification = [[UILocalNotification alloc] init];
		notification.alertBody = message;
		
		if(withSound) {
			// classic star trek communicator beep
			//	http://www.trekcore.com/audio/
			//
			// note: convert mp3 and wav formats into caf using:
			//	"afconvert -f caff -d LEI16@44100 -c 1 in.wav out.caf"
			// http://stackoverflow.com/a/10388263
			
			notification.soundName = @"tos_beep.caf";
		}

		[[UIApplication sharedApplication] scheduleLocalNotification:notification];
	}
}

-(void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region {
    NSString *message = @"";
    
    IMViewController *viewController = (IMViewController*)self.window.rootViewController;
    viewController.beacons = beacons;
    [viewController.tableView reloadData];
	
	BOOL notifyWithSound = NO;
	
    if(beacons.count > 0) {
        CLBeacon *nearestBeacon = beacons.firstObject;
        if(nearestBeacon.proximity == self.lastProximity ||
           nearestBeacon.proximity == CLProximityUnknown) {
            return;
        }
        self.lastProximity = nearestBeacon.proximity;
        
        switch(nearestBeacon.proximity) {
            case CLProximityFar:
                message = @"You are far away from the beacon";
				notifyWithSound = YES;
                break;
            case CLProximityNear:
                message = @"You are near the beacon";
                break;
            case CLProximityImmediate:
                message = @"You are in the immediate proximity of the beacon";
                break;
            case CLProximityUnknown:
                return;
        }
    } else {
        message = @"No beacons are nearby";
    }
	
    NSLog(@"%@", message);
	
	// to avoid spamming notifications, only send notification if the message has changed
	if(![message isEqualToString:self.lastMessage]) {
		[self sendLocalNotificationWithMessage:message withSound:notifyWithSound];
	}
	
	self.lastMessage = message;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
