pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Aether.Config
import qs.components
import qs.modules.bar.popouts // Need to import this module so the Wrapper type is the same as others

Item {
    id: root

    required property ShellScreen screen
    required property var bar
    required property real borderThickness
    required property ScreenState screenState

    readonly property alias content: content
    readonly property bool isHorizontal: bar.isHorizontal
    property real offsetScale: content.isDetached || content.hasCurrent ? 0 : 1

    Config.screen: screen.name

    visible: width > 0 && height > 0
    clip: true

    implicitWidth: isHorizontal ? content.implicitWidth : content.implicitWidth * (1 - offsetScale)
    implicitHeight: isHorizontal ? content.implicitHeight * (1 - offsetScale) : content.implicitHeight

    // Whole pixels on both axes: the popout inside carries a layer, and a layer is only
    // mapped 1:1 when its rectangle lands on the pixel grid (T67).
    x: {
        if (content.isDetached)
            return Math.round((parent.width - content.nonAnimWidth) / 2);
        if (isHorizontal) {
            if (content.sidebarOpen && !content.isDockPopout && content.currentSection === "end")
                return Math.round(parent.width - content.nonAnimWidth);

            const off = content.currentCenter - parent.leftMargin - content.nonAnimWidth / 2; // qmllint disable missing-property
            const diff = parent.width - Math.floor(off + content.nonAnimWidth);
            return Math.round(diff < 0 ? off + diff : Math.max(off, 0));
        }
        if (bar.position === "right")
            return Math.round(parent.width - implicitWidth);
        return 0;
    }

    y: {
        if (content.isDetached)
            return Math.round((parent.height - content.nonAnimHeight) / 2);
        if (isHorizontal) {
            if (bar.position === "bottom")
                return Math.round(parent.height - implicitHeight);
            return 0;
        }

        const off = content.currentCenter - parent.topMargin - content.nonAnimHeight / 2; // qmllint disable missing-property
        const diff = parent.height - Math.floor(off + content.nonAnimHeight);
        return Math.round(diff < 0 ? off + diff : Math.max(off, 0));
    }

    Behavior on offsetScale {
        Anim {}
    }

    Behavior on x {
        enabled: content.isDetached || root.isHorizontal

        Anim {
            duration: content.animLength
            easing: content.animCurve
        }
    }

    Behavior on y {
        enabled: content.isDetached || (!root.isHorizontal && root.offsetScale < 1)

        Anim {
            duration: content.animLength
            easing: content.animCurve
        }
    }

    Wrapper {
        id: content

        screen: root.screen
        offsetScale: root.offsetScale
        screenState: root.screenState

        // Slide this popout as one rasterised texture instead of re-rasterising its text
        // every frame; see T67.
        layer.enabled: true
        layer.smooth: true

        // A layer is only sampled 1:1 when the item is a whole number of pixels wide and
        // sits on a whole pixel. Both were fractional here -- the width comes from font
        // metrics (476.733) and the cross-axis position from a centred half pixel -- so the
        // texture was resampled even at rest, which is why the menu looked soft after the
        // animation. Round the size up (never clip a partial pixel) and place it from the
        // bar edge by whole pixels.
        width: Math.ceil(implicitWidth)
        height: Math.ceil(implicitHeight)

        x: {
            const slide = (-width - 5) * root.offsetScale;
            if (root.bar.position === "left")
                return Math.round(slide);
            if (root.bar.position === "right")
                return Math.round(root.width - width - slide);
            return Math.round((root.width - width) / 2);
        }

        y: {
            const slide = (-height - 5) * root.offsetScale;
            if (root.bar.position === "top")
                return Math.round(slide);
            if (root.bar.position === "bottom")
                return Math.round(root.height - height - slide);
            return Math.round((root.height - height) / 2);
        }
    }
}
