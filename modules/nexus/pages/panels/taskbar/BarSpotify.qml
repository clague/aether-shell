pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("Spotify")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("Configuration")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Background")
            subtext: Tr.tr("Render a solid background behind the Spotify widget")
            configNode: root.targetConfig.bar.spotify
            propertyName: "background"
            checked: root.targetConfig.bar.spotify.background
            onToggled: {
                root.targetConfig.bar.spotify.background = checked;
            }
        }

        ToggleRow {
            text: Tr.tr("Show visualizer")
            subtext: Tr.tr("Display animated frequency visualizer bars")
            configNode: root.targetConfig.bar.spotify
            propertyName: "showVisualiser"
            checked: root.targetConfig.bar.spotify.showVisualiser
            onToggled: {
                root.targetConfig.bar.spotify.showVisualiser = checked;
            }
        }

        StepperRow {
            label: Tr.tr("Max title length")
            subtext: Tr.tr("Cut off character count for track title")
            configNode: root.targetConfig.bar.spotify
            propertyName: "maxTitleLength"
            value: root.targetConfig.bar.spotify.maxTitleLength
            from: 5
            to: 100
            stepSize: 1
            onMoved: v => {
                root.targetConfig.bar.spotify.maxTitleLength = v;
            }
        }

        ToggleRow {
            text: Tr.tr("Inverted text direction")
            subtext: Tr.tr("Rotate text in the opposite direction when the bar is vertical")
            configNode: root.targetConfig.bar.spotify
            propertyName: "inverted"
            checked: root.targetConfig.bar.spotify.inverted
            onToggled: {
                root.targetConfig.bar.spotify.inverted = checked;
            }
        }

        ToggleRow {
            text: Tr.tr("Auto-hide")
            subtext: Tr.tr("Hide the widget when there is no media source available")
            configNode: root.targetConfig.bar.spotify
            propertyName: "autoHide"
            checked: root.targetConfig.bar.spotify.autoHide
            onToggled: {
                root.targetConfig.bar.spotify.autoHide = checked;
            }
        }

        ToggleRow {
            last: true
            text: Tr.tr("Horizontal volume slider")
            subtext: Tr.tr("Place a horizontal volume slider below the playback controls in the popout")
            configNode: root.targetConfig.bar.spotify
            propertyName: "horizontalVolume"
            checked: root.targetConfig.bar.spotify.horizontalVolume
            onToggled: {
                root.targetConfig.bar.spotify.horizontalVolume = checked;
            }
        }
    }
}
