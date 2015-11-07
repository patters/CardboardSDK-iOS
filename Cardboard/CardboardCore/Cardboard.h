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

- (nonnull instancetype)initWithDeviceType:(CardboardDeviceType)deviceType NS_DESIGNATED_INITIALIZER;
- (void)update;

- (void)getVerticesForLeftEye:(float * __nonnull)vertices;
- (void)getIndicesForLeftEye:(short * __nonnull)indices;
- (void)getVerticesForRightEye:(float * __nonnull)vertices;
- (void)getIndicesForRightEye:(short * __nonnull)indices;

@end
