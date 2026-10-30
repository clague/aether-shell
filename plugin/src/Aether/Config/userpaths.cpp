#include "userpaths.hpp"

#include <qfileinfo.h>

#include "settings/common.hpp"

namespace aether::shell::config {

using Qt::StringLiterals::operator""_s;

namespace detail {

QString themeAsset(const settings::Node* self, const QString& file, const QString& fallback) {
    const QString theme = self ? self->value(u"themeName"_s).toString() : QString();
    if (theme.isEmpty())
        return fallback;
    // Themes the user added (~/.local/share/caelestia/themes/<name>/) win over the bundled ones,
    // so a packaged read-only install can still have themes.
    QString userPath = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + u"/caelestia/themes/"_s +
                       theme + u'/' + file;
    if (QFileInfo::exists(userPath))
        return userPath;
    return u"root:/assets/themes/"_s + theme + u'/' + file;
}

} // namespace detail

namespace {

// The themed keys, in declaration order: config key -> (theme asset file, static fallback).
// The file and fallback are the macro arguments THEMED_PATH used to pass into the default
// lambdas; the settings schema moved to static defaults, so reresolve() applies the theme
// through this table instead.
struct ThemedPath {
    const char* key;
    const char* file;
    const char* fallback;
};

const QList<ThemedPath>& themedPaths() {
    static const QList<ThemedPath> k_list{
        { .key = "sessionGif", .file = "session.gif", .fallback = "root:/assets/kurukuru.gif" },
        { .key = "mediaGif", .file = "media.gif", .fallback = "root:/assets/bongocat.gif" },
        { .key = "noNotifsPic", .file = "notif.png", .fallback = "root:/assets/dino.png" },
        { .key = "lockNoNotifsPic", .file = "notif.png", .fallback = "root:/assets/dino.png" },
    };
    return k_list;
}

} // namespace

// Re-resolve every themed key the user has *not* set. Deliberately not resetToDefaults(): that
// writes every key unconditionally, and under the ambient write origin each write is recorded
// as an override -- so switching theme would overwrite the user's own explicit paths with the
// theme's, which is the opposite of what a default means. WriteOrigin::Layer records nothing.
void UserPaths::reresolve() {
    const settings::WriteScope scope(this, settings::WriteOrigin::Layer);
    for (const auto& themed : themedPaths()) {
        const auto key = QString::fromUtf8(themed.key);
        if (isOverride(key))
            continue;
        setValue(key, detail::themeAsset(this, QString::fromUtf8(themed.file), QString::fromUtf8(themed.fallback)));
    }
}

UserPaths::UserPaths(UserPaths* fallback, QObject* parent, bool globalOnly)
    : settings::ObjectNode(fallback, parent, globalOnly) {
    // Every themed path is a function of themeName, so changing the theme has to re-resolve
    // them. Anything the user set stays set.
    connect(this, &UserPaths::themeNameChanged, this, [this] {
        reresolve();
    });
}

} // namespace aether::shell::config
