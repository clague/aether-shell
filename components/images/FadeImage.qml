import QtQuick
import Quickshell
import qs.components

Image {
    id: root

    property bool hadPrevious
    property bool fadingOut
    property bool preventInit
    property int fadeOutAnim: Anim.FastEffects
    property int fadeInAnim: Anim.DefaultEffects
    property int fadeInLargeAnim: Anim.StandardLarge

    function maybeStartInAnim(): void {
        if (!preventInit && !opacityInAnim.running && status === Image.Ready) {
            opacityInAnim.type = hadPrevious ? fadeInAnim : fadeInLargeAnim;
            opacityInAnim.start();
        }
    }

    asynchronous: true
    fillMode: Image.PreserveAspectCrop

    sourceSize: {
        const dpr = (QsWindow.window as QsWindow)?.devicePixelRatio ?? 1;
        // 0x0 means "no constraint" to Qt, i.e. decode the file at full resolution. Before
        // layout that is what a width of 0 turned into, so clamp to one pixel: the image is
        // replaced as soon as the item has a size.
        return Qt.size(Math.max(1, width * dpr), Math.max(1, height * dpr));
    }

    retainWhileLoading: true
    opacity: 0

    onStatusChanged: maybeStartInAnim()
    onPreventInitChanged: maybeStartInAnim()

    Anim on opacity {
        id: opacityInAnim

        running: false
        to: 1
    }

    Behavior on source {
        SequentialAnimation {
            ScriptAction {
                script: opacityInAnim.stop()
            }
            PropertyAction {
                target: root
                property: "fadingOut"
                value: true
            }
            Anim {
                target: root
                property: "opacity"
                to: 0
                type: root.fadeOutAnim
            }
            PropertyAction {
                target: root
                property: "fadingOut"
                value: false
            }
            PropertyAction {
                target: root
                property: "hadPrevious"
                value: root.source
            }
            PropertyAction {}
            ScriptAction {
                script: root.maybeStartInAnim()
            }
        }
    }
}
