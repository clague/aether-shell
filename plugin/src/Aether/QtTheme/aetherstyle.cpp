#include "aetherstyle.hpp"

#include <qjsondocument.h>
#include <qjsonobject.h>
#include <qjsonvalue.h>
#include <qlist.h>
#include <qstringview.h>

namespace aether::theme {

using Qt::StringLiterals::operator""_s;

QString kvantumThemeName(const QByteArray& ini) {
    // The QString owns the bytes the views point into, so it has to outlive the loop.
    const QString text = QString::fromUtf8(ini);

    for (QStringView line : QStringView(text).split(u'\n', Qt::SkipEmptyParts)) {
        line = line.trimmed();
        if (line.isEmpty() || line.startsWith(u'#') || line.startsWith(u';') || line.startsWith(u'['))
            continue;

        const qsizetype eq = line.indexOf(u'=');
        if (eq < 0 || line.left(eq).trimmed() != u"theme"_s)
            continue;

        QString name = line.mid(eq + 1).trimmed().toString();
        if (name.size() >= 2 && name.startsWith(u'"') && name.endsWith(u'"'))
            name = name.mid(1, name.size() - 2);
        return name;
    }

    return {};
}

QString shellQtStyle(const QByteArray& json) {
    const QJsonDocument document = QJsonDocument::fromJson(json);
    if (!document.isObject())
        return {};

    const QJsonValue value = document.object().value(u"appearance"_s).toObject().value(u"qtStyle"_s);
    return value.isString() ? value.toString() : QString();
}

} // namespace aether::theme
