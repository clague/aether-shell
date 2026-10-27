pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Caelestia
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services

Item {
    id: root

    required property HyprlandMonitor monitor

    readonly property int activeSpecialId: monitor?.lastIpcObject.specialWorkspace?.id ?? 0
    readonly property var wsIds: {
        const allMonitors = !Config.bar.workspaces.perMonitor;
        return Hypr.workspaces.values.filter(w => w.name.startsWith("special:") && (allMonitors || w.monitor === root.monitor)).map(w => w.id);
    }
    readonly property int activeIdx: wsIds.indexOf(activeSpecialId)
    readonly property real maxViewY: Math.max(0, view.contentHeight - height)

    readonly property Workspace activeWs: {
        CUtils.dependency(view.itemsDirty);
        return view.itemAtIndex(activeIdx) as Workspace;
    }

    function ensureVisible(animate = true): void {
        if (!activeWs)
            return;

        const top = activeWs.LazyListView.layoutY;
        const bottom = top + activeWs.LazyListView.preferredHeight;

        let target = view.y;
        if (top < -target)
            target = -top;
        else if (bottom > -target + height)
            target = -(bottom - height);

        target = CUtils.clamp(target, -maxViewY, 0);
        if (target !== view.y) {
            if (animate) {
                const type = viewYAnim.type;
                viewYAnim.type = Anim.DefaultSpatial;
                view.y = target;
                viewYAnim.type = type;
            } else {
                viewYBehavior.enabled = false;
                view.y = target;
                viewYBehavior.enabled = true;
            }
        }
    }

    onActiveWsChanged: ensureVisible()
    onHeightChanged: ensureVisible(false)
    Component.onCompleted: ensureVisible(false)
    onMaxViewYChanged: ensureVisible()

    readonly property bool isHorizontal: Config.bar.position === "top" || Config.bar.position === "bottom"

    // (Removed root-level 'size' property that was causing the 'label is not defined' error)

    layer.enabled: true
    layer.effect: Mask {
        maskSource: mask
    }

    Connections {
        function onLayoutYChanged(): void {
            root.ensureVisible();
        }

        function onPreferredHeightChanged(): void {
            root.ensureVisible();
        }

        target: root.activeWs?.LazyListView ?? null
    }

    Item {
        id: mask

        anchors.fill: parent
        layer.enabled: true
        visible: false

        Rectangle {
            anchors.fill: parent
            radius: Tokens.rounding.full

            gradient: Gradient {
                orientation: root.isHorizontal ? Gradient.Horizontal : Gradient.Vertical

                GradientStop {
                    position: 0
                    color: Qt.rgba(0, 0, 0, 0)
                }
                GradientStop {
                    position: 0.2
                    color: Qt.rgba(0, 0, 0, 1)
                }
                GradientStop {
                    position: 0.8
                    color: Qt.rgba(0, 0, 0, 1)
                }
                GradientStop {
                    position: 1
                    color: Qt.rgba(0, 0, 0, 0)
                }
            }
        }

        Rectangle {
            anchors.top: parent.top
            anchors.bottom: root.isHorizontal ? parent.bottom : undefined
            anchors.left: parent.left
            anchors.right: root.isHorizontal ? undefined : parent.right

            radius: Tokens.rounding.full
<<<<<<< HEAD
            // Changed undefined to 0 to fix "Unable to assign [undefined] to double"
            implicitWidth: root.isHorizontal ? parent.width / 2 : 0
            implicitHeight: root.isHorizontal ? 0 : parent.height / 2
            opacity: root.isHorizontal ? (view.contentX > 0 ? 0 : 1) : (view.contentY > 0 ? 0 : 1)
=======
            implicitHeight: parent.height / 2
            opacity: view.y < -Tokens.padding.extraSmall ? 0 : 1
>>>>>>> caelestia/main

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.top: root.isHorizontal ? parent.top : undefined
            anchors.right: parent.right
            anchors.left: root.isHorizontal ? undefined : parent.left

            radius: Tokens.rounding.full
<<<<<<< HEAD
            implicitWidth: root.isHorizontal ? parent.width / 2 : 0
            implicitHeight: root.isHorizontal ? 0 : parent.height / 2
            opacity: root.isHorizontal ? (view.contentX < view.contentWidth - parent.width + Tokens.padding.extraSmall ? 0 : 1) : (view.contentY < view.contentHeight - parent.height + Tokens.padding.extraSmall ? 0 : 1)
=======
            implicitHeight: parent.height / 2
            opacity: view.y > -root.maxViewY + Tokens.padding.extraSmall ? 0 : 1
>>>>>>> caelestia/main

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }
    }

    LazyListView {
        id: view

        anchors.left: parent.left
        anchors.right: parent.right
        implicitHeight: contentHeight

<<<<<<< HEAD
        orientation: root.isHorizontal ? ListView.Horizontal : ListView.Vertical

        currentIndex: model.values.findIndex(w => w.name === root.activeSpecial)
        onCurrentIndexChanged: currentIndex = Qt.binding(() => model.values.findIndex(w => w.name === root.activeSpecial))
=======
        cullDelegates: false
        spacing: Tokens.spacing.small
        removeDuration: Tokens.anim.durations.expressiveDefaultEffects

        onContentHeightChanged: root.ensureVisible()
>>>>>>> caelestia/main

        model: ScriptModel {
            values: root.wsIds
        }

<<<<<<< HEAD
        preferredHighlightBegin: 0
        preferredHighlightEnd: root.isHorizontal ? width : height
        highlightRangeMode: ListView.StrictlyEnforceRange

        highlightFollowsCurrentItem: false

        highlight: Item {
            x: root.isHorizontal ? (view.currentItem?.x ?? 0) : 0
            y: root.isHorizontal ? 0 : (view.currentItem?.y ?? 0)
            implicitWidth: root.isHorizontal ? ((view.currentItem as SpecialWsDelegate)?.size ?? 0) : 0
            implicitHeight: root.isHorizontal ? 0 : ((view.currentItem as SpecialWsDelegate)?.size ?? 0)

            Behavior on x {
                enabled: root.isHorizontal

                Anim {}
            }

            Behavior on y {
                enabled: !root.isHorizontal

                Anim {}
            }
=======
        delegate: Workspace {
            activeWsId: root.activeSpecialId
            ws: modelData
            monitor: root.monitor
            offMonitorColour: Colours.palette.m3outline
            displayType: Config.bar.workspaces.specialDisplayType
            showWindows: Config.bar.workspaces.showWindowsOnSpecialWorkspaces
            iconRules: GlobalConfig.bar.workspaces.specialWorkspaceIcons
>>>>>>> caelestia/main
        }

        Behavior on y {
            id: viewYBehavior

            Anim {
                id: viewYAnim

                type: Anim.FastEffects
            }
        }
    }

    Loader {
        asynchronous: true
        anchors.left: view.left
        anchors.right: view.right
        active: Config.bar.workspaces.activeIndicator

<<<<<<< HEAD
        sourceComponent: Item {
            StyledClippingRect {
                id: indicator

                anchors.left: root.isHorizontal ? undefined : parent.left
                anchors.right: root.isHorizontal ? undefined : parent.right
                anchors.top: root.isHorizontal ? parent.top : undefined
                anchors.bottom: root.isHorizontal ? parent.bottom : undefined

                x: root.isHorizontal ? ((view.currentItem?.x ?? 0) - view.contentX) : 0
                y: root.isHorizontal ? 0 : ((view.currentItem?.y ?? 0) - view.contentY)
                implicitWidth: root.isHorizontal ? ((view.currentItem as SpecialWsDelegate)?.size ?? 0) : view.width
                implicitHeight: root.isHorizontal ? view.height : ((view.currentItem as SpecialWsDelegate)?.size ?? 0)

                color: Colours.palette.m3tertiary
                radius: Tokens.rounding.full

                Colouriser {
                    source: view
                    sourceColor: Colours.palette.m3onSurface
                    colorizationColor: Colours.palette.m3onTertiary

                    anchors.horizontalCenter: root.isHorizontal ? undefined : parent.horizontalCenter
                    anchors.verticalCenter: root.isHorizontal ? parent.verticalCenter : undefined

                    x: root.isHorizontal ? -indicator.x : 0
                    y: root.isHorizontal ? 0 : -indicator.y
                    implicitWidth: view.width
                    implicitHeight: view.height
                }

                Behavior on x {
                    enabled: root.isHorizontal

                    Anim {
                        type: Anim.Emphasized
                    }
                }

                Behavior on y {
                    enabled: !root.isHorizontal

                    Anim {
                        type: Anim.Emphasized
                    }
                }

                Behavior on implicitWidth {
                    enabled: root.isHorizontal

                    Anim {
                        type: Anim.Emphasized
                    }
                }

                Behavior on implicitHeight {
                    enabled: !root.isHorizontal

                    Anim {
                        type: Anim.Emphasized
                    }
                }
            }
=======
        sourceComponent: ActiveIndicator {
            activeWs: root.activeWs
            mask: view
            color: Colours.palette.m3tertiary
            contentColour: Colours.palette.m3onTertiary
>>>>>>> caelestia/main
        }
    }

    MouseArea {
<<<<<<< HEAD
        property real startPos
=======
        property real startY
        property real startViewY
        property bool dragging
>>>>>>> caelestia/main

        anchors.fill: parent

<<<<<<< HEAD
        drag.target: view.contentItem

        drag.axis: root.isHorizontal ? Drag.XAxis : Drag.YAxis
        drag.maximumX: 0
        drag.minimumX: root.isHorizontal ? Math.min(0, view.width - view.contentWidth - Tokens.padding.small) : 0
        drag.maximumY: 0
        drag.minimumY: root.isHorizontal ? 0 : Math.min(0, view.height - view.contentHeight - Tokens.padding.extraSmall)

        onPressed: event => startPos = root.isHorizontal ? event.x : event.y

        onClicked: event => {
            const currentPos = root.isHorizontal ? event.x : event.y;
            if (Math.abs(currentPos - startPos) > drag.threshold)
                return;

            const ws = view.itemAt(event.x, event.y) as SpecialWsDelegate;
            if (ws?.modelData)
                Hypr.dispatch(Hypr.usingLua ? `hl.dsp.workspace.toggle_special("${ws.modelData.name.slice(8)}")` : `togglespecialworkspace ${ws.modelData.name.slice(8)}`);
            else
                Hypr.dispatch(Hypr.usingLua ? 'hl.dsp.workspace.toggle_special("special")' : "togglespecialworkspace special");
        }
    }

    component SpecialWsDelegate: GridLayout {
        id: ws

        required property HyprlandWorkspace modelData
        readonly property int size: root.isHorizontal ? (label.Layout.preferredWidth + (hasWindows ? windows.implicitWidth + Tokens.padding.extraSmall : 0)) : (label.Layout.preferredHeight + (hasWindows ? windows.implicitHeight + Tokens.padding.extraSmall : 0))
        property int wsId
        property string icon
        property bool hasWindows

        columns: root.isHorizontal ? -1 : 1
        rows: root.isHorizontal ? 1 : -1
        flow: root.isHorizontal ? GridLayout.LeftToRight : GridLayout.TopToBottom

        anchors.left: root.isHorizontal ? undefined : view.contentItem.left
        anchors.right: root.isHorizontal ? undefined : view.contentItem.right
        anchors.top: root.isHorizontal ? view.contentItem.top : undefined
        anchors.bottom: root.isHorizontal ? view.contentItem.bottom : undefined

        columnSpacing: 0
        rowSpacing: 0

        Component.onCompleted: {
            wsId = modelData.id;
            icon = Icons.getSpecialWsIcon(modelData.name);
            hasWindows = Config.bar.workspaces.showWindowsOnSpecialWorkspaces && modelData.lastIpcObject.windows > 0;
        }

        Connections {
            function onIdChanged(): void {
                if (ws.modelData)
                    ws.wsId = ws.modelData.id;
            }

            function onNameChanged(): void {
                if (ws.modelData)
                    ws.icon = Icons.getSpecialWsIcon(ws.modelData.name);
            }

            function onLastIpcObjectChanged(): void {
                if (ws.modelData) {
                    ws.hasWindows = root.Config.bar.workspaces.showWindowsOnSpecialWorkspaces && ws.modelData.lastIpcObject.windows > 0;
                    ws.wsId = ws.modelData.id;
                }
            }

            target: ws.modelData
        }

        Connections {
            function onShowWindowsOnSpecialWorkspacesChanged(): void {
                if (ws.modelData)
                    ws.hasWindows = root.Config.bar.workspaces.showWindowsOnSpecialWorkspaces && ws.modelData.lastIpcObject.windows > 0;
            }

            target: root.Config.bar.workspaces
        }

        Loader {
            id: label

            asynchronous: true

            Layout.alignment: root.isHorizontal ? (Qt.AlignVCenter | Qt.AlignLeft) : (Qt.AlignHCenter | Qt.AlignTop)
            Layout.preferredWidth: root.isHorizontal ? Tokens.sizes.bar.innerWidth : -1
            Layout.preferredHeight: root.isHorizontal ? -1 : Tokens.sizes.bar.innerWidth

            sourceComponent: ws.icon.length === 1 ? letterComp : iconComp

            Component {
                id: iconComp

                MaterialIcon {
                    anchors.fill: parent
                    fill: 1
                    text: ws.icon
                    verticalAlignment: Qt.AlignVCenter
                    horizontalAlignment: Qt.AlignHCenter
                }
            }

            Component {
                id: letterComp

                StyledText {
                    anchors.fill: parent
                    text: ws.icon
                    verticalAlignment: Qt.AlignVCenter
                    horizontalAlignment: Qt.AlignHCenter
                }
            }
        }

        Loader {
            id: windows

            asynchronous: true

            Layout.alignment: root.isHorizontal ? Qt.AlignVCenter : Qt.AlignHCenter
            Layout.fillWidth: root.isHorizontal && enabled
            Layout.fillHeight: !root.isHorizontal && enabled

            visible: active
            active: ws.hasWindows

            sourceComponent: root.isHorizontal ? rowComponent : columnComponent

            Behavior on Layout.preferredHeight {
                enabled: !root.isHorizontal

                Anim {}
            }
        }

        // MOVED COMPONENTS INSIDE DELEGATE: This fixes the "ws is not defined" error
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
                            const windows = Hypr.toplevelsForWs(ws.wsId);
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
                            const windows = Hypr.toplevels.values.filter(c => c.workspace?.id === ws.wsId);
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
=======
        onPressed: event => {
            startY = event.y;
            startViewY = view.y;
            dragging = false;
        }

        onPositionChanged: event => {
            if (!dragging && Math.abs(event.y - startY) > drag.threshold)
                dragging = true;

            if (dragging)
                view.y = CUtils.clamp(startViewY + (event.y - startY), -root.maxViewY, 0);
        }

        onClicked: event => {
            if (dragging)
                return;

            const ws = view.itemAt(event.x, event.y - view.y) as Workspace;
            if (ws) {
                const match = Hypr.workspaces.values.find(w => w.id === ws.ws);
                if (match)
                    Hypr.toggleSpecial(Hypr.trimWsName(match.name));
            } else {
                Hypr.toggleSpecial("special");
>>>>>>> caelestia/main
            }
        }
    }
}
