pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Aether.Config
import Aether.I18n
import qs.components
import qs.components.controls
import qs.components.filedialog
import qs.services
import qs.modules.nexus.common

// Everything about how the shell and windows look and feel, in one place. Each section is
// opt-in: the defaults keep the original look, and every change can be undone here.
PageBase {
    id: root

    title: Tr.tr("Look & feel")

    ColumnLayout {
        anchors.horizontalCenter: parent?.horizontalCenter
        anchors.top: parent?.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            text: Tr.tr("Shell appearance")
        }

        ToggleRow {
            first: true
            Layout.fillWidth: true
            text: Tr.tr("Bezel mode (Pitch black)")
            subtext: Tr.tr("Make the shell pitch black to blend with display bezels")
            checked: GlobalConfig.appearance.pitchBlack
            onToggled: GlobalConfig.appearance.pitchBlack = checked
        }

        ToggleRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            text: Tr.tr("Islands")
            subtext: Tr.tr("Everything appears as its own floating widget (Very Experimental)")
            checked: GlobalConfig.appearance.islands
            onToggled: GlobalConfig.appearance.islands = checked
        }

        ToggleRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            text: Tr.tr("Transparency")
            checked: Colours.transparency.enabled
            onToggled: GlobalConfig.appearance.transparency.enabled = checked
        }

        SliderRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: Tr.tr("Base transparency level")
            value: Colours.transparency.base
            valueLabel: Math.round(value * 100) + "%"
            onMoved: v => GlobalConfig.appearance.transparency.base = v
            enabled: Colours.transparency.enabled
        }

        SliderRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: Tr.tr("Layer transparency level")
            value: Colours.transparency.layers
            valueLabel: Math.round(value * 100) + "%"
            onMoved: v => GlobalConfig.appearance.transparency.layers = v
            enabled: Colours.transparency.enabled
        }

        ToggleRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            last: true
            text: Tr.tr("Dark theme")
            checked: !Colours.light
            onToggled: Colours.setMode(checked ? "dark" : "light")
        }

        SectionHeader {
            text: Tr.tr("App fonts")
        }

        ToggleRow {
            id: fontsRow

            first: true
            text: Tr.tr("Use these fonts in apps")
            subtext: AppFonts.message || (AppFonts.enabled ? Tr.tr("Apps pick this up the next time they start") : Tr.tr("Apps currently use %1 and %2 by default").arg(AppFonts.nowSans).arg(AppFonts.nowMono))
            enabled: AppFonts.sansChoices.length > 0 && AppFonts.monoChoices.length > 0
            onToggled: AppFonts.turn(fontsRow.checked)

            Binding {
                target: fontsRow
                property: "checked"
                value: AppFonts.enabled
            }
        }

        SelectRow {
            id: sansRow

            label: Tr.tr("Sans-serif font")
            subtext: Tr.tr("Text in browsers, Qt and most other apps")
            disabled: !AppFonts.enabled || AppFonts.busy
            fallbackText: AppFonts.sans
            menuItems: sansItems.instances
            onSelected: item => AppFonts.choose(item.value, AppFonts.mono)

            Binding {
                target: sansRow
                property: "active"
                value: sansItems.instances.find(i => i.value === AppFonts.sans) ?? null
            }

            Variants {
                id: sansItems

                model: AppFonts.sansChoices

                MenuItem {
                    required property string modelData

                    text: modelData
                    value: modelData
                }
            }
        }

        SelectRow {
            id: monoRow

            label: Tr.tr("Monospace font")
            subtext: Tr.tr("Code and terminal-style text")
            disabled: !AppFonts.enabled || AppFonts.busy
            fallbackText: AppFonts.mono
            menuItems: monoItems.instances
            onSelected: item => AppFonts.choose(AppFonts.sans, item.value)

            Binding {
                target: monoRow
                property: "active"
                value: monoItems.instances.find(i => i.value === AppFonts.mono) ?? null
            }

            Variants {
                id: monoItems

                model: AppFonts.monoChoices

                MenuItem {
                    required property string modelData

                    text: modelData
                    value: modelData
                }
            }
        }

        StepperRow {
            id: textSizeRow

            label: Tr.tr("Text size")
            subtext: Tr.tr("Fonts are scaled to read like the default ones (×%1 for the sans font, ×%2 for the monospace font). Change this to taste, in %").arg(AppFonts.autoSans.toFixed(2)).arg(AppFonts.autoMono.toFixed(2))
            disabled: !AppFonts.enabled
            from: 70
            to: 160
            stepSize: 5
            onMoved: v => AppFonts.setSizeAdjust(v)

            Binding {
                target: textSizeRow
                property: "value"
                value: AppFonts.sizeAdjust
            }
        }

        RowButton {
            visible: AppFonts.needsRestart
            icon: "restart_alt"
            text: Tr.tr("Restart the shell to use your new font")
            subtext: Tr.tr("The shell only sees fonts that were installed when it started. Until then it shows another font")
            onClicked: AppFonts.restartShell()
        }

        ToggleRow {
            id: shellFontRow

            text: Tr.tr("Also use them in the shell")
            subtext: Tr.tr("The bar, panels and Nexus too. Icons keep their own font")
            disabled: !AppFonts.enabled
            onToggled: AppFonts.setShellToo(shellFontRow.checked)

            Binding {
                target: shellFontRow
                property: "checked"
                value: AppFonts.shellToo && AppFonts.enabled
            }
        }

        ConnectedRect {
            Layout.fillWidth: true
            implicitHeight: preview.implicitHeight + Tokens.padding.large * 2

            ColumnLayout {
                id: preview

                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                anchors.leftMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.extraSmall

                StyledText {
                    Layout.fillWidth: true
                    text: Tr.tr("The quick brown fox jumps over the lazy dog")
                    font: Qt.font({
                        family: AppFonts.sans,
                        pixelSize: 18
                    })
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: "0123456789  {}[]()  <= != =>  fn main() {}"
                    color: Colours.palette.m3onSurfaceVariant
                    font: Qt.font({
                        family: AppFonts.mono,
                        pixelSize: 14
                    })
                    elide: Text.ElideRight
                }
            }
        }

        RowButton {
            last: AppFonts.added.length === 0
            icon: "upload_file"
            text: AppFonts.busy ? Tr.tr("Working…") : Tr.tr("Add a font…")
            subtext: AppFonts.message || Tr.tr("Pick a .ttf, .otf or .ttc file. It is copied to your own fonts folder")
            disabled: AppFonts.busy
            onClicked: addFontDialog.open()

            FileDialog {
                id: addFontDialog

                title: Tr.tr("Choose a font file")
                filterLabel: Tr.tr("Font files")
                filters: ["ttf", "otf", "ttc"]
                onAccepted: path => AppFonts.addFont(path)
            }
        }

        Repeater {
            model: AppFonts.added

            RowButton {
                id: fontItem

                required property var modelData
                required property int index
                property bool armed

                last: index === AppFonts.added.length - 1
                icon: "font_download"
                text: modelData.family
                subtext: armed ? Tr.tr("Press again to remove %1").arg(modelData.file) : modelData.file
                trailingIcon: armed ? "delete_forever" : "delete"
                disabled: AppFonts.busy
                onClicked: {
                    if (!armed) {
                        armed = true;
                        return;
                    }
                    armed = false;
                    AppFonts.removeFont(modelData.file);
                }

                Timer {
                    running: fontItem.armed
                    interval: 4000
                    onTriggered: fontItem.armed = false
                }
            }
        }

        SectionHeader {
            text: Tr.tr("Hyprland")
        }

        NavRow {
            first: true
            last: true
            icon: "layers"
            text: Tr.tr("Hyprland settings")
            subtext: Tr.tr("Window effects, spacing and animations now live under Hyprland")
            onClicked: root.nState.openPageByKey("hyprland", 0)
        }
    }
}
