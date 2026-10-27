pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import M3Shapes
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

GridLayout {    id: root

    required property int modelData
    required property int index
    required property int activeWsId
    required property int ws
    required property HyprlandMonitor monitor

    readonly property bool isWorkspace: true // Flag for finding workspace children
    readonly property bool isHorizontal: Config.bar.position === "top" || Config.bar.position === "bottom"

    // Unanimated prop for others to use as reference
    readonly property int size: isHorizontal ? (implicitWidth + (hasWindows ? Tokens.padding.extraSmall : 0)) : (implicitHeight + (hasWindows ? Tokens.padding.extraSmall : 0))
    readonly property list<HyprlandToplevel> toplevels: Hypr.toplevelsForWs(ws, GlobalConfig.bar.workspaces.ignoredTags)
    readonly property bool isOccupied: toplevels.length > 0
    readonly property bool hasWindows: isOccupied && showWindows && Config.bar.workspaces.maxWindowIcons > 0
    readonly property bool focused: activeWsId === ws
    readonly property list<int> focusedShapeList: [MaterialShape.Slanted, MaterialShape.Oval, MaterialShape.Pill, MaterialShape.Triangle, MaterialShape.Arrow, MaterialShape.Diamond, MaterialShape.Pentagon, MaterialShape.Gem, MaterialShape.VerySunny, MaterialShape.Sunny, MaterialShape.Cookie4Sided, MaterialShape.Cookie6Sided, MaterialShape.Cookie7Sided, MaterialShape.Cookie9Sided, MaterialShape.Cookie12Sided, MaterialShape.Clover4Leaf, MaterialShape.SoftBurst, MaterialShape.Ghostish]

    property color offMonitorColour: Colours.palette.m3outlineVariant
    readonly property bool onOtherMonitor: {
        if (Config.bar.workspaces.perMonitor)
            return false;
        const mon = Hypr.workspaces.values.find(w => w.id === ws)?.monitor;
        return !!(mon && mon !== monitor);
    }
    readonly property color fgColour: {
        if (onOtherMonitor)
            return offMonitorColour;
        if (focused || isOccupied || Config.bar.workspaces.occupiedBg)
            return Colours.palette.m3onSurface;
        return Colours.layer(Colours.palette.m3outlineVariant, 2);
    }

    function updateShape(): void {
        const shape = indicator.item as MaterialShape;
        if (!shape)
            return;

        if (focused)
            shape.shape = focusedShapeList[Math.floor(Math.random() * focusedShapeList.length)];
        else
            shape.shape = Qt.binding(() => isOccupied ? MaterialShape.Square : MaterialShape.Circle);
    }

    columns: isHorizontal ? -1 : 1
    rows: isHorizontal ? 1 : -1
    flow: isHorizontal ? GridLayout.LeftToRight : GridLayout.TopToBottom

    Layout.alignment: isHorizontal ? Qt.AlignVCenter : Qt.AlignHCenter
    Layout.preferredWidth: isHorizontal ? size : -1
    Layout.preferredHeight: isHorizontal ? -1 : size
    columnSpacing: 0
    rowSpacing: 0

    Behavior on LazyListView.visibleHeight {
        Anim {}
    }

        Layout.alignment: root.isHorizontal ? (Qt.AlignVCenter | Qt.AlignLeft) : (Qt.AlignHCenter | Qt.AlignTop)
        Layout.preferredWidth: root.isHorizontal ? (Tokens.sizes.bar.innerWidth - Tokens.padding.small) : -1
        Layout.preferredHeight: root.isHorizontal ? -1 : (Tokens.sizes.bar.innerWidth - Tokens.padding.small)

        asynchronous: true
        sourceComponent: Config.bar.workspaces.useIcon ? iconComponent : textComponent    }

    Component {
        id: textComponent

        StyledText {
            animate: true
            text: {
                const ws = Hypr.workspaces.values.find(w => w.id === root.ws);
                const wsName = !ws || ws.name == root.ws ? root.ws : ws.name[0];
                let displayName = wsName.toString();
                if (Config.bar.workspaces.capitalisation.toLowerCase() === "upper") {
                    displayName = displayName.toUpperCase();
                } else if (Config.bar.workspaces.capitalisation.toLowerCase() === "lower") {
                    displayName = displayName.toLowerCase();
                }
                const label = Config.bar.workspaces.label || displayName;
                const occupiedLabel = Config.bar.workspaces.occupiedLabel || label;
                const activeLabel = Config.bar.workspaces.activeLabel || (root.isOccupied ? occupiedLabel : label);
                return root.activeWsId === root.ws ? activeLabel : root.isOccupied ? occupiedLabel : label;
            }
            color: Config.bar.workspaces.occupiedBg || root.isOccupied || root.activeWsId === root.ws ? Colours.palette.m3onSurface : Colours.layer(Colours.palette.m3outlineVariant, 2)            verticalAlignment: Qt.AlignVCenter
            font.family: Tokens.font.workspaces
        }
    }

    Component {
        id: iconComponent

        Item {
            id: iconRoot

            // Track if this position was active (independent of which workspace)
            readonly property bool active: root.activeWsId === root.ws
            property int randShape: MaterialShape.Slanted
            property bool wasPositionActive: false
            property int lastKnownWs: -1
            property int prevActiveWsId: -1

            // Track the previous workspace at this position (before current change)
            property int prevWs: -1

            // Watch for workspace ID changes while inactive by using a binding
            property int watchedWs: root.ws

            // Track the last watched ws separately for detecting changes
            property int lastWatchedWs: -1

            // JavaScript functions
            function handleActivation() {
                const wsChanged = lastKnownWs !== root.ws;
                if (active && (!wasPositionActive || wsChanged)) {
                    const shapes = [MaterialShape.Slanted, MaterialShape.Arch, MaterialShape.Oval, MaterialShape.Pill, MaterialShape.Triangle, MaterialShape.Arrow, MaterialShape.Diamond, MaterialShape.Pentagon, MaterialShape.Gem, MaterialShape.VerySunny, MaterialShape.Sunny, MaterialShape.Cookie4Sided, MaterialShape.Cookie6Sided, MaterialShape.Cookie7Sided, MaterialShape.Cookie9Sided, MaterialShape.Cookie12Sided, MaterialShape.Clover4Leaf, MaterialShape.Clover8Leaf, MaterialShape.SoftBurst, MaterialShape.Ghostish];
                    const shuffled = [...shapes].sort(() => Math.random() - 0.5);
                    randShape = shuffled[0];
                    wsShape.shape = randShape;
                    wsShape.scale = 1 / 3;
                    deactivateAnim.stop();
                    activateAnim.fromValue = 1 / 3;
                    activateAnim.toValue = 2 / 3;
                    activateAnim.running = true;
                } else if (!active && (wasPositionActive || wsChanged)) {
                    const targetShape = root.isOccupied ? MaterialShape.Square : MaterialShape.Circle;
                    wsShape.shape = targetShape;
                    wsShape.scale = 1 / 3;
                    activateAnim.stop();
                    deactivateAnim.stop();
                }
                wasPositionActive = active;
                prevWs = lastKnownWs;
                lastKnownWs = root.ws;
                prevActiveWsId = root.activeWsId;
            }

            // Signal handlers
            onWatchedWsChanged: {
                if (lastWatchedWs !== -1 && watchedWs !== lastWatchedWs && !active) {
                    activateAnim.stop();
                    deactivateAnim.stop();
                    wsShape.shape = root.isOccupied ? MaterialShape.Square : MaterialShape.Circle;
                    wsShape.scale = 1 / 3;
                }
                lastWatchedWs = watchedWs;
            }

            onPrevActiveWsIdChanged: {
                if (prevActiveWsId !== -1 && prevActiveWsId !== root.activeWsId && active) {
                    handleActivation();
                }
            }

            onActiveChanged: handleActivation()

            // Bindings
            implicitWidth: Tokens.sizes.bar.innerWidth - Tokens.padding.small
            implicitHeight: Tokens.sizes.bar.innerWidth - Tokens.padding.small

            // Initialize state when component is created
            Component.onCompleted: {
                if (active) {
                    handleActivation();
                } else {
                    wsShape.shape = root.isOccupied ? MaterialShape.Square : MaterialShape.Circle;
                }
                wasPositionActive = active;
                prevWs = -1;
                lastKnownWs = root.ws;
                prevActiveWsId = root.activeWsId;
                lastWatchedWs = root.ws;
            }

            MaterialShape {
                id: wsShape

                anchors.centerIn: parent
                implicitSize: iconRoot.width
                scale: iconRoot.active ? 2 / 3 : 1 / 3
                color: Config.bar.workspaces.occupiedBg || root.isOccupied || root.activeWsId === root.ws ? Colours.palette.m3onSurface : Colours.layer(Colours.palette.m3outlineVariant, 2)

                Behavior on color {
                    CAnim {}
                }

                Behavior on scale {
                    enabled: !activateAnim.running && !deactivateAnim.running

                    Anim {
                        type: Anim.DefaultEffects
                    }
                }

                SequentialAnimation {
                    id: activateAnim

                    property real fromValue: 1 / 3
                    property real toValue: 2 / 3

                    Anim {
                        target: wsShape
                        property: "scale"
                        from: activateAnim.fromValue
                        to: activateAnim.toValue
                        type: Anim.FastSpatial
                    }
                }

                SequentialAnimation {
                    id: deactivateAnim

                    property real fromValue: 2 / 3
                    property real toValue: 1 / 3

                    Anim {
                        target: wsShape
                        property: "scale"
                        from: deactivateAnim.fromValue
                        to: deactivateAnim.toValue
                        type: Anim.FastSpatial
                    }
                }
            }
        }
    }

    Loader {
        id: windows
        MaterialIcon {
            fill: 1
            grade: 25
            text: iconCacher.icon
            color: root.fgColour
            verticalAlignment: Qt.AlignVCenter

        Layout.alignment: root.isHorizontal ? Qt.AlignVCenter : Qt.AlignHCenter
        Layout.fillWidth: root.isHorizontal && enabled
        Layout.fillHeight: !root.isHorizontal && enabled
        Layout.topMargin: root.isHorizontal ? 0 : -Tokens.sizes.bar.innerWidth / 10
        Layout.leftMargin: root.isHorizontal ? -Tokens.sizes.bar.innerWidth / 10 : 0
    Component {
        id: iconLoaderComponent

        sourceComponent: root.isHorizontal ? rowComponent : columnComponent
    }

    Component {
        id: columnComponent

        Column {
            spacing: 0

            add: Transition {
                Anim {
                    properties: "scale"
                    from: 0
                    to: 1
                    easing: Tokens.anim.standardDecel
                }
            }

            move: Transition {
                Anim {
                    properties: "scale"
                    to: 1
                    easing: Tokens.anim.standardDecel
                }
                Anim {
                    properties: "x,y"
                }
            }

            Repeater {
                model: ScriptModel {
                    values: {
                        const ws = root.ws;
                        const windows = Hypr.toplevels.values.filter(c => c.workspace?.id === ws);
                        const maxIcons = root.Config.bar.workspaces.maxWindowIcons;
                        return maxIcons > 0 ? windows.slice(0, maxIcons) : windows;
                    }
                }

                MaterialIcon {
                    required property var modelData

                    grade: 0
                    text: Icons.getAppCategoryIcon(modelData.lastIpcObject.class, "terminal")
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
        }
    }

    Component {
        id: rowComponent

        Row {
            spacing: 0
            WsIconCacher {
                id: loaderIconCacher
            }
        }
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: 0

        Loader {
            id: indicator

            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
            Layout.preferredHeight: Tokens.sizes.bar.innerWidth - Tokens.padding.small
            sourceComponent: {
                if (root.displayType === BarWorkspaceDisplay.Icons)
                    return iconLoaderComponent;
                if (root.displayType === BarWorkspaceDisplay.Text)
                    return textComponent;
                return shapeComponent;
            }

            onItemChanged: root.updateShape()
        }

        Loader {
            id: windows

            asynchronous: true

            Layout.fillWidth: true
            Layout.topMargin: -Tokens.spacing.extraSmall / 2
            Layout.preferredHeight: root.hasWindows && item ? (item as LazyListView).layoutHeight : 0

            visible: active
            active: root.showWindows && Config.bar.workspaces.maxWindowIcons > 0

            sourceComponent: LazyListView {
                spacing: 0
                implicitHeight: contentHeight
                cullDelegates: false
                removeDuration: Tokens.anim.durations.expressiveDefaultEffects

                model: ScriptModel {
                    values: {
                        const windows = root.toplevels;
                        const maxIcons = root.Config.bar.workspaces.maxWindowIcons;
                        return maxIcons > 0 ? windows.slice(0, maxIcons) : windows;
                    }
                }

                delegate: MaterialIcon {
                    id: win

                    required property var modelData
                    required property int index // Needed, LazyListView will fail to set it if it doesn't exist

                    grade: 0
                    horizontalAlignment: Text.AlignHCenter
                    text: Icons.getAppCategoryIcon(modelData.lastIpcObject.class, "terminal")
                    color: root.onOtherMonitor ? root.offMonitorColour : Colours.palette.m3onSurfaceVariant

                    opacity: LazyListView.adding || LazyListView.removing ? 0 : 1

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }

                    Behavior on y {
                        Anim {}
                    }
                }
            }
        }
    }

    Behavior on Layout.preferredHeight {
        enabled: !root.isHorizontal

        Anim {}
    }

    Behavior on Layout.preferredWidth {
        enabled: root.isHorizontal

        Anim {}    }
}
