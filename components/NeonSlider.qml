import QtQuick

import "root:/"

// Vertical fader: the fill rises from the bottom, the icon sits in the base and
// the readout at the top. Dragging anywhere on the column sets the value, so
// there is no handle to hunt for.
Item {
    id: root

    property real value: 0            // 0..1
    property color accent: Theme.accent
    property string icon: ""
    property bool enabled: true

    signal moved(real value)

    implicitWidth: 56
    implicitHeight: 150

    readonly property real clamped: Math.max(0, Math.min(1, value))

    Rectangle {
        id: track

        anchors.fill: parent
        radius: Theme.radiusSm
        color: Theme.alpha(Theme.surface, 0.9)
        clip: true
        antialiasing: true

        Rectangle {
            id: fill

            anchors.bottom: parent.bottom
            width: track.width
            // never shorter than its own corner radius, or the fill degenerates
            // into a sliver at the low end
            height: Math.max(radius, track.height * root.clamped)
            radius: track.radius
            opacity: root.enabled ? 1 : 0.35

            // Full-strength accent: a washed-out fill is what makes a slider
            // look like a stock widget instead of a designed control.
            color: drag.containsMouse || drag.pressed
                ? Qt.lighter(root.accent, 1.12)
                : root.accent
            antialiasing: true

            Behavior on color { ColorAnimation { duration: Theme.animFast } }
            Behavior on height {
                enabled: !drag.pressed
                Morph { duration: Theme.animMed; easing.bezierCurve: Theme.curveFlow }
            }
        }

        Text {
            id: glyph

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10

            text: root.icon
            font.family: Theme.fontIcon
            font.pixelSize: 14
            // flips to ink once the fill has risen behind it
            color: fill.height > 32 ? Theme.accentText : Theme.subtext

            Behavior on color { ColorAnimation { duration: Theme.animFast } }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 10

            text: Math.round(root.value * 100)
            font.family: Theme.fontMono
            font.pixelSize: 10
            font.letterSpacing: Theme.trackingWide
            color: fill.height > track.height - 26 ? Theme.accentText : Theme.subtext

            Behavior on color { ColorAnimation { duration: Theme.animFast } }
        }
    }

    MouseArea {
        id: drag

        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        preventStealing: true

        // y grows downward, the value grows upward
        function apply(y) {
            root.moved(Math.max(0, Math.min(1, 1 - y / height)));
        }

        onPressed: mouse => apply(mouse.y)
        onPositionChanged: mouse => {
            if (pressed)
                apply(mouse.y);
        }
        onWheel: wheel => root.moved(
            Math.max(0, Math.min(1, root.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)))
        )
    }
}
