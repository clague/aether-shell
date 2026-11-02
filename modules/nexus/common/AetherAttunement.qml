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
// A target waveform is generated at random -- its form, amplitude, period and phase -- and
// is drawn as a dim curve. The player tunes their own curve's form, amplitude, period and
// phase until the two overlap; when the deviation drops below the level's tolerance the
// level clears and a harder target appears (more forms, less slack).
Item {
    id: root

    property bool open: false

    property int level: 1
    property int cleared: 0
    property bool completing: false

    property string targetForm: "sine"
    property real targetAmp: 0.7
    property real targetPeriod: 0.9
    property real targetPhase: 0

    property string form: "sine"
    property real amp: 0.5
    property real period: 1
    property real phase: 0

    readonly property var forms: ["sine", "triangle", "square", "saw"]

    // Root-mean-square difference between the two curves, sampled across the canvas. It is
    // 0 when they coincide exactly and grows with any amplitude, period or phase error.
    readonly property real error: waveError()
    readonly property real tolerance: Math.max(0.03, 0.06 - (level - 1) * 0.004)
    readonly property bool aligned: error <= tolerance

    signal close

    function waveAt(f: string, x: real, amplitude: real, per: real, shift: real): real {
        const t = 2 * Math.PI * (x / per) + shift;
        let v;
        switch (f) {
        case "triangle":
            v = 2 / Math.PI * Math.asin(Math.sin(t));
            break;
        case "square":
            v = Math.sin(t) >= 0 ? 1 : -1;
            break;
        case "saw":
            v = 2 * (t / (2 * Math.PI) - Math.floor(t / (2 * Math.PI) + 0.5));
            break;
        default:
            v = Math.sin(t);
        }
        return amplitude * v;
    }

    function waveError(): real {
        const samples = 96;
        let sum = 0;
        for (let i = 0; i <= samples; i++) {
            const x = i / samples;
            const d = waveAt(form, x, amp, period, phase) - waveAt(targetForm, x, targetAmp, targetPeriod, targetPhase);
            sum += d * d;
        }
        return Math.sqrt(sum / (samples + 1));
    }

    function formLabel(f: string): string {
        switch (f) {
        case "triangle":
            return Tr.tr("Triangle wave");
        case "square":
            return Tr.tr("Square wave");
        case "saw":
            return Tr.tr("Sawtooth wave");
        default:
            return Tr.tr("Sine wave");
        }
    }

    function startGame(): void {
        level = 1;
        cleared = 0;
        completing = false;
        newTarget();
        forceActiveFocus();
    }

    function newTarget(): void {
        const pool = forms.slice(0, Math.min(forms.length, level));
        targetForm = pool[Math.floor(Math.random() * pool.length)];
        targetAmp = 0.45 + Math.random() * 0.4;
        targetPeriod = 0.55 + Math.random() * 0.6;
        targetPhase = Math.random() * Math.PI * 2;

        form = "sine";
        amp = 0.5;
        period = 1;
        phase = 0;

        waveCanvas.requestPaint();
    }

    function complete(): void {
        if (completing)
            return;

        completing = true;
        cleared++;
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
                text: Tr.tr("Match the solid wave to the dashed target with phase, period and amplitude")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
                wrapMode: Text.WordWrap
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 200
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

                        const mid = height / 2;
                        const half = height / 2 - 6;

                        const stroke = (f, amplitude, per, shift, colour, dash) => {
                            ctx.beginPath();
                            for (let i = 0; i <= 160; i++) {
                                const x = i / 160;
                                const v = root.waveAt(f, x, amplitude, per, shift);
                                const px = x * width;
                                const py = mid - v * half;
                                if (i === 0)
                                    ctx.moveTo(px, py);
                                else
                                    ctx.lineTo(px, py);
                            }
                            ctx.strokeStyle = colour;
                            ctx.lineWidth = 2;
                            ctx.setLineDash(dash);
                            ctx.stroke();
                        };

                        ctx.setLineDash([5, 5]);
                        stroke(root.targetForm, root.targetAmp, root.targetPeriod, root.targetPhase, Qt.alpha(Colours.palette.m3onSurfaceVariant, 0.75), [5, 5]);
                        stroke(root.form, root.amp, root.period, root.phase, Colours.palette.m3primary, []);
                        ctx.setLineDash([]);
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                Repeater {
                    model: root.forms

                    IconTextButton {
                        required property string modelData

                        Layout.fillWidth: true
                        text: root.formLabel(modelData)
                        type: root.form === modelData ? IconTextButton.Filled : IconTextButton.Text
                        onClicked: {
                            root.form = modelData;
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
                    id: ampSlider

                    Layout.fillWidth: true
                    from: 0.2
                    to: 1
                    stepSize: 0.01
                    value: root.amp
                    onInteraction: v => root.amp = Math.round((from + v * (to - from)) * 100) / 100
                    onReleased: v => root.amp = Math.round((from + v * (to - from)) * 100) / 100
                }

                StyledText {
                    Layout.preferredWidth: 46
                    horizontalAlignment: Text.AlignRight
                    text: Math.round(root.amp * 100) + "%"
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
                    id: periodSlider

                    Layout.fillWidth: true
                    from: 0.35
                    to: 1.6
                    stepSize: 0.005
                    value: root.period
                    onInteraction: v => root.period = Math.round((from + v * (to - from)) * 200) / 200
                    onReleased: v => root.period = Math.round((from + v * (to - from)) * 200) / 200
                }

                StyledText {
                    Layout.preferredWidth: 46
                    horizontalAlignment: Text.AlignRight
                    text: root.period.toFixed(2)
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
                    id: phaseSlider

                    Layout.fillWidth: true
                    from: 0
                    to: 360
                    stepSize: 0.5
                    value: root.phase * 180 / Math.PI
                    onInteraction: v => root.phase = Math.round(v * 360) * Math.PI / 180
                    onReleased: v => root.phase = Math.round(v * 360) * Math.PI / 180
                }

                StyledText {
                    Layout.preferredWidth: 46
                    horizontalAlignment: Text.AlignRight
                    text: Math.round(phaseSlider.value) + "°"
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

                Item {
                    Layout.fillWidth: true
                }

                StyledText {
                    text: Tr.tr("Resonance × %1").arg(root.cleared)
                    font: Tokens.font.label.large
                }
            }
        }
    }
}
