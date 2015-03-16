#include "engine.h"
#include "shader.h"
#include "texture.h"

#include <cmath>

#include <QDebug>
#include <QTime>
#include <QKeyEvent>
#include <QTimer>

Engine::Engine()
	: QGLWidget()
{
	m_horizRotation.setModulo(M_PI*2);
	
	m_frameTimer = new QTimer(this);
	connect(m_frameTimer, SIGNAL(timeout()), SLOT(update()));
	m_frameTimer->start(0);
	
	resize(800, 600);
}

Engine::~Engine()
{
}

void Engine::initializeGL()
{
	setupWinGLFunctions();
	
	glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
	glEnable(GL_BLEND);
	
	m_shader = new Shader(":shaders/raytracer_vert.glsl", ":shaders/raytracer_frag.glsl");
	m_pixelSizeLoc = m_shader->uniformLocation("pixelSize");
	m_passThroughLoc = m_shader->uniformLocation("objectPassThrough");
	m_textureLoc = m_shader->uniformLocation("texture");
	
	m_texture = new Texture(":textures/checkerboard.png", Texture::Mipmaps);
	
	m_timeElapsed.start();
}

void Engine::resizeGL(int width, int height)
{
	m_aspectRatio = float(width)/height;
	m_shader->bind();
	glUniform2f(m_pixelSizeLoc, m_aspectRatio / width, 1.0 / height);
	m_texture->bind(0, m_textureLoc);
	m_aspectRatio /= 2.0;
	
	glViewport(0, 0, width, height);
	
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
}

void Engine::paintGL()
{
	m_timeDelta = m_timeElapsed.restart();
	qDebug() << "Frame time" << m_timeDelta << "ms";
	updateVariables();
	
	glClear(GL_COLOR_BUFFER_BIT);
	
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	
	// Light position
	float lightPos[] = {0.0, 5.0, 0.0, 1.0};
	glLightfv(GL_LIGHT0, GL_POSITION, lightPos);
	
	// Camera position
	glTranslatef(m_position[0], m_position[1], m_position[2]);
	glRotatef(m_horizRotation / M_PI * 180.0, 0.0, 1.0, 0.0);
	
	// Draw passes
	for (int i=1 ; i>=0 ; --i)
	{
		glUniform1i(m_passThroughLoc, i);
		drawScreenQuad();
	}
}

void Engine::drawScreenQuad()
{
	glBegin(GL_QUADS);
		glTexCoord2f(-m_aspectRatio, 0.5);
		glVertex2f(-1.0f, 1.0f);
	
		glTexCoord2f(m_aspectRatio, 0.5);
		glVertex2f(1.0f, 1.0f);
	
		glTexCoord2f(m_aspectRatio, -0.5);
		glVertex2f(1.0f, -1.0f);
	
		glTexCoord2f(-m_aspectRatio, -0.5);
		glVertex2f(-1.0f, -1.0f);
	glEnd();
}

void Engine::keyPressEvent(QKeyEvent* e)
{
	switch (e->key())
	{
		case Qt::Key_Up:    m_forwardPressed = true;   break;
		case Qt::Key_Down:  m_backPressed = true;      break;
		case Qt::Key_Left:  m_turnLeftPressed = true;  break;
		case Qt::Key_Right: m_turnRightPressed = true; break;
	}
}

void Engine::keyReleaseEvent(QKeyEvent* e)
{
	switch (e->key())
	{
		case Qt::Key_Up:    m_forwardPressed = false;   break;
		case Qt::Key_Down:  m_backPressed = false;      break;
		case Qt::Key_Left:  m_turnLeftPressed = false;  break;
		case Qt::Key_Right: m_turnRightPressed = false; break;
	}
}

void Engine::updateVariables()
{
	// Handle left/right movement
	if (m_turnLeftPressed)    m_horizRotation = m_horizRotation.targetValue() - m_timeDelta / 4000.0 * M_PI;
	if (m_turnRightPressed)   m_horizRotation = m_horizRotation.targetValue() + m_timeDelta / 4000.0 * M_PI;
	m_horizRotation.finishedEditing();
	
	// Handle forward/back movement
	float speed = 0.0;
	if (m_forwardPressed) speed = 1.0;
	if (m_backPressed) speed = -1.0;
	
	float xDelta = speed * 2.5 * m_timeDelta / 1000.0 * sin(m_horizRotation);
	float zDelta = speed * 2.5 * m_timeDelta / 1000.0 * cos(m_horizRotation);
	
	m_position[0] = m_position[0].targetValue() + xDelta;
	m_position[2] = m_position[2].targetValue() + zDelta;
	
	// Update TDVs
	m_position[0].update(int(m_timeDelta));
	m_position[1].update(int(m_timeDelta));
	m_position[2].update(int(m_timeDelta));
	m_horizRotation.update(int(m_timeDelta));
	m_vertRotation.update(int(m_timeDelta));
}


