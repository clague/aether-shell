#pragma once

#include "settings/objectnode.hpp"
#include "common.hpp"
#include "enums.hpp"

namespace caelestia::shell::config {

// One boolean per feature that costs something when it is on: an extra window, a video
// decoder, a poll loop. Everything else is always available and has no flag.
//
// A flag is a plain setting now. There is no preset layer: the default below is what a fresh
// install gets, and the switch on the feature's own settings page is the only way to change it.
//
// Everything here is global: a feature flag per monitor is meaningless.
class HybridFeatures : public settings::ObjectNode {
    CONFIG_NODE(HybridFeatures, settings::ObjectNode)

    //   overview       separate drawer/overlay per screen
    //   videoWallpaper a video decoder per animated wallpaper
    //   badApple       one transparent fullscreen layer per screen
    //   hotspot        nmcli every 10s
    //   btAgent        a background pairing process
    CONFIG_GLOBAL_PROPERTY(bool, overview, true)
    CONFIG_GLOBAL_PROPERTY(bool, videoWallpaper, true)
    CONFIG_GLOBAL_PROPERTY(bool, badApple, false)
    CONFIG_GLOBAL_PROPERTY(bool, hotspot, true)
    CONFIG_GLOBAL_PROPERTY(bool, btAgent, true)
};

// The four components both forks genuinely implement. Capped at ~6 entries (D4): growth
// past that means the design is drifting back toward the implementation registry that was
// deliberately rejected.
class HybridVariants : public settings::ObjectNode {
    CONFIG_NODE(HybridVariants, settings::ObjectNode)

    // OP's popout is the one non-Midnight default. It was the old recommended preset's value.
    CONFIG_GLOBAL_ENUM_PROPERTY(HybridVariant, audioPopout, HybridVariant::Op)

    // Added in Phase 7. The component audit originally recorded four dual sites; Overview is a
    // fifth -- MiDnight ships modules/drawers/WorkspaceOverview.qml and OP ships
    // modules/overview/, two designs of the same thing (T44).
    CONFIG_GLOBAL_ENUM_PROPERTY(HybridVariant, overview, HybridVariant::Midnight)

    // The sixth entry, which is exactly D4's stated cap. MiDnight's dock is a bar section
    // (bar.dock), OP's a separate auto-hiding panel (dock.*). Same purpose, different objects,
    // and wanting both at once is redundant UI -- which is what makes it a variant.
    CONFIG_GLOBAL_ENUM_PROPERTY(HybridVariant, dock, HybridVariant::Midnight)
};

class HybridConfig : public settings::ObjectNode {
    CONFIG_NODE(HybridConfig, settings::ObjectNode)

    CONFIG_GLOBAL_SUBOBJECT(HybridFeatures, features)
    CONFIG_GLOBAL_SUBOBJECT(HybridVariants, variants)
};

} // namespace caelestia::shell::config
