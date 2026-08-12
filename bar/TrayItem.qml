import Quickshell
import Quickshell.Widgets
import QtQuick

import "root:/"

Rectangle {
    id: root

    required property var item

    width: 20
    height: 20
    radius: Theme.radiusSm

    color: mouse.containsMouse ? Theme.surfaceHover : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    IconImage {
        anchors.centerIn: parent

        implicitSize: 14
        source: root.item.icon
        smooth: true
        mipmap: true
        antialiasing: true
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton)
                root.item.secondaryActivate();
            else
                root.item.activate();
        }
    }
}
