pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Aether.Config
import Aether.I18n
import qs.components
import qs.components.controls
import qs.services

// The About page's easter egg, opened by holding the logo for a couple of seconds.
//
// The target is a random sum of sine components -- one more per level -- drawn dashed.
// The player gets the same number of components, each with its own amplitude, period and
// phase, and the solid curve is their sum. Aligning the sums clears the level and a new
// target appears with one more component (up to four), then just a tighter tolerance.
Item {
    id: root

    property bool open: false

    property int level: 1
    property bool completing: false

    // [{ amp, period, phase }, ...]
    property var targetParts: []
    property var parts: []
    property int selected: 0

    // Canvas view: wheel zooms around the pointer, dragging pans, double-click resets.
    property real zoom: 1
    property real viewX: 0
    property real centerY: 0

    readonly property int partCount: targetParts.length
    readonly property real maxAmp: Math.max(0.2, 0.8 / Math.max(1, partCount))
    // Peak of the target over its domain plus the continuation zooming out shows, with a
    // little headroom. The axis is fixed to the target rather than to both waves: a scale
    // that followed the player's amplitude would rescale the whole graph while a slider is
    // being dragged, which makes it impossible to judge a change against the previous one.
    // Overshooting the target simply clips, which reads as "too big".
    readonly property real scaleMax: {
        let max = 0.001;
        for (let i = -48; i <= 80; i++)
            max = Math.max(max, Math.abs(sumAt(targetParts, i / 32)));
        return max * 1.15;
    }

    readonly property real error: waveError()
    readonly property real tolerance: Math.max(0.03, 0.055 - (level - 1) * 0.0025)
    readonly property bool aligned: error <= tolerance

    signal close

    function sumAt(list: var, x: real): real {
        let value = 0;
        for (let i = 0; i < list.length; i++) {
            const part = list[i];
            value += part.amp * Math.sin(2 * Math.PI * x / part.period + part.phase);
        }
        return value;
    }

    function waveError(): real {
        if (targetParts.length === 0 || parts.length === 0)
            return 1;

        const samples = 128;
        let sum = 0;
        for (let i = 0; i <= samples; i++) {
            const x = i / samples;
            const d = sumAt(parts, x) - sumAt(targetParts, x);
            sum += d * d;
        }
        return Math.sqrt(sum / (samples + 1));
    }

    function startGame(): void {
        level = 1;
        completing = false;
        newTarget();
        resetView();
        forceActiveFocus();
    }

    function newTarget(): void {
        const count = Math.min(4, level);
        const maxA = 0.8 / count;
        const minA = maxA / 2;

        const target = [];
        const mine = [];
        for (let i = 0; i < count; i++) {
            target.push({
                amp: minA + Math.random() * (maxA - minA),
                period: 0.5 + Math.random() * 0.8,
                phase: Math.random() * Math.PI * 2
            });
            // The player starts from a flat, neutral component rather than from the answer.
            mine.push({
                amp: minA,
                period: 1,
                phase: 0
            });
        }

        targetParts = target;
        parts = mine;
        selected = 0;
        waveCanvas.requestPaint();
    }

    function setPartAmp(value: real): void {
        const next = [];
        for (let i = 0; i < parts.length; i++) {
            const part = parts[i];
            next.push(i === selected ? {
                amp: value,
                period: part.period,
                phase: part.phase
            } : part);
        }
        parts = next;
        waveCanvas.requestPaint();
    }

    function setPartPeriod(value: real): void {
        const next = [];
        for (let i = 0; i < parts.length; i++) {
            const part = parts[i];
            next.push(i === selected ? {
                amp: part.amp,
                period: value,
                phase: part.phase
            } : part);
        }
        parts = next;
        waveCanvas.requestPaint();
    }

    function setPartPhase(value: real): void {
        const next = [];
        for (let i = 0; i < parts.length; i++) {
            const part = parts[i];
            next.push(i === selected ? {
                amp: part.amp,
                period: part.period,
                phase: value
            } : part);
        }
        parts = next;
        waveCanvas.requestPaint();
    }

    // Keeps the visible window over the wave's [0, 1] domain: at zoom < 1 the window is
    // wider than the wave and centres it, at zoom > 1 it stays inside.
    function clampViewX(value: real, span: real): real {
        const edge = 1 - span;
        return Math.max(Math.min(0, edge), Math.min(Math.max(0, edge), value));
    }

    // Pixels per wave unit. Zooming out is horizontal only: the curve keeps its size so it
    // stays readable, and the extra width shows more of it.
    function verticalHalf(pixelHeight: real): real {
        return (pixelHeight / 2 - 8) / Math.max(0.2, scaleMax) * Math.max(1, zoom);
    }

    function resetView(): void {
        zoom = 1;
        viewX = 0;
        centerY = 0;
        waveCanvas.requestPaint();
    }

    function complete(): void {
        if (completing)
            return;

        completing = true;
        level++;
        advanceTimer.restart();
    }

    visible: opacity > 0
    enabled: open
    opacity: open ? 1 : 0
    focus: open

    onOpenChanged: {
        if (open)
            startGame();
        else
            completing = false;
    }

    onAlignedChanged: {
        if (aligned && open && !completing)
            complete();
    }

    onErrorChanged: waveCanvas.requestPaint()

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            root.close();
            event.accepted = true;
        }
    }

    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }

    Timer {
        id: advanceTimer

        interval: 850
        onTriggered: {
            root.completing = false;
            root.newTarget();
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Colours.palette.m3scrim, 0.72)
    }

    StyledRect {
        id: card

        anchors.centerIn: parent
        implicitWidth: Math.min(660, root.width - Tokens.padding.extraLarge * 2)
        implicitHeight: Math.min(700, root.height - Tokens.padding.extraLarge * 2)
        radius: Tokens.rounding.extraLarge
        color: Colours.palette.m3surfaceContainerHigh

        scale: root.open ? 1 : 0.94

        Behavior on scale {
            Anim {}
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.medium

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                StyledText {
                    Layout.fillWidth: true
                    text: Tr.tr("Aether Attunement")
                    font: Tokens.font.title.medium
                }

                IconButton {
                    icon: "close"
                    isRound: true
                    type: IconButton.Text
                    onClicked: root.close()
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: Tr.tr("Line the solid sum up with the dashed target; every component can be tuned on its own")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
                wrapMode: Text.WordWrap
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 230
                radius: Tokens.rounding.large
                color: Qt.alpha(Colours.palette.m3surfaceContainer, 0.6)
                border.width: 1
                border.color: root.aligned ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3outlineVariant, 0.5)

                Behavior on border.color {
                    CAnim {}
                }

                Canvas {
                    id: waveCanvas

                    anchors.fill: parent
                    anchors.margins: 10

                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);

                        // Visible window: `zoom` scales both axes, `viewX` is the left edge in
                        // wave units and `centerY` shifts the zero line for vertical panning.
                        const span = 1 / root.zoom;
                        const half = root.verticalHalf(height);
                        const mid = height / 2 - root.centerY * half;

                        const stroke = (list, colour, lineWidth, dash) => {
                            ctx.beginPath();
                            for (let i = 0; i <= 160; i++) {
                                const px = i / 160 * width;
                                const py = mid - root.sumAt(list, root.viewX + span * i / 160) * half;
                                if (i === 0)
                                    ctx.moveTo(px, py);
                                else
                                    ctx.lineTo(px, py);
                            }
                            ctx.strokeStyle = colour;
                            ctx.lineWidth = lineWidth;
                            ctx.setLineDash(dash);
                            ctx.stroke();
                        };

                        const selectedTarget = root.targetParts[root.selected] ? [root.targetParts[root.selected]] : [];
                        const selectedMine = root.parts[root.selected] ? [root.parts[root.selected]] : [];

                        // With one component the sum *is* the component, so the thin guide
                        // lines would only double every curve.
                        if (root.partCount > 1) {
                            stroke(selectedTarget, Qt.alpha(Colours.palette.m3onSurfaceVariant, 0.22), 1, [3, 5]);
                            stroke(selectedMine, Qt.alpha(Colours.palette.m3primary, 0.35), 1, []);
                        }

                        stroke(root.targetParts, Qt.alpha(Colours.palette.m3onSurfaceVariant, 0.8), 2, [6, 5]);
                        stroke(root.parts, Colours.palette.m3primary, 2, []);
                        ctx.setLineDash([]);
                    }
                }

                MouseArea {
                    id: viewport

                    property real pressX: 0
                    property real pressY: 0
                    property real fromX: 0
                    property real fromY: 0

                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    cursorShape: root.zoom > 1.001 ? Qt.ClosedHandCursor : Qt.ArrowCursor

                    onPressed: e => {
                        pressX = e.x;
                        pressY = e.y;
                        fromX = root.viewX;
                        fromY = root.centerY;
                    }

                    onPositionChanged: e => {
                        if (!pressed)
                            return;

                        const span = 1 / root.zoom;
                        root.viewX = root.clampViewX(fromX - (e.x - pressX) / width * span, span);

                        const half = root.verticalHalf(height);
                        root.centerY = Math.max(-1, Math.min(1, fromY - (e.y - pressY) / half));
                        waveCanvas.requestPaint();
                    }

                    onDoubleClicked: root.resetView()

                    onWheel: wheel => {
                        const span = 1 / root.zoom;
                        const fraction = wheel.x / width;
                        const anchor = root.viewX + fraction * span;

                        const step = wheel.angleDelta.y > 0 ? 1.15 : 1 / 1.15;
                        const next = Math.max(0.35, Math.min(12, root.zoom * step));
                        if (Math.abs(next - root.zoom) < 0.0001)
                            return;

                        const nextSpan = 1 / next;
                        root.zoom = next;
                        // Keep the wave under the pointer where it is while the zoom changes.
                        root.viewX = root.clampViewX(anchor - fraction * nextSpan, nextSpan);
                        waveCanvas.requestPaint();
                    }
                }

                StyledText {
                    visible: Math.abs(root.zoom - 1) > 0.001
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 8
                    text: "×" + root.zoom.toFixed(1)
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.small
                    opacity: 0.8

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.resetView()
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                text: Tr.tr("Wheel to zoom · drag to pan · double-click to reset")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.small
                opacity: 0.6
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                StyledText {
                    text: Tr.tr("Sine components")
                    font: Tokens.font.label.large
                }

                Repeater {
                    model: root.partCount

                    IconTextButton {
                        required property int index

                        Layout.fillWidth: true
                        text: (index + 1).toString()
                        type: root.selected === index ? IconTextButton.Filled : IconTextButton.Text
                        onClicked: {
                            root.selected = index;
                            waveCanvas.requestPaint();
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

                StyledText {
                    Layout.preferredWidth: 110
                    text: Tr.tr("Amplitude")
                    font: Tokens.font.label.large
                }

                StyledSlider {
                    Layout.fillWidth: true
                    from: 0
                    to: root.maxAmp
                    stepSize: 0.005
                    value: root.parts[root.selected] ? root.parts[root.selected].amp : 0
                    onInteraction: v => root.setPartAmp(from + v * (to - from))
                    onReleased: v => root.setPartAmp(from + v * (to - from))
                }

                StyledText {
                    Layout.preferredWidth: 46
                    horizontalAlignment: Text.AlignRight
                    text: Math.round((root.parts[root.selected] ? root.parts[root.selected].amp : 0) * 100) + "%"
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.medium
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

                StyledText {
                    Layout.preferredWidth: 110
                    text: Tr.tr("Period")
                    font: Tokens.font.label.large
                }

                StyledSlider {
                    Layout.fillWidth: true
                    from: 0.5
                    to: 1.3
                    stepSize: 0.005
                    value: root.parts[root.selected] ? root.parts[root.selected].period : 1
                    onInteraction: v => root.setPartPeriod(from + v * (to - from))
                    onReleased: v => root.setPartPeriod(from + v * (to - from))
                }

                StyledText {
                    Layout.preferredWidth: 46
                    horizontalAlignment: Text.AlignRight
                    text: (root.parts[root.selected] ? root.parts[root.selected].period : 1).toFixed(2)
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.medium
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

                StyledText {
                    Layout.preferredWidth: 110
                    text: Tr.tr("Phase")
                    font: Tokens.font.label.large
                }

                StyledSlider {
                    Layout.fillWidth: true
                    from: 0
                    to: 360
                    stepSize: 0.5
                    value: (root.parts[root.selected] ? root.parts[root.selected].phase * 180 / Math.PI : 0)
                    onInteraction: v => root.setPartPhase(Math.round(v * 360) * Math.PI / 180)
                    onReleased: v => root.setPartPhase(Math.round(v * 360) * Math.PI / 180)
                }

                StyledText {
                    Layout.preferredWidth: 46
                    horizontalAlignment: Text.AlignRight
                    text: Math.round(root.parts[root.selected] ? root.parts[root.selected].phase * 180 / Math.PI : 0) + "°"
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.medium
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                StyledText {
                    text: Tr.tr("Level %1").arg(root.level)
                    font: Tokens.font.label.large
                }

                StyledText {
                    visible: root.aligned
                    text: Tr.tr("Aligned")
                    color: Colours.palette.m3primary
                    font: Tokens.font.label.large
                }
            }
        }
    }
}
