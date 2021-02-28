//
//  SoundscapeRoom.m
//  SoundscapeExplorer
//
//  Created by Andrea Gerino on 14/07/2019.
//  Copyright © 2019 Andrea Gerino. All rights reserved.
//

#import "SoundscapeRoom.h"

@interface SoundscapeRoom () {
}

@property (nonatomic, assign) float height;
@property (nonatomic, assign) float width;
@property (nonatomic, assign) float depth;

@property(nonatomic, strong) UIImage* backgroundImage;
@property(nonatomic, assign) RoomType roomType;

@end

@implementation SoundscapeRoom

- (SoundscapeRoom*) initWithDictionary: (NSDictionary*) room {
    self = [super init];
    if (self) {
        NSDictionary* size = room[@"size"];
        _width = [size[@"width"] floatValue];
        _height = [size[@"height"] floatValue];
        _depth = [size[@"depth"] floatValue];

        _roomType = ROOM_RECTANGULAR;
        if(room[@"shape"] && [room[@"shape"] isEqualToString:@"ROUND"]){
            _roomType = ROOM_ROUND;
        };

        NSDictionary* backgroundImage = room[@"backgroundImage"];
        NSString* backgroundRAW = backgroundImage[@"raw"];
        NSString* backgroundURL = backgroundImage[@"url"];        
        
        if(backgroundRAW) {
            NSData *dataEncoded = [[NSData alloc] initWithBase64EncodedString:[[backgroundRAW componentsSeparatedByString:@","] lastObject] options:0];
            UIImage *image = [UIImage imageWithData:dataEncoded];
            
            [self setBackgroundImage:image];
            
        } else if(backgroundURL) {
            NSURL *url = [NSURL URLWithString:backgroundURL];
            NSData *imageData = [NSData dataWithContentsOfURL:url];
            UIImage *image = [UIImage imageWithData:imageData];
            
            [self setBackgroundImage:image];

        }
    }
    
    return self;
}

- (float) minX {
    return -1.0 * _width / 2;
}

- (float) maxX {
    return _width / 2;
}

- (float) minY {
    return -1.0 * _depth / 2;
}

- (float) maxY {
    return _depth / 2;
}

@end
