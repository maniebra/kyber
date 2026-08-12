import Quickshell
import Quickshell.Wayland
import QtQuick

import "root:/"

Item {
    id: root

    property real maxWidth: 320

    readonly property var toplevel: ToplevelManager.activeToplevel
    readonly property string appId: toplevel?.appId ?? ""

    visible: appId !== "" && maxWidth > 80
    opacity: visible ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Theme.animMed } }

    implicitWidth: Math.min(row.implicitWidth + 10, maxWidth)
    implicitHeight: 22
    clip: true

    Text {
        id: row

        anchors.verticalCenter: parent.verticalCenter

        anchors.verticalCenterOffset: 1

        anchors.left: parent.left
        anchors.leftMargin: 4

        width: parent.width - 8
        text: root.appId
        color: Theme.subtext
        font.family: Theme.font
        font.pixelSize: Theme.fontSizeSm
        font.letterSpacing: Theme.trackingWide
        font.capitalization: Font.AllUppercase
        elide: Text.ElideRight
    }
}
