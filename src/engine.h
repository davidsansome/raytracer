#ifndef ENGINE_H
#define ENGINE_H

#include "utilities.h"
#include "timedependentvariable.h"

#include <QGLWidget>
#include <QTime>

class Shader;
class Texture;
class QKeyEvent;
class QTimer;

class KeyHandler
{
public:
	KeyHandler() : m_value(false), m_releasing(false) {}
	
	operator bool ()
	{
		bool ret = m_value;
		if (m_releasing)
		{
			m_releasing = false;
			m_value = false;
		}
		return ret;
	}
	
	void operator =(bool other)
	{
		if (other)
		{
			m_value = true;
			m_releasing = false;
		}
		else
		{
			m_releasing = true;
		}
	}
	
private:
	bool m_value;
	bool m_releasing;
};

class Engine : public QGLWidget
{
public:
	Engine();
	~Engine();
	
protected:
	void initializeGL();
	void resizeGL(int width, int height);
	void paintGL();
	
	void keyPressEvent(QKeyEvent* e);
	void keyReleaseEvent(QKeyEvent* e);

private:
	void drawScreenQuad();
	void updateVariables();
	
	TimeDependentVariable m_horizRotation;
	TimeDependentVariable m_vertRotation;
	TimeDependentVariable m_position[3];
	
	KeyHandler m_forwardPressed;
	KeyHandler m_backPressed;
	KeyHandler m_turnLeftPressed;
	KeyHandler m_turnRightPressed;
	
	QTimer* m_frameTimer;
	QTime m_timeElapsed;
	float m_timeDelta;
	
	Shader* m_shader;
	int m_pixelSizeLoc;
	int m_passThroughLoc;
	int m_textureLoc;
	float m_aspectRatio;
	
	Texture* m_texture;
};

#endif
