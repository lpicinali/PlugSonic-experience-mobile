//
//  NSObject+FilePath.h
//  SoundscapeExplorer
//
//  Created by Andrea Gerino on 14/07/2019.
//  Copyright © 2019 Andrea Gerino. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (FilePath)

-(NSString*) getPathForResourceWithFileName: (NSString*) fileName;

@end

NS_ASSUME_NONNULL_END
