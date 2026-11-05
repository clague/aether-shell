import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Aether
import Aether.Config
import Aether.I18n
import qs.components
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    // Plugin support is not wired up yet; always 0 for now
    readonly property int pluginCount: 0

    property string quickshellVersion

    // CUtils.version is a SemVer string: `2.5.0` at a release tag, or
    // `2.6.0-dev.978+g8867aae` for a build N commits past one. The `dev.N` counter is what
    // makes two builds comparable, so it is shown verbatim; only a plain release keeps the
    // `v` prefix the page has always used.
    readonly property string displayVersion: {
        const version = CUtils.version;
        if (!version)
            return "…";
        return /^\d+\.\d+\.\d+$/.test(version) ? `v${version}` : version;
    }

    title: Tr.tr("About")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // e.g. "Quickshell 0.3.0 (revision ...)"
        Process {
            running: true
            command: ["quickshell", "--version"]
            stdout: StdioCollector {
                onStreamFinished: root.quickshellVersion = text.trim().split(" ")[1] ?? ""
            }
        }

        // Hero
        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            implicitHeight: hero.implicitHeight + Tokens.padding.extraLarge * 2

            ColumnLayout {
                id: hero

                property int clicks: 0

                anchors.centerIn: parent
                width: parent.width - Tokens.padding.largeIncreased * 2
                spacing: Tokens.spacing.small

                AnimatedLogo {
                    id: logo

                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: implicitWidth
                    Layout.preferredHeight: implicitHeight

                    // Long-press easter egg: while held the logo charges (the A shakes and
                    // its stars orbit faster), and holding on opens the little game.
                    property real charge: 0

                    energy: charge

                    NumberAnimation {
                        id: chargeUp

                        target: logo
                        property: "charge"
                        to: 1
                        duration: 1500
                        easing.type: Easing.InQuad
                    }

                    NumberAnimation {
                        id: chargeDown

                        target: logo
                        property: "charge"
                        to: 0
                        duration: 240
                    }

                    Timer {
                        id: holdTimer

                        interval: 2100
                        onTriggered: {
                            root.nState.easterEgg = true;
                            chargeUp.stop();
                            chargeDown.restart();
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onPressed: {
                            chargeDown.stop();
                            chargeUp.restart();
                            holdTimer.restart();
                        }

                        onReleased: {
                            holdTimer.stop();
                            chargeUp.stop();
                            chargeDown.restart();
                        }

                        onCanceled: {
                            holdTimer.stop();
                            chargeUp.stop();
                            chargeDown.restart();
                        }
                    }
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: Tokens.spacing.small
                    text: "Aether"
                    font: Tokens.font.headline.builders.large.width(110).build()
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: Tokens.spacing.small
                    text: Tr.tr("MiDnight × OP-Caelestia on Caelestia")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.medium
                    opacity: 0.8
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.displayVersion
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.medium

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (GlobalConfig.general.developerMode) {
                                Toaster.toast(Tr.tr("Developer Options"), Tr.tr("No need, you are already a developer."), "construction");
                                return;
                            }

                            hero.clicks++;
                            const remaining = 7 - hero.clicks;
                            if (remaining > 0 && remaining <= 4) {
                                Toaster.toast(Tr.tr("Developer Options"), Tr.tr("You are now %1 steps away from being a developer.").arg(remaining), "construction");
                            } else if (remaining === 0) {
                                root.nState.justUnlockedDevMode = true;
                                GlobalConfig.general.developerMode = true;
                                Toaster.toast(Tr.tr("Developer Options"), Tr.tr("You are now a developer!"), "construction");
                            }
                        }
                    }
                }
            }
        }

        // System
        SectionHeader {
            text: Tr.tr("System")
        }

        InfoRow {
            first: true
            label: Tr.tr("Hostname")
            value: SysInfo.hostname
        }

        InfoRow {
            label: Tr.trCtx("Device", "system model name")
            value: SysInfo.device
        }

        InfoRow {
            label: Tr.tr("Distro")
            value: SysInfo.osPrettyName || SysInfo.osName
        }

        InfoRow {
            label: Tr.tr("Kernel")
            value: SysInfo.kernel
        }

        InfoRow {
            last: true
            // TRANSLATORS: BIOS or UEFI firmware version
            label: Tr.tr("Firmware")
            value: SysInfo.firmware
        }

        // Software
        SectionHeader {
            text: Tr.tr("Software")
        }

        InfoRow {
            first: true
            label: Tr.trCtx("Shell", "the Aether shell itself, not a unix shell")
            value: root.displayVersion
        }

        InfoRow {
            label: "Quickshell"
            value: root.quickshellVersion || "…"
        }

        InfoRow {
            last: true
            label: "Qt"
            value: CUtils.qtVersion || "…"
        }

        // Plugins
        SectionHeader {
            text: Tr.tr("Plugins")
        }

        InfoRow {
            first: true
            last: true
            label: Tr.tr("Loaded plugins")
            value: root.pluginCount.toString()
        }
    }
}
