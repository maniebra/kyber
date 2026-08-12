import QtQuick

import "root:/"
import "root:/services"
import "root:/components"

Rectangle {
    id: root

    property int workspaceId: 1
    property bool active: false
    property bool occupied: false

    width: active ? 26 : 18
    height: 18
    radius: Theme.radiusSm
    antialiasing: true

    color: !active && mouse.containsMouse ? Theme.surfaceHover : "transparent"

    Behavior on width {
        Morph {}
    }
    Behavior on color { CMorph { duration: Theme.animFast } }

    Text {
        anchors.centerIn: parent

        text: root.workspaceId
        color: root.active
            ? Theme.accent
            : root.occupied ? Theme.subtext : Theme.faint

        font.family: Theme.fontMono
        font.pixelSize: 9
        font.weight: root.active ? Font.DemiBold : Font.Normal

        Behavior on color { ColorAnimation { duration: Theme.animFast } }
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 2

        width: root.occupied && !root.active ? 6 : 0
        height: 1
        color: Theme.subtext

        Behavior on width { Morph { duration: Theme.animMed } }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: Globals.focusWorkspace(root.workspaceId)
        onWheel: wheel => Globals.focusWorkspace(
            wheel.angleDelta.y > 0 ? "e-1" : "e+1"
        )
    }
}
