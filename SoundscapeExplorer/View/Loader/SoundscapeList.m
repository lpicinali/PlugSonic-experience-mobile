//
//  SoundscapeLoader.m
//  SoundscapeExplorer
//
//  Created by Andrea Gerino on 23/06/2019.
//  Copyright © 2019 Andrea Gerino. All rights reserved.
//

#import "Constants.h"

#import "SoundscapeList.h"
#import "SoundscapeLoader.h"

#import <ARKit/ARKit.h>
@interface SoundscapeList ()

@property (strong, nonatomic) IBOutlet UISegmentedControl *interactionModeControl;
@property (nonatomic, strong) NSArray* soundscapes;

@end

@implementation SoundscapeList

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if(![ARWorldTrackingConfiguration isSupported]){
        [[self interactionModeControl] setEnabled:NO forSegmentAtIndex:1];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear: animated];
    [self scanForSoundscapes];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scanForSoundscapes) name:NOTIFICATION_SOUNDSCAPE_UPDATE object:nil];
}

- (void) viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_SOUNDSCAPE_UPDATE object:nil];
    [super viewWillDisappear:animated];
}

- (void)scanForSoundscapes {
    NSMutableArray* availableSoundscapes = [NSMutableArray array];
    
    NSString* documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSArray* topLevelFolders = [fileManager contentsOfDirectoryAtPath:documentsPath error:nil];
    for(NSString* folder in topLevelFolders){
        if([folder isEqualToString:@"Inbox"]){
            continue;
        }
        
        NSArray* folderContent = [fileManager contentsOfDirectoryAtPath:[NSString stringWithFormat:@"%@/%@", documentsPath, folder] error:nil];
        for(NSString* file in folderContent){
            NSString* extension = [file pathExtension];
            if([extension isEqualToString:@"soundscape"]){
                NSString* folderPath = [NSString stringWithFormat:@"%@/%@", documentsPath, folder];
                NSString* filePath =[NSString stringWithFormat:@"%@/%@", folderPath, file];
                [availableSoundscapes addObject: @{ @"folder": folderPath, @"path": filePath, @"name": file}];
            }
        }
    }
    
    [self setSoundscapes: availableSoundscapes];
    [[self tableView] reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self soundscapes] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"soundscapeFolderCell" forIndexPath:indexPath];
    
    NSDictionary* soundscapeObject = [[self soundscapes] objectAtIndex:[indexPath row]];
    [[cell textLabel] setText:[soundscapeObject objectForKey:@"name"]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary* soundscapeObject = [[self soundscapes] objectAtIndex:[indexPath row]];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSLog(@"Should load %@", [soundscapeObject objectForKey:@"path"]);
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    SoundscapeLoader* loader = [storyboard instantiateViewControllerWithIdentifier:@"soundscapeLoader"];
    [loader setSoundscapePath:[soundscapeObject objectForKey:@"path"]];

    long index = [[self interactionModeControl] selectedSegmentIndex];
    switch (index) {
        case 1:
            [loader setInteractionType:INTERACTION_AR];
            break;
        case 2:
            [loader setInteractionType:INTERACTION_OSC];
            break;
        default:
            [loader setInteractionType:INTERACTION_TOUCH];
            break;
    }
    
    [loader setModalPresentationStyle: UIModalPresentationFullScreen];
    [self presentViewController:loader animated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSDictionary* soundscapeObject = [[self soundscapes] objectAtIndex:[indexPath row]];
        NSString* folder = [soundscapeObject objectForKey:@"folder"];
        
        NSError* error;
        [[NSFileManager defaultManager] removeItemAtPath:folder error:&error];
        if(!error){
            [self scanForSoundscapes];
            
            [tableView reloadData];
        } else {
            NSLog(@"%@", error);
        }
    }
}

- (bool) prefersStatusBarHidden {
    return true;
}

@end
