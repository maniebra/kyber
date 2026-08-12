import QtQuick
import Quickshell.Widgets

import "root:/"

Item {
    id: root

    property real radius: Theme.radius
    property real band: 7
    property real strength: 1
    property bool squareTop: false
    property bool squareLeft: false

    readonly property color film: Qt.rgba(1, 1, 1, 0.05 * strength)

    anchors.fill: parent

    ClippingRectangle {
        anchors.left: parent.left
        anchors.leftMargin: root.squareLeft ? -root.radius - 1 : 0
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.top: parent.top
        anchors.topMargin: root.squareTop ? -root.radius - 1 : 0

        color: root.film
        radius: root.radius
    }
}
