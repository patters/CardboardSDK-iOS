//
//  DistortionRenderer.h
//  CardboardSDK-iOS
//


#ifndef __CardboardSDK_iOS__DistortionRenderer__
#define __CardboardSDK_iOS__DistortionRenderer__

#import <Foundation/Foundation.h>


namespace CardboardSDK
{

class Distortion;
class Eye;
class FieldOfView;
class GLStateBackup;
class HeadMountedDisplay;
class Viewport;


class DistortionRenderer
{
  public:
    DistortionRenderer();
    ~DistortionRenderer();
    
    void beforeDrawFrame();
    void afterDrawFrame();
    
    void setResolutionScale(float scale);
    
    bool restoreGLStateEnabled();
    void setRestoreGLStateEnabled(bool enabled);
    
    bool chromaticAberrationEnabled();
    void setChromaticAberrationEnabled(bool enabled);
    
    bool vignetteEnabled();
    void setVignetteEnabled(bool enabled);
    
    bool viewportsChanged();
    void updateViewports(Viewport *leftViewport,
                         Viewport *rightViewport);

    void fovDidChange(HeadMountedDisplay *hmd,
                      FieldOfView *leftEyeFov,
                      FieldOfView *rightEyeFov,
                      float virtualEyeToScreenDistance);
    
    class DistortionMesh
    {
      public:
        DistortionMesh();
        DistortionMesh(Distortion *distortionRed,
                       Distortion *distortionGreen,
                       Distortion *distortionBlue,
                       float screenWidth, float screenHeight,
                       float xEyeOffsetScreen, float yEyeOffsetScreen,
                       float textureWidth, float textureHeight,
                       float xEyeOffsetTexture, float yEyeOffsetTexture,
                       float viewportXTexture, float viewportYTexture,
                       float viewportWidthTexture,
                       float viewportHeightTexture,
                       bool vignetteEnabled);
        
        void getData(float *vertexData, int *vertices, short *indexData, int *indices);
        
      private:
        float *_vertexData;
        int _vertexCount;
        short *_indexData;
        int _indexCount;
    };
    
    DistortionMesh* leftEyeDistortionMesh();
    DistortionMesh* rightEyeDistortionMesh();

    void updateDistortionMesh();

private:
    struct EyeViewport
    {
      public:
        float x;
        float y;
        float width;
        float height;
        float eyeX;
        float eyeY;

        NSString *toString();
    };
    
    float _resolutionScale;
    bool _restoreGLStateEnabled;
    bool _chromaticAberrationCorrectionEnabled;
    bool _vignetteEnabled;
    DistortionMesh *_leftEyeDistortionMesh;
    DistortionMesh *_rightEyeDistortionMesh;
    GLStateBackup *_glStateBackup;
    GLStateBackup *_glStateBackupAberration;
    HeadMountedDisplay *_headMountedDisplay;
    EyeViewport *_leftEyeViewport;
    EyeViewport *_rightEyeViewport;
    bool _fovsChanged;
    bool _viewportsChanged;
    bool _textureFormatChanged;
    bool _drawingFrame;
    float _xPxPerTanAngle;
    float _yPxPerTanAngle;
    float _metersPerTanAngle;
    
    EyeViewport *initViewportForEye(FieldOfView *eyeFieldOfView, float xOffsetM);
    
    DistortionMesh *createDistortionMesh(EyeViewport *eyeViewport,
                                         float textureWidthTanAngle,
                                         float textureHeightTanAngle,
                                         float xEyeOffsetTanAngleScreen,
                                         float yEyeOffsetTanAngleScreen);
    float computeDistortionScale(Distortion *distortion,
                                 float screenWidthM,
                                 float interpupillaryDistanceM);
    int setupRenderTextureAndRenderbuffer(int width, int height);
};

}

#endif
