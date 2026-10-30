import QtQuick
import QtQuick.Layouts
import Aether.Config
import Aether.I18n
import qs.components.controls
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property list<MenuItem> positionItems: [
        MenuItem {
            text: Tr.tr("Top left")
        },
        MenuItem {
            text: Tr.tr("Top center")
        },
        MenuItem {
            text: Tr.tr("Top right")
        },
        MenuItem {
            text: Tr.tr("Middle left")
        },
        MenuItem {
            text: Tr.tr("Middle center")
        },
        MenuItem {
            text: Tr.tr("Middle right")
        },
        MenuItem {
            text: Tr.tr("Bottom left")
        },
        MenuItem {
            text: Tr.tr("Bottom center")
        },
        MenuItem {
            text: Tr.tr("Bottom right")
        }
    ]

    function getPositionIndex(): int {
        const p = GlobalConfig.services.pipPosition.toLowerCase();
        if (p.includes("top")) {
            if (p.includes("left"))
                return 0;
            if (p.includes("center"))
                return 1;
            return 2;
        } else if (p.includes("middle")) {
            if (p.includes("left"))
                return 3;
            if (p.includes("center"))
                return 4;
            return 5;
        } else {
            if (p.includes("left"))
                return 6;
            if (p.includes("center"))
                return 7;
            return 8;
        }
    }

    title: Tr.tr("Picture in Picture")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("Behavior")
        }

        SelectRow {
            first: true
            label: Tr.tr("Position")
            subtext: Tr.tr("Anchor quadrant for Picture in Picture windows")
            configNode: root.targetConfig.services
            propertyName: "pipPosition"
            menuItems: root.positionItems
            active: root.positionItems[root.getPositionIndex()]
            onSelected: item => {
                root.targetConfig.services.pipPosition = item.text.toLowerCase();
            }
        }

        ToggleRow {
            Layout.fillWidth: true
            last: true
            text: Tr.tr("Follow active focus")
            subtext: Tr.tr("Automatically warp PiP to the active monitor and workspace")
            configNode: root.targetConfig.services
            propertyName: "pipFollowFocus"
            checked: root.targetConfig.services.pipFollowFocus
            onToggled: {
                root.targetConfig.services.pipFollowFocus = checked;
            }
        }
    }
}
