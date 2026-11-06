#include "migrate.hpp"

#include <qfile.h>
#include <qjsondocument.h>
#include <qjsonobject.h>
#include <qsavefile.h>

namespace aether::shell::config {

using Qt::StringLiterals::operator""_s;

bool migrateLegacyFeatureBlock(const QString& path) {
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly))
        return false;

    const auto data = file.readAll();
    file.close();

    QJsonParseError error;
    const auto doc = QJsonDocument::fromJson(data, &error);
    if (error.error != QJsonParseError::NoError || !doc.isObject())
        return false;

    auto obj = doc.object();
    if (!obj.contains(u"hybrid"_s))
        return false;

    // Keep the pre-rename file once. If it cannot be written, do not rewrite the original:
    // losing the old key is worse than skipping the migration.
    const QString backup = path + u".pre-aether"_s;
    if (!QFile::exists(backup) && !QFile::copy(path, backup))
        return false;

    if (!obj.contains(u"aether"_s))
        obj.insert(u"aether"_s, obj.value(u"hybrid"_s));
    obj.remove(u"hybrid"_s);

    QSaveFile out(path);
    if (!out.open(QIODevice::WriteOnly))
        return false;
    out.write(QJsonDocument(obj).toJson());
    return out.commit();
}

} // namespace aether::shell::config
