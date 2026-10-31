pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Aether.Config
import qs.components
import qs.components.containers
import qs.services
import qs.modules.nexus

VerticalFadeFlickable {
    id: root

    required property NexusState nState

    // Keeps the keyboard-focused row visible while the arrows walk the list, the same way a
    // ListView scrolls its current item into view.
    readonly property Item focusedItem: root.Window.window ? root.Window.window.activeFocusItem : null

    function revealFocus(): void {
        const item = root.focusedItem;
        if (!item)
            return;

        let node = item;
        while (node && node !== root)
            node = node.parent;
        if (node !== root)
            return;

        const pos = item.mapToItem(root.contentItem, 0, 0);
        const pad = Tokens.padding.large;
        const minY = -root.topMargin;
        const maxY = Math.max(minY, root.contentHeight - root.height + root.bottomMargin);

        let y = root.contentY;
        if (pos.y < y + pad)
            y = pos.y - pad;
        else if (pos.y + item.height > y + root.height - pad)
            y = pos.y + item.height - root.height + pad;
        root.contentY = Math.max(minY, Math.min(maxY, y));
    }

    topMargin: Tokens.padding.large
    bottomMargin: Tokens.padding.large
    contentHeight: content.implicitHeight

    onFocusedItemChanged: Qt.callLater(root.revealFocus)

    TapHandler {
        onTapped: root.focus = true
    }

    ColumnLayout {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Tokens.spacing.extraSmall

        Repeater {
            id: list

            model: {
                const arr = [];
                for (let i = 0; i < PageRegistry.pages.length; i++) {
                    const page = PageRegistry.pages[i];
                    if (!page.developerOnly || GlobalConfig.general.developerMode) {
                        arr.push({
                            originalIndex: i,
                            label: page.label,
                            icon: page.icon,
                            description: page.description,
                            category: page.category,
                            developer: page.developerOnly ?? false,
                            noFill: page.noFill ?? false
                        });
                    }
                }
                return arr;
            }

            StyledRect {
                id: item

                required property var modelData
                required property int index

                readonly property bool isCurrentPage: modelData.originalIndex === root.nState.currentPageIdx

                // The developer-only page grows in when it is unlocked, and the row above it
                // rounds off; both used to be found by a hardcoded index.
                readonly property bool isDeveloperPage: modelData.developer

                readonly property bool isBeforeDeveloperPage: index + 1 < list.model.length && list.model[index + 1].developer

                readonly property bool isCategoryStart: index === 0 || list.model[index - 1].category !== modelData.category

                readonly property bool isCategoryEnd: index === list.model.length - 1 || list.model[index + 1].category !== modelData.category

                property real animHeight: 1

                property real animSlide: 1

                property bool isUnlocking: false

                function activate(): void {
                    root.nState.currentPageIdx = item.modelData.originalIndex;
                }

                // Rows take part in the window's focus chain, so Tab and the arrow keys can reach
                // the page list without any special key handling here.
                activeFocusOnTab: true

                clip: true

                Component.onCompleted: {
                    if (item.isDeveloperPage && root.nState.justUnlockedDevMode) {
                        animHeight = 0;
                        animSlide = 0;
                        heightAnim.start();
                        slideAnim.start();
                        isUnlocking = true;
                        unlockTimer.start();
                    } else if (item.isBeforeDeveloperPage && root.nState.justUnlockedDevMode) {
                        isUnlocking = true;
                        unlockTimer.start();
                    }
                }

                Layout.fillWidth: true
                Layout.topMargin: (index !== 0 && isCategoryStart ? Tokens.spacing.medium : 0) * animHeight

                implicitHeight: {
                    const h = layout.implicitHeight + layout.anchors.margins * 2;
                    const targetH = h % 2 === 0 ? h : h + 1;
                    return targetH * animHeight;
                }

                opacity: item.isDeveloperPage ? animSlide : 1.0

                transform: Translate {
                    y: item.isDeveloperPage ? (1 - item.animSlide) * -40 : 0
                }

                color: isCurrentPage ? Colours.palette.m3secondaryContainer : Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)

                topLeftRadius: stateLayer.pressed ? Tokens.rounding.medium : isCurrentPage ? Tokens.rounding.extraLargeIncreased : (isUnlocking && isDeveloperPage) ? Tokens.rounding.extraLarge : isCategoryStart ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall

                topRightRadius: stateLayer.pressed ? Tokens.rounding.medium : isCurrentPage ? Tokens.rounding.extraLargeIncreased : (isUnlocking && isDeveloperPage) ? Tokens.rounding.extraLarge : isCategoryStart ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall

                bottomLeftRadius: stateLayer.pressed ? Tokens.rounding.medium : isCurrentPage ? Tokens.rounding.extraLargeIncreased : (isUnlocking && isBeforeDeveloperPage) ? Tokens.rounding.extraLarge : isCategoryEnd ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall

                bottomRightRadius: stateLayer.pressed ? Tokens.rounding.medium : isCurrentPage ? Tokens.rounding.extraLargeIncreased : (isUnlocking && isBeforeDeveloperPage) ? Tokens.rounding.extraLarge : isCategoryEnd ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall

                Keys.onSpacePressed: event => {
                    item.activate();
                    event.accepted = true;
                }

                Keys.onReturnPressed: event => {
                    item.activate();
                    event.accepted = true;
                }

                Keys.onEnterPressed: event => {
                    item.activate();
                    event.accepted = true;
                }

                Timer {
                    id: unlockTimer

                    interval: 20
                    onTriggered: item.isUnlocking = false
                }

                NumberAnimation {
                    id: heightAnim

                    target: item
                    property: "animHeight"
                    to: 1
                    duration: 320
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.1
                    onFinished: root.nState.justUnlockedDevMode = false
                }

                NumberAnimation {
                    id: slideAnim

                    target: item
                    property: "animSlide"
                    to: 1
                    duration: 320
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.2
                }

                RadiusBehavior on topLeftRadius {}
                RadiusBehavior on topRightRadius {}
                RadiusBehavior on bottomLeftRadius {}
                RadiusBehavior on bottomRightRadius {}

                StateLayer {
                    id: stateLayer

                    anchors.fill: parent
                    topLeftRadius: parent.topLeftRadius
                    topRightRadius: parent.topRightRadius
                    bottomLeftRadius: parent.bottomLeftRadius
                    bottomRightRadius: parent.bottomRightRadius

                    onClicked: {
                        item.forceActiveFocus(Qt.MouseFocusReason);
                        root.nState.currentPageIdx = item.modelData.originalIndex;
                    }
                }

                StyledRect {
                    anchors.fill: parent
                    z: 1

                    visible: item.activeFocus
                    color: "transparent"
                    border.width: 2
                    border.color: Colours.palette.m3primary

                    topLeftRadius: item.topLeftRadius
                    topRightRadius: item.topRightRadius
                    bottomLeftRadius: item.bottomLeftRadius
                    bottomRightRadius: item.bottomRightRadius
                }

                RowLayout {
                    id: layout

                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: Tokens.padding.large
                    spacing: Tokens.spacing.medium

                    opacity: item.isDeveloperPage ? item.animSlide : 1.0

                    StyledRect {
                        Layout.fillHeight: true
                        Layout.topMargin: -1
                        Layout.bottomMargin: -1
                        implicitWidth: height

                        radius: Tokens.rounding.full
                        color: item.isCurrentPage ? Colours.palette.m3primary : Colours.palette.m3secondaryContainer

                        MaterialIcon {
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: 1

                            text: item.modelData.icon
                            color: item.isCurrentPage ? Colours.palette.m3onPrimary : Colours.palette.m3onSecondaryContainer
                            fontStyle: Tokens.font.icon.builders.medium.weight(Font.Medium).build()
                            grade: 25
                            fill: item.modelData.noFill ? 0 : 1
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: item.modelData.label
                            font: Tokens.font.body.medium
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: item.modelData.description
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.label.small
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }

    component RadiusBehavior: Behavior {
        Anim {
            type: Anim.DefaultEffects
        }
    }
}
