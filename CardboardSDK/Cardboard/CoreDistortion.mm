//
//  CoreDistortion.mm
//  CardboardSDK-iOS
//


#include "CoreDistortion.h"

#include "CardboardDeviceParams.h"
#include "Distortion.h"
#include "Eye.h"
#include "FieldOfView.h"
#include "HeadMountedDisplay.h"
#include "ScreenParams.h"
#include "Viewport.h"

inline float GLKMathDegreesToRadians(float degrees) { return degrees * (M_PI / 180); };
inline float GLKMathRadiansToDegrees(float radians) { return radians * (180 / M_PI); };

namespace CardboardSDK
{

namespace
{
    float clamp(float val, float min, float max)
    {
        return MAX(min, MIN(max, val));
    }
}

DistortionRenderer::DistortionRenderer() :
    _resolutionScale(1.0f),
    _restoreGLStateEnabled(true),
    _chromaticAberrationCorrectionEnabled(false),
    _vignetteEnabled(true),
    _leftEyeDistortionMesh(nullptr),
    _rightEyeDistortionMesh(nullptr),
    _glStateBackup(nullptr),
    _glStateBackupAberration(nullptr),
    _headMountedDisplay(nullptr),
    _leftEyeViewport(nullptr),
    _rightEyeViewport(nullptr),
    _fovsChanged(false),
    _viewportsChanged(false),
    _textureFormatChanged(false),
    _drawingFrame(false),
    _xPxPerTanAngle(0),
    _yPxPerTanAngle(0),
    _metersPerTanAngle(0)
{
}

DistortionRenderer::~DistortionRenderer()
{
    if (_leftEyeDistortionMesh != nullptr) { delete _leftEyeDistortionMesh; }
    if (_rightEyeDistortionMesh != nullptr) { delete _rightEyeDistortionMesh; }
        
    if (_leftEyeViewport != nullptr) { delete _leftEyeViewport; }
    if (_rightEyeViewport != nullptr) { delete _rightEyeViewport; }
}

void DistortionRenderer::setResolutionScale(float scale)
{
    _resolutionScale = scale;
    _viewportsChanged = true;
}

bool DistortionRenderer::restoreGLStateEnabled()
{
    return _restoreGLStateEnabled;;
}

void DistortionRenderer::setRestoreGLStateEnabled(bool enabled)
{
    _restoreGLStateEnabled = enabled;
}

bool DistortionRenderer::chromaticAberrationEnabled()
{
    return _chromaticAberrationCorrectionEnabled;
}

void DistortionRenderer::setChromaticAberrationEnabled(bool enabled)
{
    _chromaticAberrationCorrectionEnabled = enabled;
}

bool DistortionRenderer::vignetteEnabled()
{
    return _vignetteEnabled;;
}

void DistortionRenderer::setVignetteEnabled(bool enabled)
{
    _vignetteEnabled = enabled;
    _fovsChanged = true;
}

void DistortionRenderer::fovDidChange(HeadMountedDisplay *headMountedDisplay,
                                      FieldOfView *leftEyeFov,
                                      FieldOfView *rightEyeFov,
                                      float virtualEyeToScreenDistance)
{
    if (_drawingFrame)
    {
        NSLog(@"Cannot change FOV while rendering a frame.");
        return;
    }
    
    _headMountedDisplay = headMountedDisplay;
    if (_leftEyeViewport != nullptr) { delete _leftEyeViewport; }
    if (_rightEyeViewport != nullptr) { delete _rightEyeViewport; }
    _leftEyeViewport = initViewportForEye(leftEyeFov, 0.0f);
    _rightEyeViewport = initViewportForEye(rightEyeFov, _leftEyeViewport->width);
    _metersPerTanAngle = virtualEyeToScreenDistance;
    ScreenParams *screen = _headMountedDisplay->getScreen();
    _xPxPerTanAngle = screen->width() / ( screen->widthInMeters() / _metersPerTanAngle );
    _yPxPerTanAngle = screen->height() / ( screen->heightInMeters() / _metersPerTanAngle );
    _fovsChanged = true;
    _viewportsChanged = true;
}

bool DistortionRenderer::viewportsChanged()
{
    return _viewportsChanged;
}

void DistortionRenderer::updateViewports(Viewport *leftViewport, Viewport *rightViewport)
{
    leftViewport->setViewport(round(_leftEyeViewport->x * _xPxPerTanAngle * _resolutionScale),
                              round(_leftEyeViewport->y * _yPxPerTanAngle * _resolutionScale),
                              round(_leftEyeViewport->width * _xPxPerTanAngle * _resolutionScale),
                              round(_leftEyeViewport->height * _yPxPerTanAngle * _resolutionScale));
    rightViewport->setViewport(round(_rightEyeViewport->x * _xPxPerTanAngle * _resolutionScale),
                               round(_rightEyeViewport->y * _yPxPerTanAngle * _resolutionScale),
                               round(_rightEyeViewport->width * _xPxPerTanAngle * _resolutionScale),
                               round(_rightEyeViewport->height * _yPxPerTanAngle * _resolutionScale));
    _viewportsChanged = false;
}

void DistortionRenderer::updateDistortionMesh()
{
    ScreenParams *screen = _headMountedDisplay->getScreen();
    CardboardDeviceParams *cardboardDeviceParams = _headMountedDisplay->getCardboard();
    
    float textureWidthTanAngle = _leftEyeViewport->width + _rightEyeViewport->width;
    float textureHeightTanAngle = MAX(_leftEyeViewport->height, _rightEyeViewport->height);

    float xEyeOffsetTanAngleScreen =
        (screen->widthInMeters() / 2.0f - cardboardDeviceParams->interLensDistance() / 2.0f) / _metersPerTanAngle;
    float yEyeOffsetTanAngleScreen =
        (cardboardDeviceParams->verticalDistanceToLensCenter() - screen->borderSizeInMeters()) / _metersPerTanAngle;
    
    _leftEyeDistortionMesh = createDistortionMesh(_leftEyeViewport,
                                                  textureWidthTanAngle, textureHeightTanAngle,
                                                  xEyeOffsetTanAngleScreen, yEyeOffsetTanAngleScreen);
    
    xEyeOffsetTanAngleScreen =
        screen->widthInMeters() / _metersPerTanAngle - xEyeOffsetTanAngleScreen;
    
    _rightEyeDistortionMesh = createDistortionMesh(_rightEyeViewport,
                                                   textureWidthTanAngle, textureHeightTanAngle,
                                                   xEyeOffsetTanAngleScreen, yEyeOffsetTanAngleScreen);
    
    _fovsChanged = false;
}

DistortionRenderer::EyeViewport *DistortionRenderer::initViewportForEye(FieldOfView *eyeFieldOfView, float xOffset)
{
    float left = tanf(GLKMathDegreesToRadians(eyeFieldOfView->left()));
    float right = tanf(GLKMathDegreesToRadians(eyeFieldOfView->right()));
    float bottom = tanf(GLKMathDegreesToRadians(eyeFieldOfView->bottom()));
    float top = tanf(GLKMathDegreesToRadians(eyeFieldOfView->top()));
    
    EyeViewport *eyeViewport = new EyeViewport();
    eyeViewport->x = xOffset;
    eyeViewport->y = 0.0f;
    eyeViewport->width = (left + right);
    eyeViewport->height = (bottom + top);
    eyeViewport->eyeX = (left + xOffset);
    eyeViewport->eyeY = bottom;
    
    return eyeViewport;
}

DistortionRenderer::DistortionMesh *DistortionRenderer::createDistortionMesh(EyeViewport *eyeViewport,
                                                                             float textureWidthTanAngle,
                                                                             float textureHeightTanAngle,
                                                                             float xEyeOffsetTanAngleScreen,
                                                                             float yEyeOffsetTanAngleScreen)
{
    return new DistortionMesh(_headMountedDisplay->getCardboard()->distortion(),
                              _headMountedDisplay->getCardboard()->distortion(),
                              _headMountedDisplay->getCardboard()->distortion(),
                              _headMountedDisplay->getScreen()->widthInMeters() / _metersPerTanAngle,
                              _headMountedDisplay->getScreen()->heightInMeters() / _metersPerTanAngle,
                              xEyeOffsetTanAngleScreen, yEyeOffsetTanAngleScreen,
                              textureWidthTanAngle, textureHeightTanAngle,
                              eyeViewport->eyeX, eyeViewport->eyeY,
                              eyeViewport->x, eyeViewport->y,
                              eyeViewport->width, eyeViewport->height,
                              _vignetteEnabled);
}

float DistortionRenderer::computeDistortionScale(Distortion *distortion, float screenWidthM, float interpupillaryDistanceM)
{
    return distortion->distortionFactor((screenWidthM / 2.0f - interpupillaryDistanceM / 2.0f) / (screenWidthM / 4.0f));
}

DistortionRenderer::DistortionMesh* DistortionRenderer::leftEyeDistortionMesh() {
    return _leftEyeDistortionMesh;
}
    
DistortionRenderer::DistortionMesh* DistortionRenderer::rightEyeDistortionMesh() {
    return _rightEyeDistortionMesh;
}
    
// DistortionMesh

DistortionRenderer::DistortionMesh::DistortionMesh(Distortion *distortionRed,
                                                   Distortion *distortionGreen,
                                                   Distortion *distortionBlue,
                                                   float screenWidth, float screenHeight,
                                                   float xEyeOffsetScreen, float yEyeOffsetScreen,
                                                   float textureWidth, float textureHeight,
                                                   float xEyeOffsetTexture, float yEyeOffsetTexture,
                                                   float viewportXTexture, float viewportYTexture,
                                                   float viewportWidthTexture, float viewportHeightTexture,
                                                   bool vignetteEnabled)
{
    
    const int rows = 40;
    const int cols = 40;
    const int floatsPerVertex = 9;
    _vertexCount = rows * cols * floatsPerVertex;
    _vertexData = new float[_vertexCount];
    
    int vertexOffset = 0;
    
    const float vignetteSizeTanAngle = 0.05f;
    
    for (int row = 0; row < rows; row++)
    {
        for (int col = 0; col < cols; col++)
        {
            const float uTextureBlue = col / 39.0f * (viewportWidthTexture / textureWidth) + viewportXTexture / textureWidth;
            const float vTextureBlue = row / 39.0f * (viewportHeightTexture / textureHeight) + viewportYTexture / textureHeight;
            
            const float xTexture = uTextureBlue * textureWidth - xEyeOffsetTexture;
            const float yTexture = vTextureBlue * textureHeight - yEyeOffsetTexture;
            const float rTexture = sqrtf(xTexture * xTexture + yTexture * yTexture);
            
            const float textureToScreenBlue = (rTexture > 0.0f) ? distortionBlue->distortInverse(rTexture) / rTexture : 1.0f;
            
            const float xScreen = xTexture * textureToScreenBlue;
            const float yScreen = yTexture * textureToScreenBlue;
            
            const float uScreen = (xScreen + xEyeOffsetScreen) / screenWidth;
            const float vScreen = (yScreen + yEyeOffsetScreen) / screenHeight;
            const float rScreen = rTexture * textureToScreenBlue;
            
            const float screenToTextureGreen = (rScreen > 0.0f) ? distortionGreen->distortionFactor(rScreen) : 1.0f;
            const float uTextureGreen = (xScreen * screenToTextureGreen + xEyeOffsetTexture) / textureWidth;
            const float vTextureGreen = (yScreen * screenToTextureGreen + yEyeOffsetTexture) / textureHeight;

            const float screenToTextureRed = (rScreen > 0.0f) ? distortionRed->distortionFactor(rScreen) : 1.0f;
            const float uTextureRed = (xScreen * screenToTextureRed + xEyeOffsetTexture) / textureWidth;
            const float vTextureRed = (yScreen * screenToTextureRed + yEyeOffsetTexture) / textureHeight;

            const float vignetteSizeTexture = vignetteSizeTanAngle / textureToScreenBlue;
            
            const float dxTexture = xTexture + xEyeOffsetTexture - clamp(xTexture + xEyeOffsetTexture,
                                                                         viewportXTexture + vignetteSizeTexture,
                                                                         viewportXTexture + viewportWidthTexture - vignetteSizeTexture);
            const float dyTexture = yTexture + yEyeOffsetTexture - clamp(yTexture + yEyeOffsetTexture,
                                                                         viewportYTexture + vignetteSizeTexture,
                                                                         viewportYTexture + viewportHeightTexture - vignetteSizeTexture);
            const float drTexture = sqrtf(dxTexture * dxTexture + dyTexture * dyTexture);
            
            float vignette = 1.0f;
            if (vignetteEnabled)
            {
                vignette = 1.0f - clamp(drTexture / vignetteSizeTexture, 0.0f, 1.0f);
            }
            
            _vertexData[(vertexOffset + 0)] = 2.0f * uScreen - 1.0f;
            _vertexData[(vertexOffset + 1)] = 2.0f * vScreen - 1.0f;
            _vertexData[(vertexOffset + 2)] = vignette;
            _vertexData[(vertexOffset + 3)] = uTextureRed;
            _vertexData[(vertexOffset + 4)] = vTextureRed;
            _vertexData[(vertexOffset + 5)] = uTextureGreen;
            _vertexData[(vertexOffset + 6)] = vTextureGreen;
            _vertexData[(vertexOffset + 7)] = uTextureBlue;
            _vertexData[(vertexOffset + 8)] = vTextureBlue;
            
            vertexOffset += floatsPerVertex;
        }
    }
    
    _indexCount = 3158;
    _indexData = new short[_indexCount];

    int indexOffset = 0;
    vertexOffset = 0;
    for (int row = 0; row < rows-1; row++)
    {
        if (row > 0)
        {
            _indexData[indexOffset] = _indexData[(indexOffset - 1)];
            indexOffset++;
        }
        for (int col = 0; col < cols; col++)
        {
            if (col > 0)
            {
                if (row % 2 == 0)
                {
                    vertexOffset++;
                }
                else
                {
                    vertexOffset--;
                }
            }
            _indexData[(indexOffset++)] = vertexOffset;
            _indexData[(indexOffset++)] = (vertexOffset + 40);
        }
        vertexOffset += 40;
    }
}
    
DistortionRenderer::DistortionMesh::~DistortionMesh() {
    if (_vertexData) delete[] _vertexData;
    _vertexData = nullptr;
    if (_indexData) delete[] _indexData;
    _indexData = nullptr;
}

void DistortionRenderer::DistortionMesh::getData(float *vertexData, int *vertices, short *indexData, int *indices) {
    if (vertexData) {
        memcpy(vertexData, _vertexData, _vertexCount * sizeof(float));
    }
    if (vertices) {
        *vertices = _vertexCount;
    }
    if (indexData) {
        memcpy(indexData, _indexData, _indexCount * sizeof(short));
    }
    if (indices) {
        *indices = _indexCount;
    }
}

// EyeViewport

NSString *DistortionRenderer::EyeViewport::toString()
{
    return [NSString stringWithFormat:@"{x:%f y:%f width:%f height:%f eyeX:%f, eyeY:%f}",
            x, y, width, height, eyeX, eyeY];
}

}