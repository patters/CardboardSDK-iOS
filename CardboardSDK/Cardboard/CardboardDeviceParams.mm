//
//  CardboardDeviceParams.mm
//  CardboardSDK-iOS
//


#include "CardboardDeviceParams.h"

#include "Distortion.h"
#include "FieldOfView.h"


namespace CardboardSDK
{

CardboardDeviceParams::CardboardDeviceParams() :
    _vendor(@"com.google"),
    _model(@"cardboard"),
    _interLensDistance(0.06f),
    _verticalDistanceToLensCenter(0.035f),
    _screenToLensDistance(0.042f)
{
    float coefficients[2] = {0.441f, 0.156f};
    _distortion = new Distortion();
    _distortion->setCoefficients(coefficients);

    _maximumLeftEyeFOV = new FieldOfView(40.0f);
}

CardboardDeviceParams::CardboardDeviceParams(CardboardDeviceParams* params)
{
    _vendor = params->_vendor;
    _model = params->_model;
    
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