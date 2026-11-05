#pragma once

#include <qbytearray.h>
#include <qstring.h>
#include <qstringliteral.h>

namespace aether::theme {

// The theme name kvantummanager recorded in ~/.config/Kvantum/kvantum.kvconfig.
//
// Parsed here rather than through QSettings because QSettings maps a bare [General] section onto
// the root: `value("General/theme")` returns an empty string from a file that plainly contains it,
// and the failure is silent. The file kvantummanager writes has exactly one setting we care about,
// so reading it directly is both smaller and predictable.
[[nodiscard]] QString iniValue(const QByteArray& ini, const QString& section, const QString& key);

[[nodiscard]] QString kvantumThemeName(const QByteArray& ini);

// Everything the Qt theme takes from the shell's own config (~/.config/caelestia/shell.json),
// under the `qt` node. Defaults match what the session would do on its own, so a machine that has
// never opened the settings page behaves exactly as before.
struct QtSettings {
    QString style = QStringLiteral("auto");
    QString iconTheme;
    QString font;
    int fontSize = 0;
    QString fontFixed;
    int fontFixedSize = 0;
    bool menusHaveIcons = true;
    bool shortcutsInContextMenus = true;
    int toolButtonStyle = 2;
    int wheelScrollLines = 3;
    int cursorFlashTime = 1000;
    int doubleClickInterval = 400;
};

[[nodiscard]] QtSettings qtSettingsFromJson(const QByteArray& json);

} // namespace aether::theme
