pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Aether.Config
import Aether.Plugins
import qs.components.controls
import qs.modules.nexus.common

// Rows generated from a plugin's SettingsObject: one per property, chosen by the SettingMeta the
// plugin attached to it. A plugin that ships its own settingsUi is loaded by the page instead of
// this -- this is the fallback for the common case of "a settings object, no bespoke UI".
ColumnLayout {
    id: root

    // SettingsObject instance from PluginManifest.settings
    required property var settings

    readonly property int count: settings ? settings.keys().length : 0

    spacing: Tokens.spacing.extraSmall / 2

    Repeater {
        model: root.settings ? root.settings.keys() : []

        Loader {
            id: rowLoader

            required property string modelData
            required property int index

            readonly property var meta: root.settings.metaFor(modelData)
            readonly property var value: root.settings[modelData]

            Layout.fillWidth: true
            sourceComponent: {
                switch (meta ? meta.inputType : SettingMeta.Default) {
                case SettingMeta.Switch:
                    return switchRow;
                case SettingMeta.Slider:
                    return sliderRow;
                case SettingMeta.SpinBox:
                    return stepperRow;
                case SettingMeta.SplitButton:
                case SettingMeta.BlobButton:
                    return selectRow;
                case SettingMeta.TextField:
                    return textRow;
                default:
                    // No metadata: pick by the property's type, which is what an author gets for
                    // free by declaring a plain property on the settings object.
                    if (typeof value === "boolean")
                        return switchRow;
                    if (typeof value === "number")
                        return stepperRow;
                    return textRow;
                }
            }

            onLoaded: {
                item.first = index === 0; // qmllint disable missing-property
                item.last = index === root.count - 1; // qmllint disable missing-property
                item.settingKey = modelData; // qmllint disable missing-property
                item.meta = root.settings.metaFor(modelData); // qmllint disable missing-property
                item.settings = root.settings; // qmllint disable missing-property
            }
        }
    }

    Component {
        id: itemComp

        MenuItem {}
    }

    Component {
        id: switchRow

        PluginSwitchRow {}
    }

    Component {
        id: stepperRow

        PluginStepperRow {}
    }

    Component {
        id: sliderRow

        PluginSliderRow {}
    }

    Component {
        id: selectRow

        PluginSelectRow {}
    }

    Component {
        id: textRow

        PluginTextRow {}
    }

    component PluginSwitchRow: ToggleRow {
        property string settingKey: ""
        property var meta: null
        property var settings: null

        text: meta?.label || settingKey
        subtext: meta?.description ?? ""
        enabled: !(meta?.disabled ?? false)
        checked: settings ? settings[settingKey] === true : false
        onToggled: settings[settingKey] = checked
    }

    component PluginStepperRow: StepperRow {
        property string settingKey: ""
        property var meta: null
        property var settings: null

        label: meta?.label || settingKey
        subtext: meta?.description ?? ""
        enabled: !(meta?.disabled ?? false)
        from: meta && meta.max > meta.min ? Math.ceil(meta.min) : 0
        to: meta && meta.max > meta.min ? Math.floor(meta.max) : 100
        stepSize: meta && meta.step > 0 ? Math.max(1, Math.round(meta.step)) : 1
        value: settings ? (settings[settingKey] ?? 0) : 0
        onMoved: v => settings[settingKey] = v
    }

    component PluginSliderRow: SliderRow {
        property string settingKey: ""
        property var meta: null
        property var settings: null

        readonly property real low: meta ? meta.min : 0
        readonly property real high: meta && meta.max > meta.min ? meta.max : 1

        label: meta?.label || settingKey
        enabled: !(meta?.disabled ?? false)
        value: settings && high > low ? ((settings[settingKey] ?? low) - low) / (high - low) : 0
        valueLabel: Number(settings ? (settings[settingKey] ?? 0) : 0).toFixed(meta && meta.step > 0 && meta.step < 1 ? 2 : 0)
        onMoved: v => settings[settingKey] = low + v * (high - low)
    }

    component PluginSelectRow: SelectRow {
        property string settingKey: ""
        property var meta: null
        property var settings: null

        readonly property var items: (meta?.options ?? []).map(option => itemComp.createObject(root, {
                "text": option
            }))

        label: meta?.label || settingKey
        subtext: meta?.description ?? ""
        disabled: meta?.disabled ?? false
        menuItems: items
        active: settings ? (items.find(i => i.text === settings[settingKey]) ?? null) : null
        onSelected: item => settings[settingKey] = item.text
    }

    component PluginTextRow: TextFieldRow {
        property string settingKey: ""
        property var meta: null
        property var settings: null

        label: meta?.label || settingKey
        subtext: meta?.description ?? ""
        enabled: !(meta?.disabled ?? false)
        value: settings ? (settings[settingKey] ?? "") : ""
        onValueEdited: value => settings[settingKey] = value
    }
}
