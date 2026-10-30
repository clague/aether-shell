#include "hybridconfig.hpp"

#include <qhash.h>

#include "settings/common.hpp"

namespace caelestia::shell::config {

namespace {

// The presets, as data. This is the single source of truth for what a preset means --
// hybrid/presets/*.json only names one (the three hostile presets in there set flags
// explicitly on purpose, to exercise user overrides).
//
// `recommended` is also the default column: a fresh install with no config at all gets it.
struct Preset {
    QHash<QString, bool> features;
    QHash<QString, HybridVariant::Enum> variants;
};

const Preset& presetFor(HybridPreset::Enum which) {
    static const Preset k_recommended{ .features={
                                         { u"overview"_s, true },
                                         { u"videoWallpaper"_s, true },
                                         { u"badApple"_s, false },
                                         { u"hotspot"_s, true },
                                         { u"btAgent"_s, true },
                                     },

        .variants={ { u"lockCentre"_s, HybridVariant::Midnight }, { u"audioPopout"_s, HybridVariant::Op },
            { u"overview"_s, HybridVariant::Midnight }, { u"dock"_s, HybridVariant::Midnight }, }, };

    // MiDnight as it ships: everything it added, nothing OP added.
    static const Preset k_midnight{ .features={
                                      { u"overview"_s, false },
                                      { u"videoWallpaper"_s, true },
                                      { u"badApple"_s, true },
                                      { u"hotspot"_s, false },
                                      { u"btAgent"_s, false },
                                  },

        .variants={ { u"lockCentre"_s, HybridVariant::Midnight }, { u"audioPopout"_s, HybridVariant::Midnight },
            { u"overview"_s, HybridVariant::Midnight }, { u"dock"_s, HybridVariant::Midnight }, }, };

    // OP as it ships.
    static const Preset k_op{ .features={
                                { u"overview"_s, true },
                                { u"videoWallpaper"_s, false },
                                { u"badApple"_s, false },
                                { u"hotspot"_s, true },
                                { u"btAgent"_s, true },
                            },

        .variants={ { u"lockCentre"_s, HybridVariant::Op }, { u"audioPopout"_s, HybridVariant::Op },
            { u"overview"_s, HybridVariant::Op }, { u"dock"_s, HybridVariant::Op }, }, };

    switch (which) {
    case HybridPreset::Midnight:
        return k_midnight;
    case HybridPreset::Op:
        return k_op;
    case HybridPreset::Recommended:
    default:
        return k_recommended;
    }
}

// `self` is the features or variants node; its parent is the HybridConfig holding `preset`.
HybridPreset::Enum selectedPreset(const settings::Node* self) {
    const auto* const parent = self ? self->parentNode() : nullptr;
    if (!parent)
        return HybridPreset::Recommended;
    return static_cast<HybridPreset::Enum>(parent->value(u"preset"_s).toInt());
}

bool presetFeature(const settings::Node* self, const QString& key) {
    return presetFor(selectedPreset(self)).features.value(key, false);
}

HybridVariant::Enum presetVariant(const settings::Node* self, const QString& key) {
    return presetFor(selectedPreset(self)).variants.value(key, HybridVariant::Midnight);
}

} // namespace

// Re-resolve every key the user has *not* set. Deliberately not resetToDefaults(): that
// writes every key unconditionally, and under the ambient write origin (File while the
// config is loading) each write is recorded as an override -- so it would overwrite the
// user's explicit values with the preset's, which is the opposite of D8. Writing under
// WriteOrigin::Layer records nothing, which is exactly what a fallback layer should do.
void HybridConfig::reresolve() {
    const settings::WriteScope scope(m_features, settings::WriteOrigin::Layer);
    for (const auto& desc : m_features->schema().descriptors()) {
        if (desc.isNode || m_features->isOverride(desc.key))
            continue;
        m_features->setValue(desc.key, presetFeature(m_features, desc.key));
    }
    for (const auto& desc : m_variants->schema().descriptors()) {
        if (desc.isNode || m_variants->isOverride(desc.key))
            continue;
        // QVariant must carry the enum type: a bare enum converts to int and the settings
        // layer rejects it, which silently left every preset on the static Midnight default.
        m_variants->setValue(desc.key, QVariant::fromValue(presetVariant(m_variants, desc.key)));
    }
}

HybridConfig::HybridConfig(HybridConfig* fallback, QObject* parent, bool globalOnly)
    : settings::ObjectNode(fallback, parent, globalOnly) {
    // Every feature and variant default is a function of the preset, so changing the preset
    // has to re-resolve them. Anything the user set stays set (D8).
    connect(this, &HybridConfig::presetChanged, this, [this] {
        reresolve();
    });
}

} // namespace caelestia::shell::config
