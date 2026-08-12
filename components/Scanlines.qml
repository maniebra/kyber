import QtQuick
import Quickshell.Widgets

import "root:/"

ClippingRectangle {
    id: root

    property real pitch: 4
    property real strength: 0.05
    property bool squareTop: false

    anchors.fill: parent
    color: "transparent"
    radius: Theme.radius

    anchors.topMargin: squareTop ? -radius - 1 : 0

    Column {
        width: parent.width
        spacing: root.pitch - 1

        Repeater {
            model: Math.ceil(root.height / root.pitch) + 1

            Rectangle {
                width: root.width
                height: 1
                color: Qt.rgba(0, 0, 0, root.strength)
            }
        }
    }
}
