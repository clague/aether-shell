#include <qpa/qplatformtheme.h>
#include <qpa/qplatformthemeplugin.h>
#include <qstring.h>
#include <qstringlist.h>
#include <qtmetamacros.h>

#include "aethertheme.hpp"

namespace {

// Qt matches QT_QPA_PLATFORMTHEME against the key in aether.json, not against the library name,
// so `aether` here is the string a user puts in their environment.
class AetherThemePlugin final : public QPlatformThemePlugin {
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.qt-project.Qt.QPA.QPlatformThemeFactoryInterface.5.1" FILE "aether.json")

public:
    [[nodiscard]] QPlatformTheme* create(const QString& key, const QStringList& params) override {
        Q_UNUSED(params)

        using Qt::StringLiterals::operator""_s;
        if (key.compare(u"aether"_s, Qt::CaseInsensitive) != 0)
            return nullptr;

        return new aether::theme::AetherTheme();
    }
};

} // namespace

#include "thememain.moc"
