import QtQuick
import QtQuick.Shapes
import qs.services

// The Aether mark: an A drawn with two strokes, an orbit passing behind it and a four-pointed
// star at the apex. Kept in the same 128-unit box as the animated version so both can share
// coordinates.
Item {
    id: root

    readonly property real designWidth: 128
    readonly property real designHeight: 128

    property color topColour: Colours.palette.m3primary
    property color bottomColour: Colours.palette.m3onSurface

    implicitWidth: designWidth
    implicitHeight: designHeight

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        rotation: -14

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.topColour
            strokeWidth: 2

            PathAngleArc {
                centerX: 64
                centerY: 72
                radiusX: 53
                radiusY: 19
                startAngle: 0
                sweepAngle: 360
            }
        }
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.topColour
            strokeWidth: 10.5
            capStyle: ShapePath.RoundCap

            PathSvg {
                path: "M27 106 L62 26"
            }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.bottomColour
            strokeWidth: 10.5
            capStyle: ShapePath.RoundCap

            PathSvg {
                path: "M101 106 L66 26"
            }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.bottomColour
            strokeWidth: 9
            capStyle: ShapePath.RoundCap

            PathSvg {
                path: "M42 82 L86 82"
            }
        }

        ShapePath {
            fillColor: root.topColour

            PathSvg {
                path: "M64 5 L67 16 L78 19 L67 22 L64 33 L61 22 L50 19 L61 16 Z"
            }
        }
    }
}
