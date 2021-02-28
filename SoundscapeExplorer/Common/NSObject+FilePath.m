//
//  NSObject+FilePath.m
//  SoundscapeExplorer
//
//  Created by Andrea Gerino on 14/07/2019.
//  Copyright © 2019 Andrea Gerino. All rights reserved.
//

#import "NSObject+FilePath.h"

@implementation NSObject (FilePath)

-(NSString*) getPathForResourceWithFileName: (NSString*) fileName{
  if(fileName!=nil){
    NSString* documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *path = [documentsPath stringByAppendingPathComponent:fileName];;
    
    if([[NSFileManager defaultManager] fileExistsAtPath:path]){
      return path;
    }else{
      NSRange substringRange = [fileName rangeOfString:@"."];
      if(substringRange.location != NSNotFound){
        
        path = [[NSBundle mainBundle] pathForResource:[fileName substringToIndex:substringRange.location] ofType:[fileName substringFromIndex:substringRange.location+1]];
        
        if(path!=nil)
          return path;
      }
    }
  }else{
    NSLog(@"You should at least specify a fileName...");
  }
  
  return nil;
}

@end
