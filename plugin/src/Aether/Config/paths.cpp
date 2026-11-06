#include "paths.hpp"

#include <qdir.h>
#include <qfile.h>
#include <qfileinfo.h>
#include <qstandardpaths.h>

namespace aether::shell::config {

using Qt::StringLiterals::operator""_s;

Q_LOGGING_CATEGORY(lcConfig, "aether.config", QtInfoMsg)

namespace {

// Copy the old caelestia tree into the new aether one once. Copy, never move: a caelestia-shell
// install keeps its own settings and the two can coexist. Missing files only, so a rerun after a
// partial copy does not overwrite anything.
void copyDir(const QString& from, const QString& to) {
    const QDir source(from);
    if (!source.exists())
        return;

    QDir().mkpath(to);
    const auto entries = source.entryInfoList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot | QDir::Hidden);
    for (const QFileInfo& entry : entries) {
        // A symlink to a directory is recursed into by isDir(), so one `self -> .` in the old
        // config turns the first start into a stack overflow.
        if (entry.isSymLink())
            continue;
        const QString target = to + u'/' + entry.fileName();
        if (entry.isDir())
            copyDir(entry.absoluteFilePath(), target);
        else if (!QFileInfo::exists(target))
            QFile::copy(entry.absoluteFilePath(), target);
    }
}

void copyLegacyBase(QStandardPaths::StandardLocation location) {
    const QString base = QStandardPaths::writableLocation(location);
    copyDir(base + u"/caelestia"_s, base + u"/aether"_s);
}

} // namespace

QString configDir() {
    static const QString k_dir = [] {
        const QString base = QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation);
        const QString current = base + u"/aether"_s;
        if (!QFileInfo::exists(current)) {
            copyDir(base + u"/caelestia"_s, current);
            copyLegacyBase(QStandardPaths::GenericDataLocation);
            copyLegacyBase(QStandardPaths::GenericStateLocation);
            qCInfo(lcConfig) << "copied legacy caelestia configuration to" << current;
        }
        return current;
    }();
    return k_dir;
}

QString monitorConfigDir() {
    return configDir() + u"/monitors"_s;
}

} // namespace aether::shell::config
