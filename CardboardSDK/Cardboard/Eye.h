//
//  Eye.h
//  CardboardSDK-iOS
//


#ifndef __CardboardSDK_iOS__Eye__
#define __CardboardSDK_iOS__Eye__

#ifndef CARDBOARD_CORE
#import <GLKit/GLKit.h>
#endif


namespace CardboardSDK
{

class FieldOfView;
class Viewport;


class Eye
{
  public:

    typedef enum
    {
        TypeMonocular = 0,
        TypeLeft = 1,
        TypeRight = 2
    } Type;

    Eye(Type eye);
    ~Eye();

    Type type();

#ifndef CARDBOARD_CORE
    GLKMatrix4 eyeView();
    void setEyeView(GLKMatrix4 eyeView);
    GLKMatrix4 perspective(float zNear, float zFar);
#endif
    
    Viewport *viewport();
    FieldOfView *fov();
    
    void setProjectionChanged();
    
  private:
    Type _type;
#ifndef CARDBOARD_CORE
    GLKMatrix4 _eyeView;
#endif
    Viewport *_viewport;
    FieldOfView *_fov;
    bool _projectionChanged;
#ifndef CARDBOARD_CORE
    GLKMatrix4 _perspective;
#endif
    float _lastZNear;
    float _lastZFar;
};

}

#endif