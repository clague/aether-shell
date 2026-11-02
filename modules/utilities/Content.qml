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
                    const swipeItem = mediaViewport.currentItem ? mediaViewport.currentItem.item : null; // qmllint disable missing-property
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
                }

                spacing: Tokens.spacing.small

                Component.onCompleted: showPendingPage()

                onCurrentIndexChanged: {
                    animEnabled = true;
                    animDisableTimer.restart();
                }

                onNonAnimHeightChanged: {
                    const swipeItem = mediaViewport.currentItem ? mediaViewport.currentItem.item : null; // qmllint disable missing-property
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

                Item {
                    id: mediaViewport

                    readonly property Item currentItem: {
                        mediaRepeater.count; // qmllint disable confusing-expression-statement
                        mediaRepeater.dummy; // qmllint disable confusing-expression-statement
                        return mediaRepeater.itemAt(mediaLayout.currentIndex);
                    }

                    // One page is one viewport wide, so page i sits at i * (width + spacing).
                    // The position is derived from the index, never from the item's own x: on
                    // the frame a page is added the Row has not laid it out yet, and x is 0.
                    readonly property real pageStride: width + mediaRow.spacing

                    property real lastValidImplicitHeight: 0

                    // A wheel over a list that can itself scroll belongs to that list. Handlers
                    // are offered the event before the item under the cursor, so without this
                    // check the pager would steal scrolling from a long transfer or recording
                    // list instead of merely being unable to page past the first item.
                    function overScrollable(pos: point): bool {
                        let item = childAt(pos.x, pos.y);
                        while (item && item !== mediaViewport) {
                            // Only Flickable-derived items carry contentHeight; anything else
                            // reads as undefined and is skipped.
                            if (item.contentHeight !== undefined && item.contentHeight > item.height) // qmllint disable missing-property
                                return true;
                            item = item.parent;
                        }
                        return false;
                    }

                    Layout.fillWidth: true
                    clip: true
                    implicitHeight: currentItem ? currentItem.implicitHeight : lastValidImplicitHeight

                    onImplicitHeightChanged: {
                        if (currentItem)
                            lastValidImplicitHeight = currentItem.implicitHeight;
                    }

                    // Desktop paging is a wheel step, not a drag: one notch per page. A notch
                    // is 120, a touchpad sends less per event, so accumulate rather than
                    // switching on every event -- and only consume it when there is a page to
                    // reach, so a single-card panel still scrolls its parent.
                    WheelHandler {
                        property real accumulated: 0

                        enabled: mediaRepeater.count > 1

                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad

                        onWheel: event => {
                            const delta = Math.abs(event.angleDelta.x) > Math.abs(event.angleDelta.y) ? event.angleDelta.x : event.angleDelta.y;
                            // event.x/y are the wheel position in this item's coordinates.
                            if (delta === 0 || mediaViewport.overScrollable(Qt.point(event.x, event.y)))
                                return;

                            accumulated += delta;
                            const steps = Math.trunc(accumulated / 120);
                            if (steps === 0)
                                return;

                            accumulated -= steps * 120;
                            event.accepted = true;
                            // Wheel up (positive delta) moves towards the first page.
                            mediaLayout.currentIndex = Math.max(0, Math.min(mediaLayout.currentIndex - steps, mediaRepeater.count - 1));
                        }
                    }

                    Row {
                        id: mediaRow

                        spacing: Tokens.spacing.medium
                        x: -mediaLayout.currentIndex * mediaViewport.pageStride

                        Behavior on x {
                            Anim {}
                        }

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

                                width: mediaViewport.width
                            }
                        }
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

                            Item {
                                id: dot

                                required property int index

                                width: Tokens.spacing.medium
                                height: Tokens.spacing.small

                                StyledRect {
                                    anchors.fill: parent
                                    radius: Tokens.rounding.full
                                    color: Colours.palette.m3surfaceVariant
                                }

                                MouseArea {
                                    // The dot is a few pixels wide, so the hit area is padded
                                    // outwards by half the gap: neighbouring areas then meet
                                    // exactly. Padding by the whole gap made them overlap, and
                                    // the later dot won the shared strip, so the earlier dot's
                                    // live area looked shifted left.
                                    anchors.fill: parent
                                    anchors.margins: -Tokens.spacing.small / 2
                                    cursorShape: Qt.PointingHandCursor

                                    onClicked: mediaLayout.currentIndex = dot.index
                                }
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
