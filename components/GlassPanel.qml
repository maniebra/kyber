import QtQuick

import "root:/"

Rectangle {
    id: root

    property real sheen: 1

    property bool squareTop: false

    property bool squareLeft: false

    color: "transparent"
    radius: Theme.radius
    antialiasing: true

    Rectangle {
        anchors.left: parent.left
        anchors.leftMargin: root.squareLeft ? -root.radius - 1 : 0
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.top: parent.top
        anchors.topMargin: root.squareTop ? -root.radius - 1 : 0

        color: Theme.panel
        radius: root.radius
        antialiasing: true

        border.width: 1
        border.color: Theme.rim
    }

    GlassSheen {
        radius: root.radius
        strength: root.sheen
        squareTop: root.squareTop
        squareLeft: root.squareLeft
        z: 100
    }
}
