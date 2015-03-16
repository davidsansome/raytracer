#include <QApplication>

#include "engine.h"

int main(int argc, char** argv)
{
	QApplication app(argc, argv);
	
	Engine win;
	win.show();

	return app.exec();
}
