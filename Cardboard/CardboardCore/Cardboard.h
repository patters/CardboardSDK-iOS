//
//  Cardboard.h
//  Cardboard
//
//  Created by PattersonJ on 10/7/15.
//  Copyright © 2015 Jason Patterson. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Cardboard : NSObject
@property (nonatomic, readonly) NSInteger vertexCount;
@property (nonatomic, readonly) NSInteger indexCount;

- (void)update;

- (void)getVerticesForLeftEye:(float *)vertices;
- (void)getIndicesForLeftEye:(short *)indices;
- (void)getVerticesForRightEye:(float *)vertices;
- (void)getIndicesForRightEye:(short *)indices;

@end
