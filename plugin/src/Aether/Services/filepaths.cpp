#include "filepaths.hpp"

#include <qfileinfo.h>

namespace aether::services {

using Qt::StringLiterals::operator""_s;

QString uniquePath(const QString& directory, const QString& fileName) {
    // The name comes from a peer. Keep only the last component, or "../../.bashrc" would write
    // outside the directory (and QSaveFile would happily rename it there).
    QString name = QFileInfo(fileName).fileName();
    if (name.isEmpty() || name == u"."_s || name == u".."_s)
        name = u"download"_s;

    const QFileInfo info(name);

    // A dotfile (".bashrc") has no base name and no suffix split worth making; index the whole
    // name instead of producing " (1).bashrc".
    const bool split = !info.completeBaseName().isEmpty();
    const QString base = split ? info.completeBaseName() : name;
    const QString suffix = split ? info.suffix() : QString();

    QString candidate = directory + u'/' + name;
    for (int index = 1; QFileInfo::exists(candidate); ++index) {
        candidate = directory + u'/' + base + u" ("_s + QString::number(index) + u')';
        if (!suffix.isEmpty())
            candidate += u'.' + suffix;
    }

    return candidate;
}

} // namespace aether::services
