// Pins the one-way `hybrid` -> `aether` config rename: values survive, other keys survive,
// and the pre-rename file is kept for a downgrade.
#include <qfile.h>
#include <qjsondocument.h>
#include <qjsonobject.h>
#include <qtemporarydir.h>

#include <cstdio>

#include "Aether/Config/migrate.hpp"

using aether::shell::config::migrateLegacyFeatureBlock;

namespace {

int failures = 0;

void check(bool ok, const char* what) {
    if (!ok) {
        std::printf("  FAIL: %s\n", what);
        ++failures;
    }
}

void writeFile(const QString& path, const QByteArray& data) {
    QFile file(path);
    file.open(QIODevice::WriteOnly);
    file.write(data);
    file.close();
}

QJsonObject readObject(const QString& path) {
    QFile file(path);
    file.open(QIODevice::ReadOnly);
    const auto doc = QJsonDocument::fromJson(file.readAll());
    file.close();
    return doc.object();
}

} // namespace

int main() {
    QTemporaryDir directory;
    if (!directory.isValid()) {
        std::printf("  FAIL: no temporary directory\n");
        return 1;
    }

    const QString path = directory.path() + "/shell.json";
    check(!migrateLegacyFeatureBlock(path), "a missing file is left alone");

    const QByteArray original =
        R"({"hybrid":{"features":{"hotspot":true},"variants":{"dock":"op"}},"general":{"scale":1}})";
    writeFile(path, original);
    check(migrateLegacyFeatureBlock(path), "the legacy block is migrated");

    const auto migrated = readObject(path);
    check(!migrated.contains("hybrid"), "the old key is gone");
    const auto aether = migrated.value("aether").toObject();
    check(aether.value("features").toObject().value("hotspot").toBool(), "feature values survive");
    check(aether.value("variants").toObject().value("dock").toString() == "op", "variant values survive");
    check(migrated.value("general").toObject().value("scale").toInt() == 1, "other keys survive");

    QFile backup(path + ".pre-aether");
    check(backup.exists(), "the pre-rename file is kept");
    backup.open(QIODevice::ReadOnly);
    check(backup.readAll() == original, "the backup is the original file");

    check(!migrateLegacyFeatureBlock(path), "a second run does nothing");

    // If both keys exist, the new one wins and the old one is still removed.
    writeFile(path, R"({"hybrid":{"features":{"x":false}},"aether":{"features":{"x":true}}})");
    check(migrateLegacyFeatureBlock(path), "both keys are handled");
    const auto both = readObject(path);
    check(both.value("aether").toObject().value("features").toObject().value("x").toBool(), "aether wins");
    check(!both.contains("hybrid"), "hybrid is removed");

    writeFile(path, "{");
    check(!migrateLegacyFeatureBlock(path), "malformed JSON is left alone");
    writeFile(path, "{}");
    check(!migrateLegacyFeatureBlock(path), "a file without the key is left alone");

    if (failures == 0)
        std::printf("PASS: 0 failure(s)\n");
    return failures == 0 ? 0 : 1;
}
