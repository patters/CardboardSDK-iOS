//
//  Viewport.h
//  CardboardSDK-iOS
//


#ifndef __CardboardSDK_iOS__Viewport__
#define __CardboardSDK_iOS__Viewport__

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>


namespace CardboardSDK
{

struct Viewport
{
  public:
    int x;
    int y;
    int width;
    int height;

    void setViewport(int x, int y, int width, int height);
#ifndef CARDBOARD_CORE
    void setGLViewport();
    void setGLScissor();
#endif
    CGRect toCGRect();
    NSString *toString();
};

}

#endif