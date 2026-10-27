pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services

StyledRect {
    id: root

    required property Workspace activeWs
    required property Item mask
    property alias contentColour: colouriser.colorizationColor

    property real start
    property real end

    function runAnim(): void {
        if (!activeWs)
            return;

        const newStart = activeWs.LazyListView.layoutY;
        const goingUp = newStart < start;
        const leadingDuration = Tokens.anim.durations.expressiveDefaultSpatial;
        const trailingDuration = leadingDuration * (Config.bar.workspaces.activeTrail ? 1.5 : 1);

        startAnim.stop();
        endAnim.stop();
        startAnim.to = newStart;
        endAnim.to = newStart + activeWs.LazyListView.preferredHeight;
        startAnim.duration = goingUp ? leadingDuration : trailingDuration;
        endAnim.duration = goingUp ? trailingDuration : leadingDuration;
        startAnim.start();
        endAnim.start();
    }

    readonly property bool isHorizontal: Config.bar.position === "top" || Config.bar.position === "bottom"

    property real leading: workspaces.count > 0 ? (isHorizontal ? workspaces.itemAt(currentWsIdx)?.x : workspaces.itemAt(currentWsIdx)?.y) ?? 0 : 0
    property real trailing: workspaces.count > 0 ? (isHorizontal ? workspaces.itemAt(currentWsIdx)?.x : workspaces.itemAt(currentWsIdx)?.y) ?? 0 : 0
    property real currentSize: workspaces.count > 0 ? (workspaces.itemAt(currentWsIdx) as Workspace)?.size ?? 0 : 0
    property real offset: Math.min(leading, trailing)
    property real size: {
        const s = Math.abs(leading - trailing) + currentSize;
        if (Config.bar.workspaces.activeTrail && lastWs > currentWsIdx) {
            const ws = workspaces.itemAt(lastWs) as Workspace;
            return ws ? Math.min((isHorizontal ? ws.x : ws.y) + ws.size - offset, s) : 0;
        }
        return s;
    }

    property int cWs
    property int lastWs

    onCurrentWsIdxChanged: {
        lastWs = cWs;
        cWs = currentWsIdx;
    }

    clip: true
    anchors.horizontalCenter: isHorizontal ? undefined : parent.horizontalCenter
    anchors.verticalCenter: isHorizontal ? parent.verticalCenter : undefined

    x: isHorizontal ? offset + mask.x : 0
    y: isHorizontal ? 0 : offset + mask.y
    implicitWidth: isHorizontal ? size : Tokens.sizes.bar.innerWidth - Tokens.padding.small
    implicitHeight: isHorizontal ? Tokens.sizes.bar.innerWidth - Tokens.padding.small : size    radius: Tokens.rounding.full
    color: Colours.palette.m3primary

    Anim on start {
        id: startAnim
    }

    Anim on end {
        id: endAnim
    }

    Connections {
        function onLayoutYChanged(): void {
            root.runAnim();
        }

        function onPreferredHeightChanged(): void {
            root.runAnim();
        }

        target: root.activeWs?.LazyListView ?? null
    }

    Colouriser {
        id: colouriser

        source: root.mask
        sourceColor: Colours.palette.m3onSurface
        colorizationColor: Colours.palette.m3onPrimary

        x: root.isHorizontal ? -parent.offset : 0
        y: root.isHorizontal ? 0 : -parent.offset
        implicitWidth: root.mask.implicitWidth
        implicitHeight: root.mask.implicitHeight
        anchors.horizontalCenter: root.isHorizontal ? undefined : parent.horizontalCenter
        anchors.verticalCenter: root.isHorizontal ? parent.verticalCenter : undefined
    }
}
