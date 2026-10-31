pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Aether.Config
import Aether.I18n
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.modules.nexus.common

// A row that opens a searchable list of every installed font. Kept separate from SelectRow
// because a menu with hundreds of MenuItems is both slow and impossible to search.
DialogRowButton {
    id: root

    required property string labelPrefix
    required property string current
    required property var families

    property string dialogTitle: Tr.tr("Choose a font")
    property string pending
    property string query

    signal fontChosen(string family)

    icon: "font_download"
    label: root.labelPrefix
    subtext: root.current
    header: root.dialogTitle
    acceptLabel: Tr.tr("Use")

    onOpenChanged: {
        if (open) {
            pending = current;
            query = "";
        }
    }

    onAccepted: {
        if (pending)
            root.fontChosen(pending);
    }

    content: Component {
        ColumnLayout {
            anchors.fill: parent
            spacing: Tokens.spacing.small

            StyledTextField {
                id: search

                Layout.fillWidth: true
                placeholderText: Tr.tr("Search fonts")
                Component.onCompleted: forceActiveFocus()
                onTextChanged: root.query = text
            }

            VerticalFadeListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                topMargin: Tokens.padding.small
                bottomMargin: Tokens.padding.small

                model: {
                    const query = root.query.trim().toLowerCase();
                    const all = root.families ?? [];
                    return query ? all.filter(f => f.toLowerCase().includes(query)) : all;
                }

                delegate: StyledRect {
                    id: row

                    required property string modelData

                    anchors.left: ListView.view.contentItem.left
                    anchors.right: ListView.view.contentItem.right
                    implicitHeight: rowLayout.implicitHeight + Tokens.padding.small * 2
                    radius: root.pending === modelData ? Tokens.rounding.large : Tokens.rounding.extraSmall
                    color: root.pending === modelData ? Qt.alpha(Colours.palette.m3tertiaryContainer, 1) : "transparent"

                    Behavior on radius {
                        Anim {
                            type: Anim.SlowEffects
                        }
                    }

                    StateLayer {
                        onClicked: root.pending = row.modelData
                    }

                    RowLayout {
                        id: rowLayout

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: Tokens.padding.medium
                        anchors.rightMargin: Tokens.padding.medium
                        spacing: Tokens.spacing.medium

                        StyledText {
                            Layout.fillWidth: true
                            text: row.modelData
                            font: Qt.font({
                                family: row.modelData,
                                pixelSize: 14
                            })
                            elide: Text.ElideRight
                        }

                        StyledText {
                            text: "Aa 123"
                            color: Colours.palette.m3outline
                            font: Qt.font({
                                family: row.modelData,
                                pixelSize: 14
                            })
                        }
                    }
                }
            }
        }
    }
}
