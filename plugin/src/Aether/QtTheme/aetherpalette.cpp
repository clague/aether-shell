#include "aetherpalette.hpp"

#include <qcolor.h>
#include <qjsondocument.h>
#include <qjsonobject.h>
#include <qjsonvalue.h>
#include <qstring.h>

#include <cmath>
#include <utility>

namespace aether::theme {

using Qt::StringLiterals::operator""_s;

namespace {

// Qt's own disabled groups use the same colour at reduced opacity. Anything else reads as a
// different theme rather than a disabled control.
constexpr int k_disabledOpacity = 255 / 2;

QColor parseColour(const QString& value, const QColor& fallback) {
    if (value.isEmpty())
        return fallback;

    // scheme.json stores bare hex ("130d09"), not CSS-style "#130d09".
    const QColor parsed(u'#' + value);
    return parsed.isValid() ? parsed : fallback;
}

QColor colour(const QJsonObject& colours, const QString& key, const QColor& fallback = QColor()) {
    return parseColour(colours.value(key).toString(), fallback);
}

QColor withOpacity(const QColor& colour, int alpha) {
    QColor out = colour;
    out.setAlpha(alpha);
    return out;
}

// Blend a towards b. Used to mute the selection in disabled and unfocused windows, which keeps
// the highlighted row readable instead of turning it into a block of the accent colour.
QColor mix(const QColor& a, const QColor& b, double amount) {
    const auto channel = [amount](int from, int to) {
        return static_cast<int>(std::lround(static_cast<double>(from) + (static_cast<double>(to) - from) * amount));
    };
    return { channel(a.red(), b.red()), channel(a.green(), b.green()), channel(a.blue(), b.blue()) };
}

QPalette buildPalette(const QJsonObject& colours) {
    const QColor background = colour(colours, u"background"_s, Qt::black);
    const QColor onBackground = colour(colours, u"onBackground"_s, Qt::white);
    const QColor surface = colour(colours, u"surface"_s, background);
    const QColor onSurface = colour(colours, u"onSurface"_s, onBackground);
    const QColor surfaceLow = colour(colours, u"surfaceContainerLow"_s, surface);
    const QColor surfaceContainer = colour(colours, u"surfaceContainer"_s, surface);
    const QColor surfaceHigh = colour(colours, u"surfaceContainerHigh"_s, surfaceContainer);
    const QColor surfaceBright = colour(colours, u"surfaceBright"_s, surfaceHigh);
    const QColor surfaceDim = colour(colours, u"surfaceDim"_s, background);
    const QColor onSurfaceVariant = colour(colours, u"onSurfaceVariant"_s, onSurface);
    const QColor primary = colour(colours, u"primary"_s, onSurface);
    const QColor onPrimary = colour(colours, u"onPrimary"_s, background);
    const QColor primaryDim = colour(colours, u"primaryDim"_s, mix(primary, background, 0.25));
    const QColor link = colour(colours, u"klink"_s, primary);
    const QColor visited = colour(colours, u"kvisited"_s, mix(link, onSurface, 0.4));
    const QColor onError = colour(colours, u"onError"_s, background);
    const QColor shadow = colour(colours, u"shadow"_s, Qt::black);

    // Base is where text is typed or listed, so it takes a container tone rather than the window
    // colour: a pure-black field on a near-black window reads as a hole, not an input.
    const QColor base = surfaceLow;
    const QColor alternateBase = surfaceContainer;

    QPalette palette;

    // Every role is written to all three groups. Qt falls back to the default palette for any
    // group/role pair left unset, which mixes our colours with the stock ones as soon as a
    // window loses focus.
    const auto apply = [&palette](QPalette::ColorRole role, const QColor& active, const QColor& disabled) {
        palette.setColor(QPalette::Active, role, active);
        palette.setColor(QPalette::Inactive, role, active);
        palette.setColor(QPalette::Disabled, role, disabled);
    };

    apply(QPalette::Window, background, background);
    apply(QPalette::WindowText, onBackground, withOpacity(onBackground, k_disabledOpacity));
    apply(QPalette::Base, base, base);
    apply(QPalette::AlternateBase, alternateBase, alternateBase);
    apply(QPalette::ToolTipBase, surfaceHigh, surfaceHigh);
    apply(QPalette::ToolTipText, onSurface, withOpacity(onSurface, k_disabledOpacity));
    apply(QPalette::PlaceholderText, onSurfaceVariant, withOpacity(onSurfaceVariant, k_disabledOpacity));
    apply(QPalette::Text, onSurface, withOpacity(onSurface, k_disabledOpacity));
    apply(QPalette::Button, surfaceContainer, surfaceContainer);
    apply(QPalette::ButtonText, onSurface, withOpacity(onSurface, k_disabledOpacity));
    apply(QPalette::BrightText, onError, withOpacity(onError, k_disabledOpacity));
    apply(QPalette::Light, surfaceBright, surfaceBright);
    apply(QPalette::Midlight, surfaceHigh, surfaceHigh);
    apply(QPalette::Mid, surfaceContainer, surfaceContainer);
    apply(QPalette::Dark, surfaceDim, surfaceDim);
    apply(QPalette::Shadow, shadow, shadow);
    apply(QPalette::Highlight, primary, mix(primary, background, 0.5));
    apply(QPalette::HighlightedText, onPrimary, withOpacity(onPrimary, k_disabledOpacity));
    apply(QPalette::Link, link, withOpacity(link, k_disabledOpacity));
    apply(QPalette::LinkVisited, visited, withOpacity(visited, k_disabledOpacity));
#if QT_VERSION >= QT_VERSION_CHECK(6, 6, 0)
    apply(QPalette::Accent, primary, mix(primary, background, 0.5));
#endif

    // An unfocused window keeps the accent but steps it back, the way every other desktop does.
    // Leaving the selection fully saturated makes two open windows look equally active.
    palette.setColor(QPalette::Inactive, QPalette::Highlight, primaryDim);
    palette.setColor(QPalette::Inactive, QPalette::Accent, primaryDim);
    palette.setColor(QPalette::Inactive, QPalette::WindowText, onBackground);

    return palette;
}

} // namespace

std::optional<Scheme> schemeFromJson(const QByteArray& json) {
    const QJsonDocument document = QJsonDocument::fromJson(json);
    if (!document.isObject())
        return std::nullopt;

    const QJsonObject root = document.object();
    const QJsonValue colours = root.value(u"colours"_s);
    if (!colours.isObject())
        return std::nullopt;

    // A scheme without a background is not one of ours, and guessing the rest from it would
    // paint every window with whatever the fallbacks happen to be.
    const QJsonObject map = colours.toObject();
    if (!map.contains(u"background"_s))
        return std::nullopt;

    return Scheme{
        .palette = buildPalette(map),
        .light = root.value(u"mode"_s).toString() == u"light"_s,
        .colours = map,
    };
}

namespace {

// One colour from the scheme, with "#" for the KDE format and a fallback token when a scheme is
// older than the one this engine was written against.
QString entry(const QJsonObject& colours, const QString& key, const QString& fallback = {}) {
    QString value = colours.value(key).toString();
    if (value.isEmpty())
        value = colours.value(fallback).toString();
    return value.isEmpty() ? QStringLiteral("#000000") : u'#' + value;
}

void section(QStringList& out, const QString& name) {
    out << QString() << u'[' + name + u']';
}

void row(QStringList& out, const QString& key, const QJsonObject& colours, const QString& token,
    const QString& fallback = {}) {
    out << key + u'=' + entry(colours, token, fallback);
}

// The sections KDE's own schemes carry, filled from the M3 tokens the same way the palette above
// is. kdeglobals names this file, and KColorScheme reads whichever scheme it names first.
void foregrounds(QStringList& out, const QJsonObject& colours, const QString& normal, const QString& active = {},
    const QString& link = u"klink"_s, const QString& visited = u"kvisited"_s) {
    row(out, u"ForegroundActive"_s, colours, active.isEmpty() ? normal : active, normal);
    row(out, u"ForegroundInactive"_s, colours, u"outline"_s, u"onSurfaceVariant"_s);
    row(out, u"ForegroundLink"_s, colours, link, u"primary"_s);
    row(out, u"ForegroundNegative"_s, colours, u"knegative"_s, u"error"_s);
    row(out, u"ForegroundNeutral"_s, colours, u"kneutral"_s, u"tertiary"_s);
    row(out, u"ForegroundNormal"_s, colours, normal, u"onSurface"_s);
    row(out, u"ForegroundPositive"_s, colours, u"kpositive"_s, u"success"_s);
    row(out, u"ForegroundVisited"_s, colours, visited, u"kvisited"_s);
}

} // namespace

QByteArray kdeColorScheme(const QJsonObject& colours, const QString& name) {
    QStringList out;

    section(out, u"ColorEffects:Disabled"_s);
    row(out, u"Color"_s, colours, u"surfaceContainer"_s);
    out << u"ColorAmount=0.5"_s << u"ColorEffect=3"_s << u"ContrastAmount=0"_s << u"ContrastEffect=0"_s
        << u"IntensityAmount=0"_s << u"IntensityEffect=0"_s;

    section(out, u"ColorEffects:Inactive"_s);
    out << u"ChangeSelectionColor=true"_s;
    row(out, u"Color"_s, colours, u"surfaceContainerLowest"_s);
    out << u"ColorAmount=0.025"_s << u"ColorEffect=0"_s << u"ContrastAmount=0.1"_s << u"ContrastEffect=0"_s
        << u"Enable=true"_s << u"IntensityAmount=0"_s << u"IntensityEffect=0"_s;

    section(out, u"Colors:Button"_s);
    row(out, u"BackgroundAlternate"_s, colours, u"surfaceVariant"_s);
    row(out, u"BackgroundNormal"_s, colours, u"surfaceContainerHigh"_s);
    row(out, u"DecorationFocus"_s, colours, u"primary"_s);
    row(out, u"DecorationHover"_s, colours, u"primary"_s);
    foregrounds(out, colours, u"onSurface"_s);

    section(out, u"Colors:Complementary"_s);
    row(out, u"BackgroundAlternate"_s, colours, u"surface"_s);
    row(out, u"BackgroundNormal"_s, colours, u"surfaceContainer"_s);
    row(out, u"DecorationFocus"_s, colours, u"primary"_s);
    row(out, u"DecorationHover"_s, colours, u"primary"_s);
    foregrounds(out, colours, u"onSurfaceVariant"_s, u"inverseSurface"_s);

    section(out, u"Colors:Header"_s);
    row(out, u"BackgroundAlternate"_s, colours, u"surfaceContainer"_s);
    row(out, u"BackgroundNormal"_s, colours, u"surfaceContainer"_s);
    row(out, u"DecorationFocus"_s, colours, u"primary"_s);
    row(out, u"DecorationHover"_s, colours, u"primary"_s);
    foregrounds(out, colours, u"onSurfaceVariant"_s, u"inverseSurface"_s);

    section(out, u"Colors:Header][Inactive"_s);
    row(out, u"BackgroundAlternate"_s, colours, u"surfaceContainer"_s);
    row(out, u"BackgroundNormal"_s, colours, u"surfaceContainer"_s);
    row(out, u"DecorationFocus"_s, colours, u"primary"_s);
    row(out, u"DecorationHover"_s, colours, u"primary"_s);
    foregrounds(out, colours, u"onSurfaceVariant"_s, u"inverseSurface"_s);

    section(out, u"Colors:Selection"_s);
    row(out, u"BackgroundAlternate"_s, colours, u"primary"_s);
    row(out, u"BackgroundNormal"_s, colours, u"primary"_s);
    row(out, u"DecorationFocus"_s, colours, u"primary"_s);
    row(out, u"DecorationHover"_s, colours, u"secondary"_s);
    foregrounds(out, colours, u"onPrimary"_s, u"onPrimary"_s, u"klinkSelection"_s, u"kvisitedSelection"_s);

    section(out, u"Colors:Tooltip"_s);
    row(out, u"BackgroundAlternate"_s, colours, u"surfaceVariant"_s);
    row(out, u"BackgroundNormal"_s, colours, u"surfaceContainer"_s);
    row(out, u"DecorationFocus"_s, colours, u"primary"_s);
    row(out, u"DecorationHover"_s, colours, u"primary"_s);
    foregrounds(out, colours, u"onSurface"_s);

    section(out, u"Colors:View"_s);
    row(out, u"BackgroundAlternate"_s, colours, u"surfaceContainer"_s);
    row(out, u"BackgroundNormal"_s, colours, u"surfaceDim"_s);
    row(out, u"DecorationFocus"_s, colours, u"primary"_s);
    row(out, u"DecorationHover"_s, colours, u"inversePrimary"_s);
    foregrounds(out, colours, u"onSurface"_s, u"inverseSurface"_s);

    section(out, u"Colors:Window"_s);
    row(out, u"BackgroundAlternate"_s, colours, u"surfaceVariant"_s);
    row(out, u"BackgroundNormal"_s, colours, u"surfaceContainer"_s);
    row(out, u"DecorationFocus"_s, colours, u"primary"_s);
    row(out, u"DecorationHover"_s, colours, u"primary"_s);
    foregrounds(out, colours, u"onSurfaceVariant"_s, u"klink"_s);

    section(out, u"General"_s);
    out << u"ColorScheme="_s + name << u"Name="_s + name << u"shadeSortColumn=true"_s;

    section(out, u"KDE"_s);
    out << u"contrast=4"_s;

    section(out, u"WM"_s);
    row(out, u"activeBackground"_s, colours, u"surfaceContainerHighest"_s);
    out << u"activeBlend=252,252,252"_s;
    row(out, u"activeForeground"_s, colours, u"onSurface"_s);
    row(out, u"inactiveBackground"_s, colours, u"secondaryContainer"_s);
    out << u"inactiveBlend=161,169,177"_s;
    row(out, u"inactiveForeground"_s, colours, u"onSecondaryContainer"_s);

    return (out.join(u'\n') + u'\n').toUtf8();
}

} // namespace aether::theme
