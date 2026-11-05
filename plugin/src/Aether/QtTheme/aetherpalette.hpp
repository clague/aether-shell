#pragma once

#include <qbytearray.h>
#include <qjsonobject.h>
#include <qpalette.h>
#include <qstring.h>

#include <optional>

namespace aether::theme {

// The part of Aether's scheme a Qt application can use: the palette itself, plus which side of
// light/dark it is on, which picks the default icon theme.
struct Scheme {
    QPalette palette;
    bool light = true;
    // Kept so the same parse can produce the KDE-format copy below, without reading the file twice.
    QJsonObject colours;
};

// Translates the JSON the shell writes to scheme.json. Returns nullopt for a missing, truncated
// or unrecognisable file: the caller then leaves Qt's own palette alone rather than painting the
// user's apps with a half-built one.
[[nodiscard]] std::optional<Scheme> schemeFromJson(const QByteArray& json);

// The same scheme in the KDE colour-scheme format. KDE applications paint through KColorScheme,
// which reads a .colors file via the KDE_COLOR_SCHEME_PATH application property, not QPalette --
// so this is the file that decides what Dolphin's places panel looks like.
[[nodiscard]] QByteArray kdeColorScheme(const QJsonObject& colours, const QString& name);

} // namespace aether::theme
