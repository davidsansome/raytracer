#include "utilities.h"

#include <QGLContext>

QGLContext* Utilities::context()
{
	const QGLContext* c = QGLContext::currentContext();
	return const_cast<QGLContext*>(c);
}
