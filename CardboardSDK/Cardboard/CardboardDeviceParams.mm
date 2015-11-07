//
//  CardboardDeviceParams.mm
//  CardboardSDK-iOS
//


#include "CardboardDeviceParams.h"

#include "Distortion.h"
#include "FieldOfView.h"


namespace CardboardSDK
{
    
CardboardDeviceParams::CardboardDeviceParams(NSString *vendor,
                                             NSString *model,
                                             NSString *version,
                                             float interLensDistance,
                                             float verticalDistanceToLensCenter,
                                             float screenToLensDistance,
                                             float maxFOV,
                                             float distortionK1,
                                             float distortionK2):
    _vendor([vendor copy]),
    _model([model copy]),
    _version([version copy]),
    _interLensDistance(interLensDistance),
    _verticalDistanceToLensCenter(verticalDistanceToLensCenter),
    _screenToLensDistance(screenToLensDistance)
{
    _maximumLeftEyeFOV = new FieldOfView(maxFOV);

    float coefficients[2] = {distortionK1, distortionK2};
    _distortion = new Distortion();
    _distortion->setCoefficients(coefficients);
}

CardboardDeviceParams::CardboardDeviceParams(CardboardDeviceParams* params)
{
    _vendor = params->_vendor;
    _model = params->_model;
    _version = params->_version;
    
    _interLensDistance = params->_interLensDistance;
    _verticalDistanceToLensCenter = params->_verticalDistanceToLensCenter;
    _screenToLensDistance = params->_screenToLensDistance;
    
    _maximumLeftEyeFOV = new FieldOfView(params->_maximumLeftEyeFOV);
    _distortion = new Distortion(params->_distortion);
}

CardboardDeviceParams::~CardboardDeviceParams()
{
    if (_distortion != nullptr) { delete _distortion; }
    if (_maximumLeftEyeFOV != nullptr) { delete _maximumLeftEyeFOV; }
}

NSString *CardboardDeviceParams::vendor()
{
    return _vendor;
}
    
NSString *CardboardDeviceParams::model()
{
    return _model;
}

NSString *CardboardDeviceParams::version()
{
    return _version;
}

float CardboardDeviceParams::interLensDistance()
{
    return _interLensDistance;
}

float CardboardDeviceParams::verticalDistanceToLensCenter()
{
    return _verticalDistanceToLensCenter;
}

float CardboardDeviceParams::screenToLensDistance()
{
    return _screenToLensDistance;
}

FieldOfView *CardboardDeviceParams::maximumLeftEyeFOV()
{
    return _maximumLeftEyeFOV;
}

Distortion *CardboardDeviceParams::distortion()
{
    return _distortion;
}

bool CardboardDeviceParams::equals(CardboardDeviceParams *other)
{
    if (other == nullptr)
    {
        return false;
    }
    else if (other == this)
    {
        return true;
    }
    return
        ([vendor() isEqualToString:other->vendor()])
        && ([model() isEqualToString:other->model()])
        && (interLensDistance() == other->interLensDistance())
        && (verticalDistanceToLensCenter() == other->verticalDistanceToLensCenter())
        && (screenToLensDistance() == other->screenToLensDistance())
        && (maximumLeftEyeFOV()->equals(other->maximumLeftEyeFOV()))
        && (distortion()->equals(other->distortion()));
}

}