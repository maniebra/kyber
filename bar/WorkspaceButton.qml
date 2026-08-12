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

    // the active fill is the sliding pill behind the row, not this
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
