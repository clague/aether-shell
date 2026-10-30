pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services

MouseArea {
    id: root

    enum Side {
        Top,
        Bottom,
        Left,
        Right
    }

    required property Item attachTo

    property int attachSideX: Menu.Right

    property int attachSideY: Menu.Bottom

    property int thisSideX: Menu.Right

    property int thisSideY: Menu.Top

    property real marginX

    property real marginY

    property list<MenuItem> items

    property MenuItem active: items[0] ?? null

    property bool expanded

    // Room around the attach point, to cap the height and decide whether the menu opens up.
    // Measured when the menu opens and when the anchor moves, never bound: the geometry it
    // reads is not reactive and a binding here loops with the menu's own position (OP's
    // 0ff57acc fixes exactly that in the source).
    property real spaceBelow: 0

    property real spaceAbove: 0

    readonly property real naturalHeight: column.implicitHeight + Tokens.padding.extraSmall * 2

    // Opens upward when it would not fit below and there is more room above
    readonly property bool flipUp: thisSideY === Menu.Top && attachSideY === Menu.Bottom && spaceBelow < Math.min(naturalHeight, 260) && spaceAbove > spaceBelow

    readonly property real maxMenuHeight: {
        const room = (flipUp || thisSideY === Menu.Bottom) ? spaceAbove : spaceBelow;
        return Math.max(120, Math.min(340, room));
    }

    signal itemSelected(item: MenuItem)

    function measure(): void {
        if (!parent || !attachTo)
            return;
        const top = attachTo.mapToItem(parent, 0, 0).y;
        spaceAbove = top - Tokens.padding.large;
        spaceBelow = parent.height - (top + attachTo.height) - Tokens.padding.large;
    }

    function revealActive(): void {
        const it = repeater.itemAt(items.indexOf(active));
        if (!it)
            return;
        flickable.contentY = Math.max(0, Math.min(flickable.contentHeight - flickable.height, it.y - (flickable.height - it.height) / 2));
    }

    parent: {
        let node = root.attachTo;
        let interactionsNode = null;

        while (node && node.parent) {
            if (node.utilitiesShortcutActive !== undefined) { // qmllint disable missing-property
                interactionsNode = node;
            }
            node = node.parent;
        }

        if (interactionsNode) {
            return interactionsNode;
        }

        return node || root.parent;
    }

    onExpandedChanged: {
        if (expanded) {
            measure();
            Qt.callLater(revealActive);
        }
    }

    anchors.fill: parent

    enabled: expanded

    hoverEnabled: expanded

    cursorShape: expanded ? Qt.ArrowCursor : undefined

    onClicked: expanded = false

    opacity: expanded ? 1 : 0

    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }

    TransformWatcher {
        id: watcher

        a: root.parent

        b: root.attachTo
    }

    Connections {
        function onTransformChanged(): void {
            root.measure();
        }

        target: watcher
    }

    Elevation {
        id: menu

        x: {
            CUtils.dependency(watcher.transform); // mapToItem is not reactive so this forces updates
            const item = root.attachTo;
            let off = root.attachSideX === Menu.Left ? 0 : item.width;
            if (root.thisSideX === Menu.Right)
                off -= width;
            return item.mapToItem(root.parent, off, 0).x + root.marginX;
        }

        y: {
            CUtils.dependency(watcher.transform); // mapToItem is not reactive so this forces updates
            const item = root.attachTo;
            let off = root.attachSideY === Menu.Top ? 0 : item.height;
            if (root.thisSideY === Menu.Bottom || root.flipUp) {
                off = root.flipUp ? 0 : off;
                off -= height;
            }
            return item.mapToItem(root.parent, 0, off).y + root.marginY;
        }

        radius: Tokens.rounding.large

        level: 2

        implicitWidth: Math.max(200, column.implicitWidth + Tokens.padding.extraSmall * 2)

        implicitHeight: Math.min(root.naturalHeight, root.maxMenuHeight)

        transform: Scale {
            yScale: root.expanded ? 1 : 0.1

            origin.y: (root.thisSideY === Menu.Bottom || root.flipUp) ? menu.height : 0

            Behavior on yScale {
                Anim {}
            }
        }

        MouseArea {
            anchors.fill: parent

            hoverEnabled: true

            onWheel: e => e.accepted = true
        }

        StyledRect {
            anchors.fill: parent

            radius: parent.radius

            color: Colours.palette.m3surfaceContainerLow

            Flickable {
                id: flickable

                anchors.fill: parent

                anchors.margins: Tokens.padding.extraSmall

                contentWidth: width

                contentHeight: column.implicitHeight

                clip: true

                interactive: contentHeight > height

                ScrollBar.vertical: StyledScrollBar {
                    flickable: flickable
                }

                ColumnLayout {
                    id: column

                    width: parent.width

                    spacing: 0

                    Repeater {
                        id: repeater

                        model: root.items

                        StyledRect {
                            id: item

                            required property int index

                            required property MenuItem modelData

                            readonly property bool active: modelData === root?.active

                            Layout.fillWidth: true

                            implicitWidth: menuOptionRow.implicitWidth + Tokens.padding.medium * 2

                            implicitHeight: menuOptionRow.implicitHeight + Tokens.padding.medium * 2

                            radius: active ? Tokens.rounding.medium : Tokens.rounding.extraSmall

                            topLeftRadius: index === 0 ? Tokens.rounding.medium : radius

                            topRightRadius: index === 0 ? Tokens.rounding.medium : radius

                            bottomLeftRadius: index === repeater?.count - 1 ? Tokens.rounding.medium : radius

                            bottomRightRadius: index === repeater?.count - 1 ? Tokens.rounding.medium : radius

                            color: Qt.alpha(Colours.palette.m3tertiaryContainer, active ? 1 : 0)

                            Behavior on radius {
                                Anim {}
                            }

                            StateLayer {
                                topLeftRadius: parent.topLeftRadius

                                topRightRadius: parent.topRightRadius

                                bottomLeftRadius: parent.bottomLeftRadius

                                bottomRightRadius: parent.bottomRightRadius

                                color: item.active ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurface

                                disabled: !root.expanded

                                onClicked: {
                                    root.itemSelected(item.modelData);
                                    root.active = item.modelData;
                                    item.modelData.clicked();
                                    root.expanded = false;
                                }
                            }

                            RowLayout {
                                id: menuOptionRow

                                anchors.fill: parent

                                anchors.margins: Tokens.padding.medium

                                spacing: Tokens.spacing.small

                                MaterialIcon {
                                    Layout.alignment: Qt.AlignVCenter

                                    text: item.modelData?.icon ?? ""

                                    color: item.active ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurfaceVariant
                                }

                                StyledText {
                                    Layout.alignment: Qt.AlignVCenter

                                    Layout.fillWidth: true

                                    text: item.modelData?.text ?? ""

                                    color: item.active ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurface
                                }

                                Loader {
                                    asynchronous: true

                                    Layout.alignment: Qt.AlignVCenter

                                    active: item.modelData?.trailingIcon.length > 0

                                    visible: active

                                    sourceComponent: MaterialIcon {
                                        text: item.modelData.trailingIcon

                                        color: item.active ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurfaceVariant
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
