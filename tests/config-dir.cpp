// configDir() moves an existing ~/.config/caelestia to ~/.config/aether once. This pins the
// copy (not move), the three legacy trees, and the fact that the old directory survives.
#include <qdir.h>
#include <qfile.h>
#include <qfileinfo.h>
#include <qstandardpaths.h>
#include <qtemporarydir.h>

#include <cstdio>

#include "Aether/Config/paths.hpp"

using namespace aether::shell::config;

namespace {

bool writeFile(const QString& path, const QByteArray& data) {
    QDir().mkpath(QFileInfo(path).absolutePath());
    QFile file(path);
    return file.open(QIODevice::WriteOnly) && file.write(data) == data.size();
}

int fail(const char* message) {
    std::fprintf(stderr, "config-dir: %s\n", message);
    return 1;
}

} // namespace

int main() {
    QTemporaryDir tmp;
    if (!tmp.isValid())
        return fail("could not create a temp dir");

    const QString root = tmp.path();
    qputenv("HOME", (root + "/home").toUtf8());
    qputenv("XDG_CONFIG_HOME", (root + "/config").toUtf8());
    qputenv("XDG_DATA_HOME", (root + "/data").toUtf8());
    qputenv("XDG_STATE_HOME", (root + "/state").toUtf8());

    if (!writeFile(root + "/config/caelestia/shell.json", R"({"aether":{"features":{}}})"))
        return fail("could not write the legacy config");
    if (!writeFile(root + "/data/caelestia/themes/night/wallpaper.jpg", "x"))
        return fail("could not write the legacy data");
    if (!writeFile(root + "/state/caelestia/scheme.json", "{}"))
        return fail("could not write the legacy state");

    const QString dir = configDir();
    if (dir != root + "/config/aether")
        return fail("configDir() did not switch to the aether directory");
    if (!QFile::exists(dir + "/shell.json"))
        return fail("shell.json was not copied");
    if (!QFile::exists(root + "/data/aether/themes/night/wallpaper.jpg"))
        return fail("the user theme directory was not copied");
    if (!QFile::exists(root + "/state/aether/scheme.json"))
        return fail("the scheme state was not copied");
    if (!QFile::exists(root + "/config/caelestia/shell.json"))
        return fail("the legacy directory was moved or removed");

    std::printf("PASS: copied the legacy config, data and state; kept the originals\n");
    return 0;
}
