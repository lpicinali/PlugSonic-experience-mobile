//
//  SoundscapeRoom.h
//  SoundscapeExplorer
//
//  Created by Andrea Gerino on 14/07/2019.
//  Copyright © 2019 Andrea Gerino. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SoundscapeRoom : NSObject

typedef enum : int {
    ROOM_RECTANGULAR,
    ROOM_ROUND
} RoomType;

- (SoundscapeRoom*) initWithDictionary: (NSDictionary*) room;

- (float) minX;
- (float) maxX;
- (float) minY;
- (float) maxY;

- (float) height;
- (float) width;
- (float) depth;

- (UIImage*) backgroundImage;
- (RoomType) roomType;

@end

NS_ASSUME_NONNULL_END
