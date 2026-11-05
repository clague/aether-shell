pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Aether
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

    // What Qt applications draw their controls with. "auto" is the first entry and means the
    // platform theme decides (Kvantum when configured, then the style the CLI asks for, then
    // Fusion); the rest is whatever Qt can create on this machine. A style named in the config
    // but missing here keeps its value -- it is skipped at runtime instead of being rewritten.
    readonly property var qtStyleValues: ["auto"].concat(CUtils.availableQtStyles())
    readonly property var qtStyleItems: qtStyleValues.map(name => qtStyleItem.createObject(root, {
            "text": name === "auto" ? Tr.tr("Automatic") : name
        }))

    title: Tr.tr("Look & feel")

    ColumnLayout {
        anchors.horizontalCenter: parent?.horizontalCenter
        anchors.top: parent?.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        Component {
            id: qtStyleItem

            MenuItem {}
        }

        SectionHeader {
            text: Tr.tr("Qt applications")
        }

        SelectRow {
            first: true
            last: true
            Layout.fillWidth: true
            label: Tr.tr("Widget style")
            subtext: Tr.tr("How Qt apps draw their controls; takes effect when they restart")
            configNode: GlobalConfig.appearance
            propertyName: "qtStyle"
            menuItems: root.qtStyleItems
            active: root.qtStyleItems[Math.max(0, root.qtStyleValues.indexOf(GlobalConfig.appearance.qtStyle))] ?? null
            onSelected: item => {
                const idx = root.qtStyleItems.indexOf(item);
                if (idx !== -1)
                    GlobalConfig.appearance.qtStyle = root.qtStyleValues[idx];
            }
        }

        SectionHeader {
            text: Tr.tr("Colours")
        }

        // Colours keep living next to the wallpaper that seeds them; this is the link the other
        // half of the category needs, so nobody has to guess which page owns the scheme.
        NavRow {
            first: true
            last: true
            icon: "palette"
            text: Tr.tr("Colour scheme")
            subtext: Tr.tr("Dynamic or static colours, and the mode")
            onClicked: root.nState.openPageByKey("wallpaper", 3)
        }

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

        // Written by scripts/app-fonts.py, which Nexus cannot show in a row: the switch below
        // edits files outside the shell, so say so before the user turns it on. A wrapping card
        // rather than an InfoRow, whose subtext is elided to one line and would cut the paths off.
        ConnectedRect {
            Layout.fillWidth: true
            first: true
            implicitHeight: notice.implicitHeight + Tokens.padding.largeIncreased * 2

            RowLayout {
                id: notice

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                MaterialIcon {
                    Layout.alignment: Qt.AlignTop
                    text: "info"
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.medium
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.extraSmall

                    StyledText {
                        Layout.fillWidth: true
                        text: Tr.tr("This changes your system font settings")
                        font: Tokens.font.body.medium
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: Tr.tr("It writes %1 and sets the GTK font, so every application uses these fonts, not only the shell. Fonts you add are copied to %2. Turning it off removes the file and puts the previous GTK fonts back.").arg("~/.config/fontconfig/conf.d/60-caelestia-app-fonts.conf").arg("~/.local/share/fonts/caelestia")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.small
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }

        ToggleRow {
            id: fontsRow

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

        FontSelectRow {
            rootParent: root.flickable
            first: true
            last: false
            labelPrefix: Tr.tr("Sans-serif font")
            dialogTitle: Tr.tr("Choose a sans-serif font")
            current: AppFonts.sans
            families: AppFonts.sansChoices
            disabled: !AppFonts.enabled || AppFonts.busy
            onFontChosen: family => AppFonts.choose(family, AppFonts.mono)
        }

        FontSelectRow {
            rootParent: root.flickable
            first: false
            last: false
            labelPrefix: Tr.tr("Monospace font")
            dialogTitle: Tr.tr("Choose a monospace font")
            current: AppFonts.mono
            families: AppFonts.monoChoices
            disabled: !AppFonts.enabled || AppFonts.busy
            onFontChosen: family => AppFonts.choose(AppFonts.sans, family)
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
