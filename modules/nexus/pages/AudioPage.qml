pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    // Ordered to match config::HybridVariant (Midnight, Op)
    readonly property list<MenuItem> variantItems: [
        MenuItem {
            text: "MiDnight"
        },
        MenuItem {
            text: "OP"
        }
    ]

    function addApp() {
        let appName = silenceAppInput.text.trim();
        if (appName !== "") {
            let list = Array.from(GlobalConfig.audio.sounds.disabledNotifApps);
            if (!list.includes(appName)) {
                list.push(appName);
                GlobalConfig.audio.sounds.disabledNotifApps = list;
            }
            silenceAppInput.text = "";
        }
    }

    title: Tr.tr("Audio")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter

        anchors.top: parent.top

        width: root.cappedWidth

        spacing: Tokens.spacing.extraSmall / 2

        // Output
        SliderRow {
            first: true
            icon: Icons.getVolumeIcon(Audio.volume, Audio.muted)
            label: Tr.trCtx("Output", "audio output")
            valueLabel: Strings.percentOne(value)
            value: Audio.volume
            enabled: !Audio.muted
            onMoved: v => Audio.setVolume(v)
            onReleased: v => Audio.playEffectTick()
        }

        ToggleRow {
            text: Tr.trCtx("Muted", "audio output muted")

            checked: Audio.muted

            onToggled: Audio.setStreamMuted(Audio.sink, checked)
        }

        AudioDeviceList {
            nodes: Audio.sinks

            currentId: Audio.sink?.id ?? -1

            iconName: "speaker"

            placeholderIcon: "speaker"

            placeholderText: Tr.trCtx("No output devices", "no audio outputs")

            onSelected: node => Audio.setAudioSink(node)
        }

        // Combined Audio Output (Multi-Output)
        ToggleRow {
            Layout.topMargin: Tokens.spacing.medium
            first: true
            last: !Audio.combinedSinkEnabled
            text: Tr.tr("Combined Audio Output")
            subtext: Tr.tr("Simultaneous playback across multiple devices")
            checked: Audio.combinedSinkEnabled
            onToggled: Audio.setCombinedSinkEnabled(checked)
        }

        ColumnLayout {
            Layout.fillWidth: true

            visible: Audio.combinedSinkEnabled

            spacing: Tokens.spacing.extraSmall / 2

            Repeater {
                id: memberRepeater

                model: Audio.sinks.filter(s => s && s.name !== Audio.combinedModuleName)

                delegate: ConnectedRect {
                    id: memberCard

                    required property PwNode modelData

                    required property int index

                    readonly property bool isSelected: Audio.combinedSinkMembers.includes(memberCard.modelData.name)

                    readonly property real curVolume: memberCard.modelData?.audio?.volume ?? 1.0

                    Layout.fillWidth: true

                    first: false

                    last: index === (memberRepeater.count - 1)

                    implicitHeight: cardLayout.implicitHeight + cardLayout.anchors.margins * 2

                    ColumnLayout {
                        id: cardLayout

                        anchors.fill: parent

                        anchors.margins: Tokens.padding.medium

                        anchors.leftMargin: Tokens.padding.largeIncreased

                        anchors.rightMargin: Tokens.padding.largeIncreased

                        spacing: Tokens.spacing.small

                        RowLayout {
                            Layout.fillWidth: true

                            spacing: Tokens.spacing.medium

                            MaterialIcon {
                                text: memberCard.modelData.properties["device.api"] === "bluez5" ? "headphones" : "speaker"

                                color: memberCard.isSelected ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant

                                fontStyle: Tokens.font.icon.medium
                            }

                            ColumnLayout {
                                Layout.fillWidth: true

                                spacing: 0

                                StyledText {
                                    Layout.fillWidth: true

                                    text: memberCard.modelData.description || memberCard.modelData.name

                                    font: Tokens.font.body.small

                                    elide: Text.ElideRight
                                }

                                StyledText {
                                    Layout.fillWidth: true

                                    text: memberCard.isSelected ? Tr.tr("Trim: %1").arg(Strings.percentOne(memberCard.curVolume)) : Tr.tr("Not included")

                                    color: Colours.palette.m3outline

                                    font: Tokens.font.label.small
                                }
                            }

                            StyledSwitch {
                                checked: memberCard.isSelected

                                onToggled: Audio.toggleCombinedSinkMember(memberCard.modelData.name)
                            }
                        }

                        // Gain trim slider (visible only when included in combined sink)
                        RowLayout {
                            Layout.fillWidth: true

                            visible: memberCard.isSelected

                            spacing: Tokens.spacing.medium

                            MaterialIcon {
                                text: Icons.getVolumeIcon(memberCard.curVolume, memberCard.modelData?.audio?.muted ?? false)

                                color: Colours.palette.m3outline

                                fontStyle: Tokens.font.icon.small
                            }

                            CustomMouseArea {
                                function onWheel(event: WheelEvent): void {
                                    const step = GlobalConfig.services.audioIncrement;
                                    if (event.angleDelta.y > 0)
                                        Audio.setSinkTrimVolume(memberCard.modelData, Math.min(1.5, memberCard.curVolume + step));
                                    else if (event.angleDelta.y < 0)
                                        Audio.setSinkTrimVolume(memberCard.modelData, Math.max(0, memberCard.curVolume - step));
                                }

                                Layout.fillWidth: true

                                implicitHeight: Tokens.padding.medium * 2

                                StyledSlider {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    implicitHeight: parent.implicitHeight

                                    radius: Tokens.rounding.small
                                    value: memberCard.curVolume
                                    onInteraction: v => Audio.setSinkTrimVolume(memberCard.modelData, v)
                                }
                            }
                        }
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true

                Layout.leftMargin: Tokens.padding.largeIncreased

                Layout.topMargin: Tokens.spacing.extraSmall

                visible: Audio.combinedSinkMembers.length < 2

                text: Tr.tr("Select at least 2 outputs to activate simultaneous playback.")

                color: Colours.palette.m3error

                font: Tokens.font.body.small
            }
        }

        // Input
        SliderRow {
            Layout.topMargin: Tokens.spacing.large - parent.spacing
            first: true
            icon: Icons.getMicVolumeIcon(Audio.sourceVolume, Audio.sourceMuted)
            label: Tr.trCtx("Input", "audio input")
            valueLabel: Strings.percentOne(value)
            value: Audio.sourceVolume
            enabled: !Audio.sourceMuted
            onMoved: v => Audio.setSourceVolume(v)
            onReleased: v => Audio.playEffectTick()
        }

        ToggleRow {
            text: Tr.trCtx("Muted", "audio input muted")

            checked: Audio.sourceMuted

            onToggled: Audio.setStreamMuted(Audio.source, checked)
        }

        AudioDeviceList {
            nodes: Audio.sources

            currentId: Audio.source?.id ?? -1

            iconName: "mic"

            placeholderIcon: "mic_off"

            placeholderText: Tr.trCtx("No input devices", "no audio inputs")

            onSelected: node => Audio.setAudioSource(node)
        }

        // Per-app routing & volumes
        NavRow {
            Layout.topMargin: Tokens.spacing.large - parent.spacing
            first: true
            last: true

            icon: "tune"
            text: Tr.tr("App routing & volumes")
            subtext: Audio.streams.length === 0 ? Tr.tr("No apps playing audio") : Tr.trN("%n app playing audio", "%n apps playing audio", Audio.streams.length)
            onClicked: root.nState.openSubPage(1)
        }

        // Sound effects
        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.large - parent.spacing
            text: Tr.tr("Sound effects")
            font: Tokens.font.body.small
            color: Colours.palette.m3primary
        }

        ToggleRow {
            Layout.fillWidth: true

            first: true

            text: Tr.tr("Enable sound effects")

            checked: GlobalConfig.audio.sounds.enabled

            onToggled: GlobalConfig.audio.sounds.enabled = checked
        }

        SliderRow {
            Layout.fillWidth: true

            icon: "volume_up"

            label: Tr.tr("SFX Volume")

            valueLabel: Math.round(value * 100) + "%"

            value: GlobalConfig.audio.sounds.sfxVolume

            enabled: GlobalConfig.audio.sounds.enabled

            onMoved: v => GlobalConfig.audio.sounds.sfxVolume = v

            onReleased: v => Audio.playEffectTick()
        }

        SliderRow {
            Layout.fillWidth: true

            icon: "notifications"

            label: Tr.tr("Notification Volume")

            valueLabel: Math.round(value * 100) + "%"

            value: GlobalConfig.audio.sounds.notificationVolume

            enabled: GlobalConfig.audio.sounds.enabled

            onMoved: v => GlobalConfig.audio.sounds.notificationVolume = v

            onReleased: v => Audio.playNotification()
        }

        ToggleRow {
            Layout.fillWidth: true

            text: Tr.tr("Camera click")

            checked: GlobalConfig.audio.sounds.cameraClick

            enabled: GlobalConfig.audio.sounds.enabled

            onToggled: GlobalConfig.audio.sounds.cameraClick = checked
        }

        ToggleRow {
            Layout.fillWidth: true

            text: Tr.tr("Charging started")

            checked: GlobalConfig.audio.sounds.chargingStarted

            enabled: GlobalConfig.audio.sounds.enabled

            onToggled: GlobalConfig.audio.sounds.chargingStarted = checked
        }

        ToggleRow {
            Layout.fillWidth: true

            text: Tr.tr("Volume tick")

            checked: GlobalConfig.audio.sounds.effectTick

            enabled: GlobalConfig.audio.sounds.enabled

            onToggled: GlobalConfig.audio.sounds.effectTick = checked
        }

        ToggleRow {
            Layout.fillWidth: true

            text: Tr.tr("Screen lock")

            checked: GlobalConfig.audio.sounds.lock

            enabled: GlobalConfig.audio.sounds.enabled

            onToggled: GlobalConfig.audio.sounds.lock = checked
        }

        ToggleRow {
            Layout.fillWidth: true

            text: Tr.tr("Screen unlock")

            checked: GlobalConfig.audio.sounds.unlock

            enabled: GlobalConfig.audio.sounds.enabled

            onToggled: GlobalConfig.audio.sounds.unlock = checked
        }

        ToggleRow {
            Layout.fillWidth: true

            text: Tr.tr("Low battery")

            checked: GlobalConfig.audio.sounds.lowBattery

            enabled: GlobalConfig.audio.sounds.enabled

            onToggled: GlobalConfig.audio.sounds.lowBattery = checked
        }

        ToggleRow {
            Layout.fillWidth: true

            last: true

            text: Tr.tr("Screen record")

            checked: GlobalConfig.audio.sounds.screenRecord

            enabled: GlobalConfig.audio.sounds.enabled

            onToggled: GlobalConfig.audio.sounds.screenRecord = checked
        }

        // Notification Silencing
        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.large - parent.spacing
            text: Tr.tr("Notification silencing")
            font: Tokens.font.body.small
            color: Colours.palette.m3primary
        }

        StyledText {
            Layout.fillWidth: true

            Layout.leftMargin: Tokens.padding.small

            Layout.bottomMargin: Tokens.spacing.medium

            text: Tr.tr("Mute notification sounds for specific apps")

            color: Colours.palette.m3outline

            font: Tokens.font.body.small

            wrapMode: Text.WordWrap
        }

        RowLayout {
            Layout.fillWidth: true

            spacing: Tokens.spacing.small

            StyledTextField {
                id: silenceAppInput

                Layout.fillWidth: true

                onEditingFinished: root.addApp()
            }

            IconTextButton {
                text: Tr.tr("Add")

                icon: "add"

                onClicked: root.addApp()
            }
        }

        Flow {
            Layout.fillWidth: true

            spacing: Tokens.spacing.small

            Repeater {
                model: GlobalConfig.audio.sounds.disabledNotifApps

                delegate: StyledRect {
                    id: chip

                    required property string modelData

                    required property int index

                    width: implicitWidth

                    height: implicitHeight

                    color: Colours.layer(Colours.palette.m3surfaceContainer, 2)

                    radius: Tokens.rounding.large

                    implicitWidth: chipLayout.implicitWidth + Tokens.padding.medium * 2

                    implicitHeight: chipLayout.implicitHeight + Tokens.padding.extraSmall * 2

                    RowLayout {
                        id: chipLayout

                        x: Tokens.padding.medium

                        y: Tokens.padding.extraSmall

                        spacing: Tokens.spacing.extraSmall

                        StyledText {
                            text: chip.modelData
                        }

                        MaterialIcon {
                            text: "close"

                            font: Tokens.font.icon.small

                            StateLayer {
                                onClicked: {
                                    let list = Array.from(GlobalConfig.audio.sounds.disabledNotifApps);
                                    list.splice(chip.index, 1);
                                    GlobalConfig.audio.sounds.disabledNotifApps = list;
                                }
                            }
                        }
                    }
                }
            }
        }

        SectionHeader {
            text: Tr.tr("Bar popout")
        }

        SelectRow {
            first: true
            last: true
            label: Tr.tr("Audio popout")
            subtext: Tr.tr("Which fork's audio panel the bar opens")
            configNode: GlobalConfig.hybrid.variants
            propertyName: "audioPopout"
            menuItems: root.variantItems
            active: root.variantItems[GlobalConfig.hybrid.variants.audioPopout === HybridVariant.Op ? 1 : 0]
            onSelected: item => {
                GlobalConfig.hybrid.variants.audioPopout = root.variantItems.indexOf(item) === 1 ? HybridVariant.Op : HybridVariant.Midnight;
            }
        }
    }
}
