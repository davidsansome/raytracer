#include "texture.h"
#include "utilities.h"

#include <QImage>
#include <QGLContext>

Texture::Texture(const QString& filename, Settings settings)
	: m_filename(filename),
	  m_settings(settings)
{
	QImage image(m_filename);
	if (image.isNull())
		qFatal(QString("Couldn't load texture " + m_filename).toAscii());
	
	m_id = Utilities::context()->bindTexture(image, GL_TEXTURE_2D, GL_RGBA);
	setTexParams(GL_TEXTURE_2D);
	
	qDebug() << "Loaded texture:" << m_filename;
}

Texture::Texture(Settings settings)
	: m_settings(settings)
{
	glGenTextures(1, (GLuint*)&m_id);
	glBindTexture(GL_TEXTURE_2D, m_id);
	setTexParams(GL_TEXTURE_2D);
}

Texture::~Texture()
{
	Utilities::context()->deleteTexture(m_id);
}

void Texture::setTexParams(GLenum target)
{
	if (m_settings & Mipmaps)
	{
		glTexParameteri(target, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
		glTexParameteri(target, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	}
	else
	{
		glTexParameteri(target, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(target, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	}
	
	if (m_settings & Mirrored)
	{
		glTexParameteri(target, GL_TEXTURE_WRAP_S, GL_MIRRORED_REPEAT);
		glTexParameteri(target, GL_TEXTURE_WRAP_T, GL_MIRRORED_REPEAT);
	}
	else
	{
		glTexParameteri(target, GL_TEXTURE_WRAP_S, GL_REPEAT);
		glTexParameteri(target, GL_TEXTURE_WRAP_T, GL_REPEAT);
	}
}

void Texture::bind(int texUnit, int shaderLoc)
{
	glActiveTexture(GL_TEXTURE0 + texUnit);
	glBindTexture(GL_TEXTURE_2D, m_id);
	
	if (shaderLoc != -1)
		glUniform1i(shaderLoc, texUnit);
}

