/*
 * SPDX-FileCopyrightText: (C) 2020 Carl Schwan <carl@carlschwan.eu>
 *
 * SPDX-LicenseRef: GPL-3.0-or-later
 */
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QIcon>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("Samegame"));
    app.setApplicationVersion(QStringLiteral("1.0"));
    app.setOrganizationName(QStringLiteral("KDE"));

#ifdef Q_OS_ANDROID
    QQuickStyle::setStyle(QStringLiteral("Material"));
#endif

    app.setWindowIcon(QIcon(QStringLiteral(":/contents/ui/shared/pics/star.png")));

    QQmlApplicationEngine engine;
    engine.load(QUrl(QStringLiteral("qrc:/contents/ui/samegame.qml")));

    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

    return app.exec();
}
