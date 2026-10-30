pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Aether
import Aether.Config
import Aether.I18n
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("Variables")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("Keybind apps")
        }

        AppRow {
            first: true
            icon: "terminal"
            label: Tr.tr("Terminal")
            varKey: "terminal"
        }
        AppRow {
            icon: "public"
            label: Tr.tr("Browser")
            varKey: "browser"
        }
        AppRow {
            icon: "code"
            label: Tr.tr("Editor")
            varKey: "editor"
        }
        AppRow {
            icon: "folder"
            label: Tr.tr("File Explorer")
            varKey: "fileExplorer"
        }
        AppRow {
            last: true
            icon: "volume_up"
            label: Tr.tr("Audio Settings")
            varKey: "audioSettings"
        }

        SectionHeader {
            text: Tr.tr("Touchpad")
        }

        HyprBoolRow {
            first: true
            text: Tr.tr("Disable typing")
            varKey: "touchpadDisableTyping"
        }
        HyprFloatRow {
            label: Tr.tr("Scroll factor")
            varKey: "touchScrollFactor"
        }
        HyprIntRow {
            label: Tr.tr("Gesture fingers")
            varKey: "gestureFingers"
            from: 1
            to: 10
        }
        HyprIntRow {
            label: Tr.tr("Workspace swipe fingers")
            varKey: "workspaceSwipeFingers"
            from: 1
            to: 10
        }
        HyprIntRow {
            last: true
            label: Tr.tr("Gesture fingers more")
            varKey: "gestureFingersMore"
            from: 1
            to: 10
        }

        SectionHeader {
            text: Tr.tr("Misc")
        }

        HyprIntRow {
            first: true
            label: Tr.tr("Hyprland volume step")
            varKey: "volumeStep"
            from: 1
            to: 100
        }
        HyprStringRow {
            label: Tr.tr("Cursor theme")
            varKey: "cursorTheme"
        }
        HyprIntRow {
            label: Tr.tr("Cursor size")
            varKey: "cursorSize"
            from: 8
            to: 128
        }
        HyprStringRow {
            last: true
            label: Tr.tr("Sleep gesture command")
            varKey: "sleepGestureCmd"
        }

        Item {
            Layout.preferredHeight: Tokens.padding.large
            Layout.fillWidth: true
        }
    }

    component AppRow: PopupRow {
        id: aroot

        property string varKey
        readonly property int popupHeight: root.flickable.height - y + root.flickable.contentY - Tokens.padding.large - Tokens.padding.extraExtraLarge

        showDelete: HyprVars.vars[varKey] !== undefined
        onDeleted: HyprVars.deleteVar(varKey)

        keepPopupAsChild: {
            if (!aroot.popup.open && aroot.popup.animDriver === 0)
                return true;

            if (root.nState.animatingContainer || root.opacity < 1)
                return true;

            let p = root.parent;
            while (p && p.objectName !== "PageContainer")
                p = p.parent;
            return p ? (p.opacity < 1) : false;
        }

        popup.topMovement: Math.max(Tokens.sizes.nexus.minPopupHeight - popupHeight, Tokens.padding.large)

        status: HyprVars.vars[aroot.varKey] !== undefined ? String(HyprVars.vars[aroot.varKey]) : (HyprVars.defaults[aroot.varKey] !== undefined ? String(HyprVars.defaults[aroot.varKey]) : "")

        Loader {
            anchors.centerIn: parent
            active: aroot.popup.animDriver > 0

            sourceComponent: VerticalFadeListView {
                id: list

                implicitWidth: Tokens.sizes.nexus.popupWidth
                implicitHeight: CUtils.clamp(aroot.popupHeight, Tokens.sizes.nexus.minPopupHeight, Tokens.sizes.nexus.maxPopupHeight)

                model: {
                    const apps = [...DesktopEntries.applications.values];
                    const favourited = new Set(apps.filter(a => Strings.testRegexList(GlobalConfig.launcher.favouriteApps, a.id)));
                    return apps.sort((a, b) => (favourited.has(b) - favourited.has(a)) || a.name.localeCompare(b.name));
                }

                delegate: StateLayer {
                    id: appItem

                    required property DesktopEntry modelData
                    required property int index

                    anchors.fill: undefined
                    anchors.left: list.contentItem.left
                    anchors.right: list.contentItem.right
                    implicitHeight: itemLayout.implicitHeight + itemLayout.anchors.margins * 2
                    radius: Tokens.rounding.small

                    onClicked: {
                        aroot.popup.open = false;
                        HyprVars.saveVar(aroot.varKey, modelData.command);
                    }

                    RowLayout {
                        id: itemLayout

                        anchors.fill: parent
                        anchors.margins: Tokens.padding.medium
                        spacing: Tokens.spacing.medium

                        IconImage {
                            asynchronous: true
                            implicitSize: Math.round(Tokens.font.icon.large.pointSize * 1.8)
                            source: Quickshell.iconPath(appItem.modelData.icon, "image-missing")
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            StyledText {
                                Layout.fillWidth: true
                                text: appItem.modelData.name
                                font: Tokens.font.body.small
                                elide: Text.ElideRight
                            }

                            StyledText {
                                Layout.fillWidth: true
                                visible: text
                                text: (appItem.modelData.comment || appItem.modelData.genericName) ?? ""
                                color: Colours.palette.m3outline
                                font: Tokens.font.label.small
                                elide: Text.ElideRight
                            }
                        }

                        MaterialIcon {
                            visible: Strings.testRegexList(GlobalConfig.launcher.favouriteApps, appItem.modelData.id)
                            text: "favorite"
                            fill: 1
                            color: Colours.palette.m3primary
                            fontStyle: Tokens.font.icon.small
                        }
                    }
                }
            }
        }
    }
}
