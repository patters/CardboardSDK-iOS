//
//  Cardboard.h
//  Cardboard
//
//  Created by PattersonJ on 10/7/15.
//  Copyright © 2015 Jason Patterson. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, CardboardDeviceType) {
    CardboardDeviceTypeCardboardJun2014,
    CardboardDeviceTypeCardboardMay2015,
    CardboardDeviceTypeGoggleTechC1Glass
};

@interface Cardboard : NSObject
@property (nonatomic, readonly) NSInteger vertexCount;
@property (nonatomic, readonly) NSInteger indexCount;

- (instancetype)initWithDeviceType:(CardboardDeviceType)deviceType NS_DESIGNATED_INITIALIZER;
- (void)update;

- (void)getVerticesForLeftEye:(float *)vertices;
- (void)getIndicesForLeftEye:(short *)indices;
- (void)getVerticesForRightEye:(float *)vertices;
- (void)getIndicesForRightEye:(short *)indices;

@end
