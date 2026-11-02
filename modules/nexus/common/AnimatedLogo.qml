pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.components

Item {
    id: root

    property real blurAmount: skipIntroAnimation ? 0.0 : 1.0
    property bool skipIntroAnimation: false

    property real star1Opacity: skipIntroAnimation ? 1.0 : 0.0
    property real star2Opacity: skipIntroAnimation ? 1.0 : 0.0
    property real star3Opacity: skipIntroAnimation ? 1.0 : 0.0

    property real star1Scale: skipIntroAnimation ? 1.0 : 0.0
    property real star2Scale: skipIntroAnimation ? 1.0 : 0.0
    property real star3Scale: skipIntroAnimation ? 1.0 : 0.0

    readonly property alias topShape: topShape
    readonly property alias bottomShape: bottomShape
    readonly property alias star1: star1
    readonly property alias star2: star2
    readonly property alias star3: star3

    // Easter egg: holding the logo charges it. The A shakes and the stars move along the
    // orbit faster; 0 is the resting state (see AboutPage).
    property real energy: 0
    property real orbitPhase: 0
    property real shakeX: 0
    property real shakeY: 0

    // The orbit is the ellipse drawn below: centre (64, 72), radii 53 x 19, rotated -14
    // degrees. Stars are placed on that path rather than on a circle of their own.
    readonly property point star1Pos: orbitPoint(Math.PI * 1.5 + orbitPhase)
    readonly property point star2Pos: orbitPoint(Math.PI / 6 + orbitPhase)
    readonly property point star3Pos: orbitPoint(Math.PI * 5 / 6 + orbitPhase)

    signal animationCompleted

    function orbitPoint(angle: real): point {
        const sx = 53 * Math.cos(angle);
        const sy = 19 * Math.sin(angle);
        const rot = -14 * Math.PI / 180;
        return Qt.point(64 + sx * Math.cos(rot) - sy * Math.sin(rot), 72 + sx * Math.sin(rot) + sy * Math.cos(rot));
    }

    implicitWidth: 128
    implicitHeight: 128

    Item {
        id: logo

        readonly property real designWidth: 128
        readonly property real designHeight: 128

        property color topColour: "#EBF4FF"
        property color bottomColour: "#FFFFFF"
        property color starColour: "#6AE5E1"

        implicitWidth: designWidth
        implicitHeight: designHeight

        transformOrigin: Item.Center
        scale: root.skipIntroAnimation ? 1.0 : 0.0
        opacity: root.skipIntroAnimation ? 1.0 : 0.0
        rotation: 0.0

        layer.enabled: root.blurAmount > 0
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: root.blurAmount
            blurMax: 60
        }

        Component.onCompleted: {
            root.star1.opacity = Qt.binding(() => root.star1Opacity);
            root.star1.scale = Qt.binding(() => root.star1Scale);
            root.star2.opacity = Qt.binding(() => root.star2Opacity);
            root.star2.scale = Qt.binding(() => root.star2Scale);
            root.star3.opacity = Qt.binding(() => root.star3Opacity);
            root.star3.scale = Qt.binding(() => root.star3Scale);
        }

        Behavior on topColour {
            CAnim {}
        }

        Behavior on bottomColour {
            CAnim {}
        }

        Behavior on starColour {
            CAnim {}
        }

        // The orbit is split at its widest points: the far half is drawn behind the A, the
        // near half in front of it, so the ring reads as going around the letter rather than
        // through it. Angles run clockwise with y down, so 0..180 is the lower (near) half.
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            rotation: -14
            opacity: 0.85
            z: -2

            ShapePath {
                fillColor: "transparent"
                strokeColor: logo.starColour
                strokeWidth: 2

                PathAngleArc {
                    centerX: 64
                    centerY: 72
                    radiusX: 53
                    radiusY: 19
                    startAngle: 180
                    sweepAngle: 180
                }
            }
        }

        // The A: two legs and a crossbar. Kept apart from the orbit and the stars so the
        // easter egg can shake the letter without moving either of them.
        Item {
            id: aShapes

            anchors.fill: parent
            transform: Translate {
                x: root.shakeX
                y: root.shakeY
            }

            Shape {
                id: topShape

                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    fillColor: "transparent"
                    strokeColor: logo.topColour
                    strokeWidth: 10.5
                    capStyle: ShapePath.RoundCap

                    PathSvg {
                        path: "M27 106 L62 26"
                    }
                }
            }

            Shape {
                id: bottomShape

                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    fillColor: "transparent"
                    strokeColor: logo.bottomColour
                    strokeWidth: 10.5
                    capStyle: ShapePath.RoundCap

                    PathSvg {
                        path: "M101 106 L66 26"
                    }
                }

                ShapePath {
                    fillColor: "transparent"
                    strokeColor: logo.bottomColour
                    strokeWidth: 9
                    capStyle: ShapePath.RoundCap

                    PathSvg {
                        path: "M42 82 L86 82"
                    }
                }
            }
        }

        // The near half of the orbit, drawn over the letter.
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            rotation: -14
            opacity: 0.85
            z: 1

            ShapePath {
                fillColor: "transparent"
                strokeColor: logo.starColour
                strokeWidth: 2

                PathAngleArc {
                    centerX: 64
                    centerY: 72
                    radiusX: 53
                    radiusY: 19
                    startAngle: 0
                    sweepAngle: 180
                }
            }
        }

        // The three stars travel along the orbit while the logo is charged. Each keeps its
        // own shape upright; only its centre moves. The lower half of the ellipse is in front
        // of the A and the upper half behind it, so a star's z follows the sine of its phase.
        Shape {
            id: star1

            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            opacity: 0.0
            transform: Translate {
                x: root.star1Pos.x - 64
                y: root.star1Pos.y - 19
            }
            z: Math.sin(Math.PI * 1.5 + root.orbitPhase) > 0 ? 2 : -1

            ShapePath {
                fillColor: logo.starColour
                strokeColor: "transparent"

                PathSvg {
                    path: "M64 5 L67 16 L78 19 L67 22 L64 33 L61 22 L50 19 L61 16 Z"
                }
            }
        }

        Shape {
            id: star2

            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            opacity: 0.0
            transform: Translate {
                x: root.star2Pos.x - 102
                y: root.star2Pos.y - 45
            }
            z: Math.sin(Math.PI / 6 + root.orbitPhase) > 0 ? 2 : -1

            ShapePath {
                fillColor: logo.starColour
                strokeColor: "transparent"

                PathSvg {
                    path: "M102 39 L104 43 L108 45 L104 47 L102 51 L100 47 L96 45 L100 43 Z"
                }
            }
        }

        Shape {
            id: star3

            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            opacity: 0.0
            transform: Translate {
                x: root.star3Pos.x - 24
                y: root.star3Pos.y - 96
            }
            z: Math.sin(Math.PI * 5 / 6 + root.orbitPhase) > 0 ? 2 : -1

            ShapePath {
                fillColor: logo.starColour
                strokeColor: "transparent"

                PathSvg {
                    path: "M24 90 L25.5 94.5 L30 96 L25.5 97.5 L24 102 L22.5 97.5 L18 96 L22.5 94.5 Z"
                }
            }
        }
    }

    SequentialAnimation {
        running: !root.skipIntroAnimation
        onFinished: root.animationCompleted()

        ParallelAnimation {
            SequentialAnimation {
                NumberAnimation {
                    target: logo
                    property: "rotation"
                    from: 0
                    to: 750
                    duration: 1000
                    easing.type: Easing.OutCubic
                }

                NumberAnimation {
                    target: logo
                    property: "rotation"
                    from: 750
                    to: 710
                    duration: 300
                    easing.type: Easing.InOutQuad
                }

                NumberAnimation {
                    target: logo
                    property: "rotation"
                    from: 710
                    to: 725
                    duration: 350
                    easing.type: Easing.InOutQuad
                }

                NumberAnimation {
                    target: logo
                    property: "rotation"
                    from: 725
                    to: 720
                    duration: 250
                    easing.type: Easing.OutQuad
                }

                ScriptAction {
                    script: logo.rotation = 0
                }
            }

            SequentialAnimation {
                NumberAnimation {
                    target: logo
                    property: "scale"
                    from: 0.0
                    to: 1.08
                    duration: 1000
                    easing.type: Easing.OutCubic
                }

                NumberAnimation {
                    target: logo
                    property: "scale"
                    from: 1.08
                    to: 0.96
                    duration: 200
                    easing.type: Easing.InOutQuad
                }

                NumberAnimation {
                    target: logo
                    property: "scale"
                    from: 0.96
                    to: 1.0
                    duration: 250
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.05
                }
            }

            NumberAnimation {
                target: logo
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: 600
                easing.type: Easing.InOutQuad
            }

            NumberAnimation {
                target: root
                property: "blurAmount"
                from: 1.0
                to: 0.0
                duration: 900
                easing.type: Easing.OutCubic
            }

            SequentialAnimation {
                PauseAnimation {
                    duration: 1100
                }

                ParallelAnimation {
                    NumberAnimation {
                        target: root
                        property: "star1Opacity"
                        from: 0.0
                        to: 1.0
                        duration: 700
                        easing.type: Easing.InOutQuad
                    }

                    SequentialAnimation {
                        NumberAnimation {
                            target: root
                            property: "star1Scale"
                            from: 0.0
                            to: 1.08
                            duration: 500
                            easing.type: Easing.OutQuad
                        }

                        NumberAnimation {
                            target: root
                            property: "star1Scale"
                            from: 1.08
                            to: 1.0
                            duration: 400
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
            }

            SequentialAnimation {
                PauseAnimation {
                    duration: 1250
                }

                ParallelAnimation {
                    NumberAnimation {
                        target: root
                        property: "star2Opacity"
                        from: 0.0
                        to: 1.0
                        duration: 700
                        easing.type: Easing.InOutQuad
                    }

                    SequentialAnimation {
                        NumberAnimation {
                            target: root
                            property: "star2Scale"
                            from: 0.0
                            to: 1.08
                            duration: 500
                            easing.type: Easing.OutQuad
                        }

                        NumberAnimation {
                            target: root
                            property: "star2Scale"
                            from: 1.08
                            to: 1.0
                            duration: 400
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
            }

            SequentialAnimation {
                PauseAnimation {
                    duration: 1400
                }

                ParallelAnimation {
                    NumberAnimation {
                        target: root
                        property: "star3Opacity"
                        from: 0.0
                        to: 1.0
                        duration: 700
                        easing.type: Easing.InOutQuad
                    }

                    SequentialAnimation {
                        NumberAnimation {
                            target: root
                            property: "star3Scale"
                            from: 0.0
                            to: 1.08
                            duration: 500
                            easing.type: Easing.OutQuad
                        }

                        NumberAnimation {
                            target: root
                            property: "star3Scale"
                            from: 1.08
                            to: 1.0
                            duration: 400
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
            }
        }
    }

    SequentialAnimation {
        running: true
        loops: Animation.Infinite

        PauseAnimation {
            duration: 2500
        }

        ParallelAnimation {
            SequentialAnimation {
                loops: Animation.Infinite

                NumberAnimation {
                    target: root.star1
                    property: "y"
                    from: root.star1.y
                    to: root.star1.y - 5
                    duration: 2500
                    easing.type: Easing.InOutQuad
                }

                NumberAnimation {
                    target: root.star1
                    property: "y"
                    from: root.star1.y - 5
                    to: root.star1.y
                    duration: 2500
                    easing.type: Easing.InOutQuad
                }
            }

            SequentialAnimation {
                loops: Animation.Infinite

                NumberAnimation {
                    target: root.star2
                    property: "y"
                    from: root.star2.y
                    to: root.star2.y + 5
                    duration: 3000
                    easing.type: Easing.InOutQuad
                }

                NumberAnimation {
                    target: root.star2
                    property: "y"
                    from: root.star2.y + 5
                    to: root.star2.y
                    duration: 3000
                    easing.type: Easing.InOutQuad
                }
            }

            SequentialAnimation {
                loops: Animation.Infinite

                NumberAnimation {
                    target: root.star3
                    property: "y"
                    from: root.star3.y
                    to: root.star3.y - 5
                    duration: 2800
                    easing.type: Easing.InOutQuad
                }

                NumberAnimation {
                    target: root.star3
                    property: "y"
                    from: root.star3.y - 5
                    to: root.star3.y
                    duration: 2800
                    easing.type: Easing.InOutQuad
                }
            }

            SequentialAnimation {
                loops: Animation.Infinite

                NumberAnimation {
                    target: root.star1
                    property: "scale"
                    from: 1.0
                    to: 1.08
                    duration: 2500
                    easing.type: Easing.InOutQuad
                }

                NumberAnimation {
                    target: root.star1
                    property: "scale"
                    from: 1.08
                    to: 1.0
                    duration: 2500
                    easing.type: Easing.InOutQuad
                }
            }

            SequentialAnimation {
                loops: Animation.Infinite

                NumberAnimation {
                    target: root.star2
                    property: "scale"
                    from: 1.0
                    to: 1.12
                    duration: 3000
                    easing.type: Easing.InOutQuad
                }

                NumberAnimation {
                    target: root.star2
                    property: "scale"
                    from: 1.12
                    to: 1.0
                    duration: 3000
                    easing.type: Easing.InOutQuad
                }
            }

            SequentialAnimation {
                loops: Animation.Infinite

                NumberAnimation {
                    target: root.star3
                    property: "scale"
                    from: 1.0
                    to: 1.08
                    duration: 2800
                    easing.type: Easing.InOutQuad
                }

                NumberAnimation {
                    target: root.star3
                    property: "scale"
                    from: 1.08
                    to: 1.0
                    duration: 2800
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }

    // Drives both easter egg effects: the letter's jitter and the stars' orbit. Two
    // different frequencies so it reads as a shake rather than a sway.
    FrameAnimation {
        running: root.energy > 0.001

        onTriggered: {
            root.orbitPhase = (root.orbitPhase + frameTime * (0.55 + root.energy * 9.5)) % (Math.PI * 2);
            const amp = root.energy * 3.2;
            root.shakeX = Math.sin(elapsedTime * 57) * amp;
            root.shakeY = Math.cos(elapsedTime * 43) * amp;
        }

        onRunningChanged: {
            if (!running) {
                root.shakeX = 0;
                root.shakeY = 0;
            }
        }
    }
}
