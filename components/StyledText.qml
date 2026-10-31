pragma ComponentBehavior: Bound

import QtQuick
import Aether.Config
import qs.services

Text {
    id: root

    property bool animate: false

    // Native-rendered glyphs snap to the pixel grid while they are scaled or rotated, which
    // reads as pixel jitter. Rasterise once into a layer for the duration of the transform.
    layer.enabled: root.scale !== 1 || root.rotation !== 0
    layer.smooth: true

    renderType: Text.NativeRendering
    textFormat: Text.PlainText
    color: Colours.palette.m3onSurface
    font: Tokens.font.body.small

    Behavior on color {
        CAnim {}
    }

    Behavior on text {
        enabled: root.animate

        SequentialAnimation {
            Anim {
                target: root
                property: "opacity"
                to: 0
                type: Anim.FastEffects
            }
            PropertyAction {}
            Anim {
                target: root
                property: "opacity"
                to: 1
                type: Anim.DefaultEffects
            }
        }
    }
}
