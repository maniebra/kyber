import QtQuick

import "root:/"

Item {
    id: root

    property color color: Theme.accent
    property real thickness: 1.5
    property real arm: 9
    property real inset: 4
    property real elbow: 5
    property real strength: 0.7

    property bool topLeft: true
    property bool topRight: false
    property bool bottomLeft: false
    property bool bottomRight: true

    anchors.fill: parent

    Repeater {
        model: [
            { on: root.topLeft, hx: -1, hy: -1 },
            { on: root.topRight, hx: 1, hy: -1 },
            { on: root.bottomLeft, hx: -1, hy: 1 },
            { on: root.bottomRight, hx: 1, hy: 1 }
        ]

        Item {
            required property var modelData

            visible: modelData.on
            width: root.arm
            height: root.arm

            x: modelData.hx < 0 ? root.inset : root.width - root.arm - root.inset
            y: modelData.hy < 0 ? root.inset : root.height - root.arm - root.inset

            clip: true

            Rectangle {
                width: root.arm * 2
                height: root.arm * 2
                x: modelData.hx < 0 ? 0 : -root.arm
                y: modelData.hy < 0 ? 0 : -root.arm

                color: "transparent"
                radius: root.elbow
                border.width: root.thickness
                border.color: root.color
                opacity: root.strength
                antialiasing: true
            }
        }
    }
}
