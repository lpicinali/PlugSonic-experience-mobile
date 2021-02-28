//
//  AppDelegate.m
//  SoundscapeExplorer
//
//  Created by Andrea Gerino on 23/06/2019.
//  Copyright © 2019 Andrea Gerino. All rights reserved.
//

#import "AppDelegate.h"

#import "Model/Constants.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    if(![[[NSUserDefaults standardUserDefaults] objectForKey:@"DEFAULT_SOUNDSCAPE_COPIED"] boolValue]){
        [self copyDefaultSoundscape];
    }
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
    if(url) {
        return [self openSoundScapeURL:url];
    }

    return NO;
}

- (BOOL) openSoundScapeURL: (NSURL*) url {
    NSString* fileName = [url lastPathComponent];

    NSString* documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* folder = [documentsPath stringByAppendingPathComponent:[[fileName componentsSeparatedByString:@"."] firstObject]];
    
    NSError* fileError;
    if([[NSFileManager defaultManager] fileExistsAtPath:folder]){
        [[NSFileManager defaultManager] removeItemAtPath:folder error: &fileError];
    }
    if(!fileError)
        [[NSFileManager defaultManager] createDirectoryAtPath:folder withIntermediateDirectories:NO attributes:nil error: &fileError];

    if(!fileError)
        [[NSFileManager defaultManager] moveItemAtPath:[url path] toPath:[NSString stringWithFormat:@"%@/%@", folder, fileName] error: &fileError];

    if(!fileError){
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_SOUNDSCAPE_UPDATE object:nil];
        return YES;
    
    }else{
        UIAlertController * newAlertController = [UIAlertController alertControllerWithTitle:@"Error" message:@"An error occurred while downloading the new Soundscape" preferredStyle:UIAlertControllerStyleAlert];
        [newAlertController addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler: nil]];
        
        UINavigationController* mainController = (UINavigationController*) self.window.rootViewController;
        [mainController presentViewController:newAlertController animated:YES completion:nil];

        return NO;
    }
}

- (void) copyDefaultSoundscape {
    NSString* defaultFileName = @"jazz.soundscape";
    
    NSString* defaultSoundscapePath = [[NSBundle mainBundle] pathForResource:[[defaultFileName componentsSeparatedByString:@"."] firstObject] ofType:@"soundscape"];
    NSString* documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* folder = [documentsPath stringByAppendingPathComponent:[[defaultFileName componentsSeparatedByString:@"."] firstObject]];
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:folder]){
        NSError* fileError;
        [[NSFileManager defaultManager] createDirectoryAtPath:folder withIntermediateDirectories:NO attributes:nil error: &fileError];
        [[NSFileManager defaultManager] copyItemAtPath:defaultSoundscapePath toPath:[NSString stringWithFormat:@"%@/%@", folder, defaultFileName] error: &fileError];
        
        if(!fileError){
            [[NSUserDefaults standardUserDefaults] setObject: @(true) forKey:@"DEFAULT_SOUNDSCAPE_COPIED"];
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_SOUNDSCAPE_UPDATE object:nil];
        }
    }
}

@end
