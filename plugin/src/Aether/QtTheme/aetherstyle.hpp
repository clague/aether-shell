#pragma once

#include <qbytearray.h>
#include <qstring.h>

namespace aether::theme {

// The theme name kvantummanager recorded in ~/.config/Kvantum/kvantum.kvconfig.
//
// Parsed here rather than through QSettings because QSettings maps a bare [General] section onto
// the root: `value("General/theme")` returns an empty string from a file that plainly contains it,
// and the failure is silent. The file kvantummanager writes has exactly one setting we care about,
// so reading it directly is both smaller and predictable.
[[nodiscard]] QString iniValue(const QByteArray& ini, const QString& section, const QString& key);

[[nodiscard]] QString kvantumThemeName(const QByteArray& ini);

// The style named in the shell's own config (appearance.qtStyle in ~/.config/caelestia/shell.json).
// Empty when unset, which is not the same as "auto": both fall back to the automatic chain, but the
// caller distinguishes them in a warning.
[[nodiscard]] QString shellQtStyle(const QByteArray& json);

} // namespace aether::theme
