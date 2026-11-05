#include "aetherstyle.hpp"

#include <qjsondocument.h>
#include <qjsonobject.h>
#include <qjsonvalue.h>
#include <qlist.h>
#include <qstringview.h>

namespace aether::theme {

using Qt::StringLiterals::operator""_s;

QString iniValue(const QByteArray& ini, const QString& section, const QString& key) {
    // The QString owns the bytes the views point into, so it has to outlive the loop.
    const QString text = QString::fromUtf8(ini);
    QString current;

    for (QStringView line : QStringView(text).split(u'\n', Qt::SkipEmptyParts)) {
        line = line.trimmed();
        if (line.isEmpty() || line.startsWith(u'#') || line.startsWith(u';'))
            continue;

        if (line.startsWith(u'[') && line.endsWith(u']')) {
            current = line.mid(1, line.size() - 2).toString();
            continue;
        }

        const qsizetype eq = line.indexOf(u'=');
        if (eq < 0 || current != section || line.left(eq).trimmed() != key)
            continue;

        QString value = line.mid(eq + 1).trimmed().toString();
        if (value.size() >= 2 && value.startsWith(u'"') && value.endsWith(u'"'))
            value = value.mid(1, value.size() - 2);
        return value;
    }

    return {};
}

QString kvantumThemeName(const QByteArray& ini) {
    // kvantummanager writes [General], but a hand-written file may have no header at all, and
    // Kvantum itself does not care. Accept both.
    const QString scoped = iniValue(ini, u"General"_s, u"theme"_s);
    return scoped.isEmpty() ? iniValue(ini, QString(), u"theme"_s) : scoped;
}

QtSettings qtSettingsFromJson(const QByteArray& json) {
    QtSettings settings;
    const QJsonDocument document = QJsonDocument::fromJson(json);
    if (!document.isObject())
        return settings;

    const QJsonObject qt = document.object().value(u"qt"_s).toObject();
    if (qt.isEmpty())
        return settings;

    const auto text = [&qt](const QString& key, const QString& fallback) {
        const QJsonValue value = qt.value(key);
        return value.isString() ? value.toString() : fallback;
    };
    const auto number = [&qt](const QString& key, int fallback) {
        const QJsonValue value = qt.value(key);
        return value.isDouble() ? value.toInt() : fallback;
    };
    const auto flag = [&qt](const QString& key, bool fallback) {
        const QJsonValue value = qt.value(key);
        return value.isBool() ? value.toBool() : fallback;
    };

    settings.style = text(u"style"_s, settings.style);
    settings.iconTheme = text(u"iconTheme"_s, settings.iconTheme);
    settings.font = text(u"font"_s, settings.font);
    settings.fontSize = number(u"fontSize"_s, settings.fontSize);
    settings.fontFixed = text(u"fontFixed"_s, settings.fontFixed);
    settings.fontFixedSize = number(u"fontFixedSize"_s, settings.fontFixedSize);
    settings.menusHaveIcons = flag(u"menusHaveIcons"_s, settings.menusHaveIcons);
    settings.shortcutsInContextMenus = flag(u"shortcutsInContextMenus"_s, settings.shortcutsInContextMenus);
    settings.toolButtonStyle = number(u"toolButtonStyle"_s, settings.toolButtonStyle);
    settings.wheelScrollLines = number(u"wheelScrollLines"_s, settings.wheelScrollLines);
    settings.cursorFlashTime = number(u"cursorFlashTime"_s, settings.cursorFlashTime);
    settings.doubleClickInterval = number(u"doubleClickInterval"_s, settings.doubleClickInterval);
    return settings;
}

} // namespace aether::theme
