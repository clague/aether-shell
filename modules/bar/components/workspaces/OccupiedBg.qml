pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property var workspaces
    required property int wsSpacing

    readonly property color colour: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
    property color colourAnimated: colour

    Behavior on colourAnimated {
        CAnim {}
    }

    // Item wrappers because `layer.enabled` clips the content, and the rects extend 1px outside the parent
    Item {
        anchors.fill: parent
        anchors.margins: -1

        opacity: root.colourAnimated.a
        layer.enabled: opacity < 1 // Forces opacity to apply to children as a single layer

        Item {
            anchors.fill: parent
            anchors.margins: 1

            AnimatedRepeater {
                model: ScriptModel {
                    values: root.workspaces
                }

                removeDuration: Tokens.anim.durations.expressiveDefaultEffects

<<<<<<< HEAD
        StyledRect {
            id: rect

            required property var modelData

            readonly property Workspace start: root.workspaces.count > 0 ? root.workspaces.itemAt(getWsIdx(modelData.start)) ?? null : null // qmllint disable incompatible-type
            readonly property Workspace end: root.workspaces.count > 0 ? root.workspaces.itemAt(getWsIdx(modelData.end)) ?? null : null // qmllint disable incompatible-type
            readonly property bool isHorizontal: Config.bar.position === "top" || Config.bar.position === "bottom"

            function getWsIdx(ws: int): int {
                let i = ws - 1;
                while (i < 0)
                    i += Config.bar.workspaces.shown;
                return i % Config.bar.workspaces.shown;
            }

            anchors.horizontalCenter: isHorizontal ? undefined : root.horizontalCenter
            anchors.verticalCenter: isHorizontal ? root.verticalCenter : undefined

            x: isHorizontal ? ((start?.x ?? 0) - 1) : 0
            y: isHorizontal ? 0 : ((start?.y ?? 0) - 1)
            implicitWidth: isHorizontal ? (start && end ? end.x + end.size - start.x + 2 : 0) : (Tokens.sizes.bar.innerWidth - Tokens.padding.small + 2)
            implicitHeight: isHorizontal ? (Tokens.sizes.bar.innerWidth - Tokens.padding.small + 2) : (start && end ? end.y + end.size - start.y + 2 : 0)

            color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)
            radius: Tokens.rounding.full

            scale: 0
            Component.onCompleted: scale = 1

            Behavior on scale {
                Anim {
                    easing: Tokens.anim.standardDecel
                }
            }

            Behavior on x {
                enabled: rect.isHorizontal

                Anim {}
            }

            Behavior on y {
                enabled: !rect.isHorizontal

                Anim {}
            }

            Behavior on implicitWidth {
                enabled: rect.isHorizontal

                Anim {}
            }

            Behavior on implicitHeight {
                enabled: !rect.isHorizontal

                Anim {}
=======
                OccupiedRect {}
>>>>>>> caelestia/main
            }
        }
    }

    component OccupiedRect: StyledRect {
        required property int index
        required property Workspace modelData

        property real topRadius: ifAdjacent(0, -1, 0, width / 2)
        property real bottomRadius: ifAdjacent(root.workspaces.length - 1, 1, 0, width / 2)
        property real topPadding: ifAdjacent(0, -1, root.wsSpacing, 0)
        property real bottomPadding: ifAdjacent(root.workspaces.length - 1, 1, root.wsSpacing, 0)

        function ifAdjacent(exclIdx: int, adj: int, yes: real, no: real): real {
            if (AnimatedRepeater.adding || AnimatedRepeater.removing || !modelData?.isOccupied || index === exclIdx)
                return no;
            return root.workspaces[index + adj]?.isOccupied ? yes : no;
        }

        anchors.left: parent?.left
        anchors.right: parent?.right
        anchors.margins: -1

        y: modelData ? modelData.y + anchors.margins - topPadding : 0
        implicitHeight: modelData ? modelData.LazyListView.visibleHeight - anchors.margins * 2 + topPadding + bottomPadding : 0

        color: Qt.alpha(root.colour, 1)
        topLeftRadius: topRadius
        topRightRadius: topRadius
        bottomLeftRadius: bottomRadius
        bottomRightRadius: bottomRadius

        opacity: modelData?.isOccupied ? 1 : 0

        Behavior on topRadius {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on bottomRadius {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on topPadding {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on bottomPadding {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }
}
