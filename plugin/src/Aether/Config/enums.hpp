#pragma once

#include <qobject.h>
#include <qqmlintegration.h>

namespace aether::shell::config {

#define ENUM(Name, ...)                                                                                                \
    namespace Name {                                                                                                   \
                                                                                                                       \
    Q_NAMESPACE                                                                                                        \
    QML_NAMED_ELEMENT(Name)                                                                                            \
                                                                                                                       \
    enum Enum : quint8 {                                                                                               \
        __VA_ARGS__                                                                                                    \
    };                                                                                                                 \
    Q_ENUM_NS(Enum)                                                                                                    \
                                                                                                                       \
    };

ENUM(BarWorkspaceDisplay, Shapes, Text, Icons)
ENUM(BarWorkspaceCapitalisation, Preserve, Upper, Lower)
ENUM(LyricsBackend, Auto, Local, LRCLIB, NetEase)
// Intel is appended rather than slotted next to Nvidia. Config serialises enums by name
// (EnumCodec), so position is free there -- but modules/nexus/pages/ServicesPage.qml keeps a
// MenuItem list indexed by ordinal, and appending keeps every existing index correct.
ENUM(GpuType, Auto, Nvidia, Generic, None, Intel)
ENUM(NotifsFullscreen, On, Off)
ENUM(TemperatureUnit, Auto, Celsius, Fahrenheit, Kelvin)
ENUM(DataUnit, Binary, Decimal)
ENUM(ClockFormat, Auto, TwelveHour, TwentyFourHour)
ENUM(WallpaperTransition,
    // clang-format off
    ChromaticBloom,
    ColourDistance,
    Crossfade,
    Crosshatch,
    Crosswarp,
    Directional,
    DirectionalWipe,
    FadeColour,
    Glitch,
    GlitchDisplace,
    HeatMelt,
    InkSplash,
    InkwellDrop,
    Iris,
    Morph,
    ParametricGlitch,
    Perlin,
    Pixelate,
    PixelfadeWave,
    PlasmaFlow,
    PolkaDotsCurtain,
    PuzzleRight,
    RandomSquares,
    Smoke,
    SoftWarpFade,
    VoronoiShatter,
    ZoomBlurPull,
    // clang-format on
)

// Which fork's implementation to use where both forks ship one (D3/D4).
ENUM(HybridVariant, Midnight, Op)

#undef ENUM

} // namespace aether::shell::config
