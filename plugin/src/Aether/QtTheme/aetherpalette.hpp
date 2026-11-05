#pragma once

#include <qbytearray.h>
#include <qpalette.h>

#include <optional>

namespace aether::theme {

// The part of Aether's scheme a Qt application can use: the palette itself, plus which side of
// light/dark it is on, which picks the default icon theme.
struct Scheme {
    QPalette palette;
    bool light = true;
};

// Translates the JSON the shell writes to scheme.json. Returns nullopt for a missing, truncated
// or unrecognisable file: the caller then leaves Qt's own palette alone rather than painting the
// user's apps with a half-built one.
[[nodiscard]] std::optional<Scheme> schemeFromJson(const QByteArray& json);

} // namespace aether::theme
