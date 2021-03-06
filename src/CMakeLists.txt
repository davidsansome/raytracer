# Source files
SET(RAYTRACER-SOURCES
	main.cpp
	engine.cpp
	shader.cpp
	texture.cpp
	glwin.cpp
	utilities.cpp
	timedependentvariable.cpp
)

# Header files that have Q_OBJECT in
SET(RAYTRACER-MOC-HEADERS
)

# UI files
SET(RAYTRACER-UI
)

# Resource files
SET(RAYTRACER-RESOURCES
	shaders.qrc
	textures.qrc
)

SET (EXECUTABLE_OUTPUT_PATH ..)

QT4_WRAP_CPP(RAYTRACER-SOURCES-MOC ${RAYTRACER-MOC-HEADERS})
QT4_WRAP_UI(RAYTRACER-SOURCES-UI ${RAYTRACER-UI})
QT4_ADD_RESOURCES(RAYTRACER-SOURCES-RESOURCE ${RAYTRACER-RESOURCES})

INCLUDE_DIRECTORIES(
	${CMAKE_CURRENT_BINARY_DIR}
	${CMAKE_CURRENT_SOURCE_DIR}
	${OPENGL_INCLUDE_DIR}
)

ADD_EXECUTABLE(raytracer ${RAYTRACER-SOURCES} ${RAYTRACER-SOURCES-MOC} ${RAYTRACER-SOURCES-UI} ${RAYTRACER-SOURCES-RESOURCE})

TARGET_LINK_LIBRARIES(raytracer
	${QT_QTCORE_LIBRARY}
	${QT_QTGUI_LIBRARY}
	${QT_QTOPENGL_LIBRARY}
	${OPENGL_LIBRARIES}
	-lsvl
)

INSTALL(TARGETS raytracer
	RUNTIME DESTINATION bin)
