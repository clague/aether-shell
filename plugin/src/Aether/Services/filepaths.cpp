#include "filepaths.hpp"

#include <qfileinfo.h>

namespace aether::services {

using Qt::StringLiterals::operator""_s;

QString uniquePath(const QString& directory, const QString& fileName) {
    const QFileInfo info(fileName);

    // A dotfile (".bashrc") has no base name and no suffix split worth making; index the whole
    // name instead of producing " (1).bashrc".
    const bool split = !info.completeBaseName().isEmpty();
    const QString base = split ? info.completeBaseName() : fileName;
    const QString suffix = split ? info.suffix() : QString();

    QString candidate = directory + u'/' + fileName;
    for (int index = 1; QFileInfo::exists(candidate); ++index) {
        candidate = directory + u'/' + base + u" ("_s + QString::number(index) + u')';
        if (!suffix.isEmpty())
            candidate += u'.' + suffix;
    }

    return candidate;
}

} // namespace aether::services
