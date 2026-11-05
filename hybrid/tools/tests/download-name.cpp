// Pins the name a QuickShare transfer is saved under. The transfer used to overwrite whatever was
// already in ~/Downloads with the same name, and a test is the only place that is cheap to check.
#include <qdir.h>
#include <qfile.h>
#include <qtemporarydir.h>

#include <cstdio>

#include "filepaths.hpp"

using aether::services::uniquePath;

namespace {

int failures = 0;

void check(bool ok, const char* what) {
    if (!ok) {
        std::printf("  FAIL: %s\n", what);
        ++failures;
    }
}

void touch(const QString& path) {
    QFile file(path);
    file.open(QIODevice::WriteOnly);
    file.close();
}

} // namespace

int main() {
    QTemporaryDir directory;
    if (!directory.isValid()) {
        std::printf("  FAIL: no temporary directory\n");
        return 1;
    }

    const QString dir = directory.path();
    check(uniquePath(dir, "photo.jpg") == dir + "/photo.jpg", "a free name is used unchanged");

    touch(dir + "/photo.jpg");
    check(uniquePath(dir, "photo.jpg") == dir + "/photo (1).jpg", "first collision gets (1)");

    touch(dir + "/photo (1).jpg");
    check(uniquePath(dir, "photo.jpg") == dir + "/photo (2).jpg", "second collision gets (2)");

    check(uniquePath(dir, "README") == dir + "/README", "a name without a suffix still works");
    touch(dir + "/README");
    check(uniquePath(dir, "README") == dir + "/README (1)", "and is numbered without a dot");

    touch(dir + "/.bashrc");
    check(uniquePath(dir, ".bashrc") == dir + "/.bashrc (1)", "a dotfile keeps its dot");

    if (failures == 0)
        std::printf("PASS: 0 failure(s)\n");
    return failures == 0 ? 0 : 1;
}
