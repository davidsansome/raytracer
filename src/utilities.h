#ifndef UTILITIES_H
#define UTILITIES_H

#define GL_GLEXT_PROTOTYPES
#ifdef __APPLE__
#include <OpenGL/gl.h>
#include <OpenGL/glext.h>
#include <OpenGL/glu.h>
#else
#include <GL/gl.h>
#include <GL/glext.h>
#include <GL/glu.h>
#endif

#include <svl/SVL.h>
#include <QDebug>

#include "glwin.h"

class QGLContext;

namespace Utilities
{
	QGLContext* context();
};

#endif
