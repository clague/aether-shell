# Plugins

The shell can load QML plugins from disk: a plugin adds bar entries, popouts, quick toggles,
status icons and dashboard tabs, and can ship its own settings. This is the contract the loader
in `plugin/src/Aether/Plugins/` implements; read it for anything this page does not spell out.

## Where a plugin lives

A plugin is one directory with a `manifest.json` in it. The loader scans, in order:

1. `~/.local/share/aether/plugins/<dir>/`
2. `~/.config/aether/plugins/<dir>/`
3. every directory in `$CAELESTIA_PLUGIN_PATH` (colon separated)

The directory name does not matter; the id comes from the manifest. Which plugins are enabled,
and every plugin's saved settings, live in `~/.config/aether/plugins.json`.

Enabling a plugin registers its QML module and seals its directory (a plugin resolves its own
files by name and cannot reach into another plugin's). A change on disk is picked up by the file
watcher, and **Plugins > Rescan** reloads manifests and entry points without restarting.

## manifest.json

```json
{
  "name": "Weather Clock",
  "author": "you",
  "version": "1.0.0",
  "icon": "schedule",
  "description": "Clock with the forecast next to it",
  "requires": ">=2.6.0",
  "settings": "Settings.qml",
  "settingsUi": "SettingsUi.qml",
  "entryPoints": [
    { "type": "bar-entry", "source": "BarEntry.qml", "properties": { "name": "weatherClock" } },
    { "type": "quick-toggle", "source": "Toggle.qml", "properties": { "name": "weatherClock" } }
  ]
}
```

| field | meaning |
|---|---|
| `name`, `author` | Required. Both become the id (`author/name`, lowercased) and the QML module URI, so they may only contain letters, digits and `_`, and may not start with a digit. |
| `version` | Free string, shown in the settings page. |
| `icon`, `description` | Shown in the settings page. |
| `requires` | Version requirement against the shell, e.g. `>=2.6.0`, `<3`. Omitted means any. |
| `settings` | A QML file whose root is a `SettingsObject` (see below). |
| `settingsUi` | A QML file with your own settings UI; wins over the generated rows. |
| `entryPoints` | What the plugin contributes, see below. |

## Entry points

| `type` | consumed by | `properties.name` |
|---|---|---|
| `bar-entry` | a bar entry whose id matches | the entry id used in the bar config |
| `bar-popout` | the popout opened by that entry | the popout name the bar sets |
| `quick-toggle` | a quick toggle whose id matches | the toggle id used in the quick-toggles config |
| `status-icon` | the bar's status icons | the status icon id |
| `dashboard-tab` | the dashboard tab list | the tab id |
| `custom` | nothing yet; reserved | — |

`source` is a QML file relative to the plugin directory. The component is loaded as-is, so it is
your QML under the shell's imports. A quick toggle additionally honours `fillWidth`,
`shapeMorph` and `shapeMorphExpansion` properties on the loaded item.

To use one, name its id in the corresponding config: add `{"id": "weatherClock"}` to
`bar.entries`, or `"weatherClock"` to `utilities.quickToggles`. Entries whose id no built-in
component claims are looked up among the installed plugins.

## Settings

`settings: "Settings.qml"` loads a `SettingsObject`: declare a property per option and attach
`SettingMeta` as a value source.

```qml
import QtQuick
import Aether.Plugins

SettingsObject {
    property bool notify: true
    property int refresh: 30
    property string label: "weather"

    SettingMeta on notify {
        label: "Notifications"
        description: "Show a toast when the forecast changes"
        inputType: SettingMeta.Switch
    }

    SettingMeta on refresh {
        label: "Refresh interval"
        description: "Minutes between fetches"
        inputType: SettingMeta.SpinBox
        min: 5
        max: 120
        step: 5
    }

    SettingMeta on label {
        label: "Label"
        inputType: SettingMeta.TextField
    }
}
```

`inputType` picks the settings row: `Switch`, `SpinBox`, `Slider`, `TextField`, `SplitButton` or
`BlobButton` (the last two use `options` / `optionIcons`). With no `SettingMeta` the row is chosen
from the property's type (`bool` → switch, number → stepper, otherwise a text field). Metadata
also carries `icon` and `disabled`.

Values are read back with the property itself (`settings.refresh`) and are persisted with the
plugin by the shell; `SettingsObject::toMap()`/`load()` do that for you.

If the generated rows are not enough, ship `settingsUi` instead: a QML file loaded inside the
plugin's card on the Plugins page, free to use the same `SettingsObject` (and anything else).
