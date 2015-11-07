//
//  Cardboard.m
//  Cardboard
//
//  Created by PattersonJ on 10/7/15.
//  Copyright © 2015 Jason Patterson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Cardboard.h"
#import "CardboardDeviceParams.h"
#import "CoreDistortion.h"
#import "HeadMountedDisplay.h"
#import "FieldOfView.h"
#import "Distortion.h"
#import "ScreenParams.h"

static CardboardSDK::CardboardDeviceParams CardboardJun2014 = CardboardSDK::CardboardDeviceParams(
    @"com.google",
    @"Cardboard",
    @"v1",
    0.060f,
    0.035f,
    0.042f,
    40.0f,
    0.441f,
    0.156f
);

static CardboardSDK::CardboardDeviceParams CardboardMay2015 = CardboardSDK::CardboardDeviceParams(
    @"com.google",
    @"Cardboard",
    @"v2",
    0.064f,
    0.035f,
    0.039f,
    60.0f,
    0.34f,
    0.55f
);

static CardboardSDK::CardboardDeviceParams GoggleTechC1Glass = CardboardSDK::CardboardDeviceParams(
    @"net.goggletech",
    @"Go4D C1-Glass",
    @"v1",
    0.065f,
    0.036f,
    0.058f,
    50.0f,
    0.3f,
    0.0f
);

inline float GLKMathDegreesToRadians(float degrees) { return degrees * (M_PI / 180); };
inline float GLKMathRadiansToDegrees(float radians) { return radians * (180 / M_PI); };

@interface Cardboard ()
{
    CardboardSDK::HeadMountedDisplay *_headMountedDisplay;
    CardboardSDK::FieldOfView *_leftEyeFOV;
    CardboardSDK::FieldOfView *_rightEyeFOV;
    CardboardSDK::DistortionRenderer *_distortionRenderer;
}
@end

@implementation Cardboard

- (instancetype)initWithDeviceType:(CardboardDeviceType)deviceType {
    self = [super init];
    if (self) {
        CardboardSDK::CardboardDeviceParams *device = nil;
        switch (deviceType) {
            case CardboardDeviceTypeCardboardJun2014:
                device = &CardboardJun2014;
                break;
            case CardboardDeviceTypeCardboardMay2015:
                device = &CardboardMay2015;
                break;
            case CardboardDeviceTypeGoggleTechC1Glass:
                device = &GoggleTechC1Glass;
                break;
        }
        _headMountedDisplay = new CardboardSDK::HeadMountedDisplay([UIScreen mainScreen], device);
        _leftEyeFOV = new CardboardSDK::FieldOfView(_headMountedDisplay->getCardboard()->maximumLeftEyeFOV());
        _rightEyeFOV = new CardboardSDK::FieldOfView(_headMountedDisplay->getCardboard()->maximumLeftEyeFOV());
        
        _distortionRenderer = new CardboardSDK::DistortionRenderer();

    }
    return self;
}

- (float)virtualEyeToScreenDistance {
    return _headMountedDisplay->getCardboard()->screenToLensDistance();;
}

- (void)update
{
    [self updateFovsWithLeftEyeFov:_leftEyeFOV rightEyeFov:_rightEyeFOV];
    _distortionRenderer->fovDidChange(_headMountedDisplay, _leftEyeFOV, _rightEyeFOV, [self virtualEyeToScreenDistance]);
    _distortionRenderer->updateDistortionMesh();
}

- (NSInteger)vertexCount {
    // Same for both eyes
    int vertexCount = 0;
    _distortionRenderer->leftEyeDistortionMesh()->getData(nullptr, &vertexCount, nullptr, nullptr);
    return vertexCount;
}

- (NSInteger)indexCount {
    // Same for both eyes
    int indexCount = 0;
    _distortionRenderer->leftEyeDistortionMesh()->getData(nullptr, nullptr, nullptr, &indexCount);
    return indexCount;
}

- (void)getVerticesForLeftEye:(float *)vertices {
    _distortionRenderer->leftEyeDistortionMesh()->getData(vertices, nullptr, nullptr, nullptr);
}

- (void)getIndicesForLeftEye:(short *)indices {
    _distortionRenderer->leftEyeDistortionMesh()->getData(nullptr, nullptr, indices, nullptr);
}

- (void)getVerticesForRightEye:(float *)vertices {
    _distortionRenderer->rightEyeDistortionMesh()->getData(vertices, nullptr, nullptr, nullptr);
}

- (void)getIndicesForRightEye:(short *)indices {
    _distortionRenderer->rightEyeDistortionMesh()->getData(nullptr, nullptr, indices, nullptr);
}

- (void)updateFovsWithLeftEyeFov:(CardboardSDK::FieldOfView *)leftEyeFov
                     rightEyeFov:(CardboardSDK::FieldOfView *)rightEyeFov
{
    CardboardSDK::CardboardDeviceParams *cardboardDeviceParams = _headMountedDisplay->getCardboard();
    CardboardSDK::ScreenParams *screenParams = _headMountedDisplay->getScreen();
    CardboardSDK::Distortion *distortion = cardboardDeviceParams->distortion();
    float eyeToScreenDistance = [self virtualEyeToScreenDistance];
    
    float outerDistance = (screenParams->widthInMeters() - cardboardDeviceParams->interLensDistance() ) / 2.0f;
    float innerDistance = cardboardDeviceParams->interLensDistance() / 2.0f;
    float bottomDistance = cardboardDeviceParams->verticalDistanceToLensCenter() - screenParams->borderSizeInMeters();
    float topDistance = screenParams->heightInMeters() + screenParams->borderSizeInMeters() - cardboardDeviceParams->verticalDistanceToLensCenter();
    
    float outerAngle = GLKMathRadiansToDegrees(atanf(distortion->distort(outerDistance / eyeToScreenDistance)));
    float innerAngle = GLKMathRadiansToDegrees(atanf(distortion->distort(innerDistance / eyeToScreenDistance)));
    float bottomAngle = GLKMathRadiansToDegrees(atanf(distortion->distort(bottomDistance / eyeToScreenDistance)));
    float topAngle = GLKMathRadiansToDegrees(atanf(distortion->distort(topDistance / eyeToScreenDistance)));
    
    leftEyeFov->setLeft(MIN(outerAngle, cardboardDeviceParams->maximumLeftEyeFOV()->left()));
    leftEyeFov->setRight(MIN(innerAngle, cardboardDeviceParams->maximumLeftEyeFOV()->right()));
    leftEyeFov->setBottom(MIN(bottomAngle, cardboardDeviceParams->maximumLeftEyeFOV()->bottom()));
    leftEyeFov->setTop(MIN(topAngle, cardboardDeviceParams->maximumLeftEyeFOV()->top()));
    
    rightEyeFov->setLeft(leftEyeFov->right());
    rightEyeFov->setRight(leftEyeFov->left());
    rightEyeFov->setBottom(leftEyeFov->bottom());
    rightEyeFov->setTop(leftEyeFov->top());
}

- (void)dealloc {
    if (_headMountedDisplay != nullptr) { delete _headMountedDisplay; }
    if (_leftEyeFOV != nullptr) { delete _leftEyeFOV; }
    if (_rightEyeFOV != nullptr) { delete _rightEyeFOV; }
    if (_distortionRenderer != nullptr) { delete _distortionRenderer; }
}

@end
