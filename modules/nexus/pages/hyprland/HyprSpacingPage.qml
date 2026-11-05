pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Aether.Config
import Aether.I18n
import qs.components.controls
import qs.services
import qs.modules.nexus.common

// Hyprland window spacing and motion. The spacing preset and its three values are pushed to
// Hyprland live by Density; the workspace/single-window gaps are the persisted hypr-vars.lua
// values. Motion changes the animation speed Hyprland and the shell share.
PageBase {
    id: root

    title: Tr.tr("Spacing & animations")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("Layout")
        }

        SelectRow {
            id: layoutRow

            first: true
            label: Tr.tr("Window layout")
            subtext: Tr.tr("Dwindle, master or scrolling")
            fallbackText: HyprVars.vars.layout ?? HyprVars.defaults.layout ?? "dwindle"
            menuItems: layoutItems.instances
            onSelected: item => HyprVars.saveVar("layout", item.value)

            Binding {
                target: layoutRow
                property: "active"
                value: layoutItems.instances.find(i => i.value === (HyprVars.vars.layout ?? HyprVars.defaults.layout)) ?? null
            }

            Variants {
                id: layoutItems

                model: [
                    {
                        id: "dwindle",
                        name: Tr.tr("Dwindle")
                    },
                    {
                        id: "master",
                        name: Tr.tr("Master")
                    },
                    {
                        id: "scrolling",
                        name: Tr.tr("Scrolling")
                    }
                ]

                MenuItem {
                    required property var modelData

                    text: modelData.name
                    value: modelData.id
                }
            }
        }

        SectionHeader {
            text: Tr.tr("Gaps & borders")
        }

        SelectRow {
            id: presetRow

            first: true
            label: Tr.tr("Window spacing")
            subtext: Tr.tr("Gaps between windows and the border around them")
            fallbackText: Tr.tr("Custom")
            menuItems: presetItems.instances
            onSelected: item => Density.setPreset(item.value)

            // Picking an item replaces a plain `active:` binding, so re-assert the real value
            Binding {
                target: presetRow
                property: "active"
                value: presetItems.instances.find(i => i.value === Density.preset) ?? null
            }

            Variants {
                id: presetItems

                model: [
                    {
                        id: "comfortable",
                        name: Tr.tr("Comfortable")
                    },
                    {
                        id: "compact",
                        name: Tr.tr("Compact")
                    },
                    {
                        id: "dense",
                        name: Tr.tr("Dense")
                    }
                ]

                MenuItem {
                    required property var modelData

                    text: modelData.name
                    value: modelData.id
                }
            }
        }

        StepperRow {
            id: inRow

            label: Tr.tr("Gap between windows")
            from: 0
            to: 30
            onMoved: v => Density.setValue("gapsIn", v)

            Binding {
                target: inRow
                property: "value"
                value: Density.gapsIn
            }
        }

        StepperRow {
            id: outRow

            label: Tr.tr("Gap around the screen")
            from: 0
            to: 40
            onMoved: v => Density.setValue("gapsOut", v)

            Binding {
                target: outRow
                property: "value"
                value: Density.gapsOut
            }
        }

        StepperRow {
            id: borderRow

            last: true
            label: Tr.tr("Window border")
            from: 0
            to: 8
            onMoved: v => Density.setValue("border", v)

            Binding {
                target: borderRow
                property: "value"
                value: Density.border
            }
        }

        HyprIntRow {
            first: true
            label: Tr.tr("Workspace gaps")
            varKey: "workspaceGaps"
            from: 0
            to: 100
        }

        HyprIntRow {
            last: true
            label: Tr.tr("Single window gaps")
            varKey: "singleWindowGapsOut"
            from: 0
            to: 100
        }

        SectionHeader {
            text: Tr.tr("Window behaviour")
        }

        HyprBoolRow {
            first: true
            text: Tr.tr("Allow tearing")
            subtext: Tr.tr("Lets immediate window rules work for fullscreen games")
            varKey: "allowTearing"
        }

        HyprBoolRow {
            text: Tr.tr("Resize windows on the border")
            varKey: "resizeOnBorder"
        }
        HyprBoolRow {
            text: Tr.tr("Focus window on close")
            varKey: "focusOnClose"
        }
        HyprIntRow {
            label: Tr.tr("Focus under fullscreen")
            subtext: Tr.tr("0 off, 1 fullscreen only, 2 always")
            varKey: "onFocusUnderFullscreen"
            from: 0
            to: 2
        }
        HyprBoolRow {
            last: true
            text: Tr.tr("Allow restoring the session lock")
            varKey: "allowSessionLockRestore"
        }

        SectionHeader {
            text: Tr.tr("Dwindle layout")
        }

        HyprBoolRow {
            first: true
            text: Tr.tr("Preserve split")
            varKey: "preserveSplit"
        }

        HyprBoolRow {
            text: Tr.tr("Smart split")
            varKey: "smartSplit"
        }

        HyprBoolRow {
            last: true
            text: Tr.tr("Smart resizing")
            varKey: "smartResizing"
        }

        SectionHeader {
            text: Tr.tr("Scrolling layout")
        }

        HyprBoolRow {
            first: true
            text: Tr.tr("Fullscreen on one column")
            varKey: "scrollingFullscreenOnOneColumn"
        }
        HyprIntRow {
            label: Tr.tr("Focus fit method")
            varKey: "scrollingFocusFitMethod"
            from: 0
            to: 3
        }
        HyprSliderRow {
            label: Tr.tr("Column width")
            varKey: "scrollingColumnWidth"
            from: 0.1
            to: 1
            step: 0.05
        }
        HyprBoolRow {
            text: Tr.tr("Follow focus")
            varKey: "scrollingFollowFocus"
        }
        HyprSliderRow {
            label: Tr.tr("Minimum visible")
            varKey: "scrollingFollowMinVisible"
            from: 0
            to: 1
            step: 0.05
        }
        HyprStringRow {
            last: true
            label: Tr.tr("Explicit column widths")
            subtext: Tr.tr("Comma-separated widths, for example 0.35, 0.5, 0.65, 1.0")
            varKey: "scrollingExplicitColumnWidths"
        }

        SectionHeader {
            text: Tr.tr("Motion")
        }

        SelectRow {
            id: speedRow

            first: true
            label: Tr.tr("Animation speed")
            subtext: Tr.tr("How fast the shell and your windows animate, together")
            fallbackText: `${Motion.speed.toFixed(2)}×`
            menuItems: speedItems.instances
            onSelected: item => Motion.setSpeed(item.value)

            // Picking an item replaces a plain `active:` binding, so re-assert the real value
            Binding {
                target: speedRow
                property: "active"
                value: speedItems.instances.find(i => Math.abs(i.value - Motion.speed) < 0.001) ?? null
            }

            Variants {
                id: speedItems

                model: [
                    {
                        name: Tr.tr("Calm"),
                        factor: 1.3
                    },
                    {
                        name: Tr.tr("Standard"),
                        factor: 1
                    },
                    {
                        name: Tr.tr("Snappy"),
                        factor: 0.75
                    },
                    {
                        name: Tr.tr("Quick"),
                        factor: 0.5
                    }
                ]

                MenuItem {
                    required property var modelData

                    text: modelData.name
                    value: modelData.factor
                }
            }
        }

        ToggleRow {
            id: matchRow

            text: Tr.tr("Windows move like the shell")
            subtext: Tr.tr("Windows, workspaces and panels share one set of curves and timings")
            onToggled: Motion.setMatchShell(matchRow.checked)

            Binding {
                target: matchRow
                property: "checked"
                value: Motion.matchShell
            }
        }

        RowButton {
            last: true
            icon: "restart_alt"
            text: Tr.tr("Reset motion to defaults")
            subtext: Tr.tr("Back to the timings from your config")
            disabled: Motion.isDefault
            onClicked: Motion.resetAll()
        }

        Item {
            Layout.preferredHeight: Tokens.padding.large
            Layout.fillWidth: true
        }
    }
}
