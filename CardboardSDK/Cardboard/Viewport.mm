//
//  Viewport.mm
//  CardboardSDK-iOS
//


#include "Viewport.h"
#ifndef CARDBOARD_CORE
#import <OpenGLES/ES2/gl.h>
#endif

namespace CardboardSDK
{

void Viewport::setViewport(int x, int y, int width, int height)
{
    this->x = x;
    this->y = y;
    this->width = width;
    this->height = height;
}

#ifndef CARDBOARD_CORE

void Viewport::setGLViewport()
{
    glViewport(x, y, width, height);
}

void Viewport::setGLScissor()
{
    glScissor(x, y, width, height);
}
    
#endif

CGRect Viewport::toCGRect()
{
    return CGRectMake(x, y, width, height);
}

NSString *Viewport::toString()
{
    return [NSString stringWithFormat:@"{x:%d y:%d width:%d height:%d}", this->x, this->y, this->width, this->height];
}

}