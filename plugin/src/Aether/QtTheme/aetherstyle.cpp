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

QString shellQtStyle(const QByteArray& json) {
    const QJsonDocument document = QJsonDocument::fromJson(json);
    if (!document.isObject())
        return {};

    const QJsonValue value = document.object().value(u"appearance"_s).toObject().value(u"qtStyle"_s);
    return value.isString() ? value.toString() : QString();
}

} // namespace aether::theme
