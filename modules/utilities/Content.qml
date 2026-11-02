pragma ComponentBehavior: Bound

import "cards"
import QtQuick
import QtQuick.Layouts
import Aether.Config
import qs.components
import qs.services
import qs.modules.bar.popouts as BarPopouts

Item {
    id: root

    required property var props
    required property ScreenState screenState
    required property BarPopouts.Wrapper popouts
    required property matrix4x4 deformMatrix

    readonly property bool mediaActive: Config.utilities.cards.recorder || QuickShare.isEnabled

    // Enabling QuickShare should reveal its page in the media area; previously it was added
    // next to the recorder page and the user had to swipe to it.
    property string pendingMediaPage: ""

    readonly property int enabledCards: (idleInhibit.active ? 1 : 0) + (mediaActive ? 1 : 0) + (toggles.active ? 1 : 0)

    // Calculate nonAnimHeight
    // For mediaLoader, we take the nonAnimHeight of the active SwipeView page, or its implicitHeight, plus the indicator height
    readonly property real nonAnimHeight: {
        let h = 0;
        if (idleInhibit.active)
            h += (idleInhibit.item as IdleInhibit)?.nonAnimHeight ?? 0;
        if (toggles.active)
            h += (toggles.item as Toggles)?.implicitHeight ?? 0;
        if (mediaActive && mediaLoader.item) {
            h += mediaLoader.item.nonAnimHeight; // qmllint disable missing-property
        }
        h += layout.spacing * Math.max(0, enabledCards - 1);
        return h;
    }

    implicitHeight: layout.implicitHeight

    Connections {
        function onIsEnabledChanged(): void {
            if (QuickShare.isEnabled)
                root.pendingMediaPage = "quickShare";
        }

        target: QuickShare
    }

    ColumnLayout {
        id: layout

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Tokens.spacing.medium

        Loader {
            id: idleInhibit

            Layout.fillWidth: true
            active: Config.utilities.cards.keepAwake
            visible: active

            sourceComponent: IdleInhibit {
                objectName: "utilitiesKeepAwake"
            }
        }

        Loader {
            id: mediaLoader

            Layout.fillWidth: true
            active: root.mediaActive
            visible: active
            z: 1

            sourceComponent: ColumnLayout {
                id: mediaLayout

                property int currentIndex: 0

                property bool animEnabled: false

                property real lastValidItemHeight: 0

                property real nonAnimHeight: {
                    const swipeItem = mediaFlickable.currentItem ? mediaFlickable.currentItem.item : null; // qmllint disable missing-property
                    const itemHeight = swipeItem ? (swipeItem.nonAnimHeight ?? swipeItem.implicitHeight) : lastValidItemHeight;
                    return itemHeight + (mediaRepeater.count > 1 ? bgRow.implicitHeight + spacing : 0);
                }

                function showPendingPage(): void {
                    if (!root.pendingMediaPage)
                        return;
                    const pages = mediaRepeater.model ?? [];
                    const index = pages.indexOf(root.pendingMediaPage);
                    if (index < 0)
                        return;
                    currentIndex = index;
                    root.pendingMediaPage = "";
                    mediaFlickable.snapToCurrent();
                }

                spacing: Tokens.spacing.small

                Component.onCompleted: showPendingPage()

                onCurrentIndexChanged: {
                    animEnabled = true;
                    animDisableTimer.restart();
                    mediaFlickable.snapToCurrent();
                }

                onNonAnimHeightChanged: {
                    const swipeItem = mediaFlickable.currentItem ? mediaFlickable.currentItem.item : null; // qmllint disable missing-property
                    if (swipeItem) {
                        lastValidItemHeight = (swipeItem.nonAnimHeight ?? swipeItem.implicitHeight);
                    }
                }

                Connections {
                    function onPendingMediaPageChanged(): void {
                        mediaLayout.showPendingPage();
                    }

                    target: root
                }

                Connections {
                    function onCountChanged(): void {
                        mediaLayout.currentIndex = Math.min(mediaLayout.currentIndex, mediaRepeater.count - 1);
                        mediaLayout.showPendingPage();
                        mediaFlickable.snapToCurrent();
                    }

                    target: mediaRepeater
                }

                Timer {
                    id: animDisableTimer

                    interval: 400
                    onTriggered: mediaLayout.animEnabled = false
                }

                Behavior on nonAnimHeight {
                    enabled: mediaLayout.animEnabled

                    Anim {}
                }

                Flickable {
                    id: mediaFlickable

                    readonly property Item currentItem: {
                        mediaRepeater.count; // qmllint disable confusing-expression-statement
                        mediaRepeater.dummy; // qmllint disable confusing-expression-statement
                        return mediaRepeater.itemAt(mediaLayout.currentIndex);
                    }

                    // Every page is exactly one viewport wide, so page i starts at
                    // i * (width + spacing). Deriving the offset from the index matters: on
                    // the frame a page is added the Row has not laid it out yet, so item.x is
                    // still 0 and snapping to it does nothing.
                    readonly property real pageStride: width + mediaRow.spacing

                    property real lastValidImplicitHeight: 0

                    // A drag replaces the contentX binding with a plain value, so every path
                    // that changes the current page has to put the binding back, or the view
                    // stays where the drag left it and the new page is only reachable by
                    // dragging again.
                    function snapToCurrent(): void {
                        contentX = Qt.binding(() => mediaLayout.currentIndex * pageStride);
                    }

                    Layout.fillWidth: true

                    clip: true
                    interactive: mediaRepeater.count > 1

                    flickableDirection: Flickable.HorizontalFlick
                    implicitHeight: currentItem ? currentItem.implicitHeight : lastValidImplicitHeight

                    onImplicitHeightChanged: {
                        if (currentItem)
                            lastValidImplicitHeight = currentItem.implicitHeight;
                    }

                    contentX: mediaLayout.currentIndex * pageStride
                    contentWidth: mediaRow.implicitWidth
                    contentHeight: mediaRow.implicitHeight

                    // Let the drag decide the page on release, then always snap: the flick used
                    // to keep whatever offset the gesture ended on, which left the panel between
                    // two pages.
                    onDragEnded: {
                        const offset = contentX - mediaLayout.currentIndex * pageStride;
                        if (offset > width / 10)
                            mediaLayout.currentIndex = Math.min(mediaLayout.currentIndex + 1, mediaRepeater.count - 1);
                        else if (offset < -width / 10)
                            mediaLayout.currentIndex = Math.max(mediaLayout.currentIndex - 1, 0);
                    }

                    // A release can still be followed by the flick animation, which keeps moving
                    // contentX; snapping has to wait for the movement to stop, otherwise the
                    // page ends up half-scrolled.
                    onMovementEnded: snapToCurrent()

                    onWidthChanged: snapToCurrent()

                    Row {
                        id: mediaRow

                        spacing: Tokens.spacing.medium

                        Repeater {
                            id: mediaRepeater

                            property int dummy: 0

                            onCountChanged: {
                                mediaLayout.animEnabled = true;
                                animDisableTimer.restart();
                            }

                            onItemAdded: dummy++

                            model: {
                                const pages = [];
                                if (Config.utilities.cards.recorder)
                                    pages.push("record");
                                if (QuickShare.isEnabled)
                                    pages.push("quickShare");
                                return pages;
                            }

                            Loader {
                                required property int index
                                required property string modelData

                                active: true
                                sourceComponent: modelData === "record" ? recordComp : quickShareComp

                                width: mediaFlickable.width
                            }
                        }
                    }

                    Behavior on contentX {
                        Anim {}
                    }

                    Behavior on implicitHeight {
                        enabled: mediaLayout.animEnabled

                        Anim {}
                    }
                }

                Item {
                    id: indicatorRow
                    Layout.alignment: Qt.AlignHCenter

                    implicitWidth: bgRow.implicitWidth
                    implicitHeight: mediaRepeater.count > 1 ? bgRow.implicitHeight : 0
                    opacity: mediaRepeater.count > 1 ? 1 : 0
                    visible: implicitHeight > 0

                    Behavior on implicitHeight {
                        enabled: mediaLayout.animEnabled

                        Anim {}
                    }
                    Behavior on opacity {
                        enabled: mediaLayout.animEnabled

                        Anim {}
                    }

                    Row {
                        id: bgRow

                        spacing: Tokens.spacing.small

                        Repeater {
                            model: mediaRepeater.count

                            StyledRect {
                                required property int index

                                width: Tokens.spacing.medium
                                height: Tokens.spacing.small
                                radius: Tokens.rounding.full
                                color: Colours.palette.m3surfaceVariant
                            }
                        }
                    }

                    StyledRect {
                        width: Tokens.spacing.medium
                        height: Tokens.spacing.small
                        radius: Tokens.rounding.full
                        color: Colours.palette.m3primary
                        x: mediaLayout.currentIndex * (Tokens.spacing.medium + Tokens.spacing.small)

                        Behavior on x {
                            Anim {
                                type: Anim.DefaultEffects
                            }
                        }
                    }
                }
            }
        }

        Loader {
            id: toggles

            Layout.fillWidth: true
            active: Config.utilities.cards.quickToggles
            visible: active

            sourceComponent: Toggles {
                objectName: "utilitiesQuickToggles"

                screenState: root.screenState
                popouts: root.popouts
            }
        }
    }

    Component {
        id: recordComp

        Record {
            objectName: "utilitiesScreenRecorder"
            props: root.props
            screenState: root.screenState
        }
    }

    Component {
        id: quickShareComp

        QuickShareList {
            objectName: "utilitiesQuickShare"
            props: root.props
            screenState: root.screenState
        }
    }

    RecordingDeleteModal {
        props: root.props
        deformMatrix: root.deformMatrix
    }

    QuickShareDeleteModal {
        props: root.props
        deformMatrix: root.deformMatrix
    }

    QuickShareDeviceSelector {
        props: root.props
        deformMatrix: root.deformMatrix
    }
}
