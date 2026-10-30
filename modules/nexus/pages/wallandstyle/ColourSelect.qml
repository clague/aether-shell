import QtQuick
import QtQuick.Layouts
import Quickshell
import Aether.Config
import Aether.I18n
import qs.components.controls
import qs.services
import qs.modules.launcher.services
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property list<var> variantData: [
        {
            name: "vibrant",
            label: Tr.tr("Vibrant")
        },
        {
            name: "tonalspot",
            label: Tr.tr("Tonal Spot")
        },
        {
            name: "expressive",
            label: Tr.tr("Expressive")
        },
        {
            name: "fidelity",
            label: Tr.tr("Fidelity")
        },
        {
            name: "content",
            label: Tr.tr("Content")
        },
        {
            name: "fruitsalad",
            label: Tr.tr("Fruit Salad")
        },
        {
            name: "rainbow",
            label: Tr.tr("Rainbow")
        },
        {
            name: "neutral",
            label: Tr.tr("Neutral")
        },
        {
            name: "monochrome",
            label: Tr.tr("Monochrome")
        }
    ]

    title: Tr.tr("Colours")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        Variants {
            id: schemeItems

            model: Schemes.list

            MenuItem {
                required property var modelData

                text: `${modelData.name} ${modelData.flavour}`
                onClicked: {
                    Quickshell.execDetached(["caelestia", "scheme", "set", "-n", modelData.name, "-f", modelData.flavour]);
                }
            }
        }

        Variants {
            id: variantItems

            model: root.variantData

            MenuItem {
                required property var modelData

                text: modelData.label
                onClicked: {
                    Quickshell.execDetached(["caelestia", "scheme", "set", "-v", modelData.name]);
                }
            }
        }

        SectionHeader {
            first: true
            text: Tr.tr("General")
        }

        ToggleRow {
            first: true
            last: true
            Layout.fillWidth: true
            text: Tr.tr("Smart colour scheme")
            subtext: Tr.tr("Derive theme mode and variant from the wallpaper")
            checked: GlobalConfig.services.smartScheme
            onToggled: GlobalConfig.services.smartScheme = checked
        }

        SectionHeader {
            text: Tr.tr("Scheme Settings")
        }

        SelectRow {
            first: true
            label: Tr.tr("Colour Scheme")
            subtext: Tr.tr("Select your base colour scheme style")
            menuItems: schemeItems.instances
            active: {
                const current = Colours.scheme + " " + Colours.flavour;
                const list = menuItems;
                for (let i = 0; i < list.length; i++) {
                    if (list[i].text === current)
                        return list[i];
                }
                return null;
            }
            fallbackText: Colours.scheme + " " + Colours.flavour
        }

        SelectRow {
            last: true
            label: Tr.tr("Scheme Variant")
            subtext: Tr.tr("Select the color distribution algorithm")
            menuItems: variantItems.instances
            active: {
                const current = Colours.variant;
                let match = null;
                for (let i = 0; i < root.variantData.length; i++) {
                    if (root.variantData[i].name === current) {
                        match = root.variantData[i];
                        break;
                    }
                }
                if (!match)
                    return null;
                const list = menuItems;
                for (let i = 0; i < list.length; i++) {
                    if (list[i].text === match.label)
                        return list[i];
                }
                return null;
            }
            fallbackText: Colours.variant
        }
    }
}
