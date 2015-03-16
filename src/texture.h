#ifndef TEXTURE_H
#define TEXTURE_H

#include <QList>

#include "utilities.h"

class Texture
{
public:
	enum Settings
	{
		Defaults = 0x00,
		Mipmaps = 0x01,
		Mirrored = 0x02
	};
	Texture(const QString& filename, Settings settings);
	Texture(Settings settings);
	~Texture();
	
	void bind(int texUnit = 0, int shaderLoc = -1);
	
	Settings settings() const { return m_settings; }
	const QString& filename() const { return m_filename; }

private:
	void setTexParams(GLenum target);
	
	QString m_filename;
	Settings m_settings;
	uint m_id;
};

#endif
