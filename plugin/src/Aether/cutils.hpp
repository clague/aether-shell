#pragma once

#include <qlist.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qquickitem.h>
#include <qstringlist.h>
#include <qvariant.h>

namespace aether::shell {

class CUtils : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QString version READ version CONSTANT)
    Q_PROPERTY(QString qtVersion READ qtVersion CONSTANT)

public:
    // No-op for declaring variable/expression dependencies in QML bindings
    Q_INVOKABLE static void dependency(const QVariant& value);

    Q_INVOKABLE void saveItem(
        QQuickItem* target, const QUrl& path, const QJSValue& onSaved = {}, const QJSValue& onFailed = {});
    Q_INVOKABLE void saveItem(QQuickItem* target, const QUrl& path, const QRect& rect, const QJSValue& onSaved = {},
        const QJSValue& onFailed = {});

    Q_INVOKABLE static bool copyFile(const QUrl& source, const QUrl& target, bool overwrite = true);
    Q_INVOKABLE static bool deleteFile(const QUrl& path);
    Q_INVOKABLE static QString toLocalFile(const QUrl& url);
    Q_INVOKABLE static QString findExecutable(const QString& name);
    Q_INVOKABLE static QString sha256(const QString& path);

    Q_INVOKABLE static qreal clamp(qreal value, qreal min, qreal max);
    Q_INVOKABLE static bool fileExists(const QString& path);
    Q_INVOKABLE static QString readFile(const QString& path);
    Q_INVOKABLE static bool writeFile(const QString& path, const QString& content);

    Q_INVOKABLE static QString enumToString(QObject* target, const QString& property, const QVariant& value = {});

    Q_INVOKABLE static QQuickItem* findChild(QQuickItem* root, const QString& name);
    Q_INVOKABLE static QList<QQuickItem*> findChildren(QQuickItem* root, const QString& name);
    Q_INVOKABLE static QList<QQuickItem*> findChildrenMatching(QQuickItem* root, const QString& pattern);

    // The QStyle keys Qt can create on this machine, for the settings UI. Built without
    // QStyleFactory, which lives in QtWidgets and is not linked here.
    Q_INVOKABLE static QStringList availableQtStyles();

    // Installed icon themes, for the Qt settings page: one entry per directory that carries an
    // index.theme, in the three places the icon spec searches.
    Q_INVOKABLE static QStringList availableIconThemes();

    // The icon theme the session itself is using (kdeglobals [Icons] Theme), so the settings page
    // can show what "follow the desktop" resolves to instead of leaving it a guess.
    Q_INVOKABLE static QString desktopIconTheme();

    // The icon theme the caelestia CLI generated (qtengine/config.json), which is what a machine
    // without KDE falls back to.
    Q_INVOKABLE static QString qtConfigIconTheme();

    // The font fontconfig resolves, so the settings page can show what "follow fontconfig" gives.
    // `fixed` asks for fontconfig's monospace font instead of its UI font.
    Q_INVOKABLE static QString systemFont(bool fixed = false);

    [[nodiscard]] static QString version();
    [[nodiscard]] static QString qtVersion();
    Q_INVOKABLE static bool mkdirp(const QString& path);
};

} // namespace aether::shell
