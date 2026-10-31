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

        InfoRow {
            first: true
            last: true
            Layout.fillWidth: true
            icon: "info"
            label: Tr.tr("Stored in hypr-vars.lua")
            subtext: Tr.tr("Hyprland reads this file at startup; clear a row to remove its override.")
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
