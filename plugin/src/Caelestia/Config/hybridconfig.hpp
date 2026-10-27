#pragma once

#include <qstring.h>

#include "settings/objectnode.hpp"
#include "common.hpp"
#include "enums.hpp"

namespace caelestia::shell::config {

using Qt::StringLiterals::operator""_s;

// A feature or variant with no user value takes the selected preset's (D8). The settings
// schema moved to static defaults, so the preset lookup is applied through reresolve()
// when the preset changes or a layer loads, rather than through a callable default.
#define FEATURE(name) CONFIG_GLOBAL_PROPERTY(bool, name, false)
#define VARIANT(name)                                                                                                  \
    CONFIG_GLOBAL_PROPERTY(caelestia::shell::config::HybridVariant::Enum, name, HybridVariant::Midnight)

// One boolean per feature. This is the workhorse of the hybrid design (D3): the two forks
// are ~90% disjoint, so nearly everything they add is a feature that is either present or
// absent, not a choice between two implementations.
//
// A flag exists here only once something reads it. Four were removed for failing that:
//
//   gpuDetection  upstream ships it unconditionally (Services/gpu.cpp, the GpuType enum).
//                 A toggle for it would be a lie. OP's contribution is enhanced monitoring,
//                 which is a service merge (D5), not a feature.
//   patternLock   never ships as a toggle. It is a lock-screen bypass (D10, trap T3), and
//                 a switch offering to enable it is exactly the wrong artefact. Recorded
//                 in the traps, not in the user's settings schema.
//
// Each flag's *default* is the selected preset's value, resolved through reresolve() (D8).
// A user who has never touched a flag follows the preset; one who has
// keeps their own value, because an override is never re-resolved.
//
// Everything here is global: a feature flag per monitor is meaningless.
class HybridFeatures : public settings::ObjectNode {
    CONFIG_NODE(HybridFeatures, settings::ObjectNode)

    FEATURE(dock)
    FEATURE(overview)
    FEATURE(clipboard)
    FEATURE(emojiPicker)
    FEATURE(windowSwitcher)
    FEATURE(keybindViewer)
    FEATURE(videoWallpaper)
    FEATURE(wallhaven)
    FEATURE(floatingLyrics)
    FEATURE(shimeji)
    FEATURE(badApple)
    FEATURE(dino)
    FEATURE(hotspot)
    FEATURE(btAgent)
    FEATURE(themeManager)
    FEATURE(lockPowerConfirm)
};

// The four components both forks genuinely implement. Capped at ~6 entries (D4): growth
// past that means the design is drifting back toward the implementation registry that was
// deliberately rejected.
class HybridVariants : public settings::ObjectNode {
    CONFIG_NODE(HybridVariants, settings::ObjectNode)

    VARIANT(lockCentre)
    VARIANT(audioPopout)

    // Added in Phase 7. The component audit originally recorded four dual sites; Overview is a
    // fifth -- MiDnight ships modules/drawers/WorkspaceOverview.qml and OP ships
    // modules/overview/, two designs of the same thing (T44).
    VARIANT(overview)

    // The sixth entry, which is exactly D4's stated cap. MiDnight's dock is a bar section
    // (bar.dock), OP's a separate auto-hiding panel (dock.*). Same purpose, different objects,
    // and wanting both at once is redundant UI -- which is what makes it a variant.
    VARIANT(dock)
};

class HybridConfig : public settings::ObjectNode {
    CONFIG_NODE_NO_CTOR(HybridConfig, settings::ObjectNode)
    QML_ANONYMOUS

    // The preset *name* is stored, never its expanded values (D8), so "recommended" can be
    // improved later and existing users receive the improvement. There is no `Custom`
    // enumerator: custom is the computed state when any flag differs from the preset, which
    // QML derives rather than stores.
    CONFIG_GLOBAL_ENUM_PROPERTY(HybridPreset, preset, HybridPreset::Recommended)
    CONFIG_GLOBAL_SUBOBJECT(HybridFeatures, features)
    CONFIG_GLOBAL_SUBOBJECT(HybridVariants, variants)

public:
    // Applies the selected preset's values to the flags and variants the user has not set (D8).
    void reresolve();

    explicit HybridConfig(HybridConfig* fallback = nullptr, QObject* parent = nullptr, bool globalOnly = false);
};

#undef FEATURE
#undef VARIANT

} // namespace caelestia::shell::config
