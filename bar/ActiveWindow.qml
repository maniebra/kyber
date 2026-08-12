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

    // The margins have to be in the implicit width, and letter-spacing adds a
    // trailing gap Qt counts in implicitWidth but the layout was cutting off —
    // hence the slack. Without it the last glyph is clipped.
    implicitWidth: Math.min(row.implicitWidth + 10, maxWidth)
    implicitHeight: 22
    clip: true

    // App id only. The window title is whatever the app feels like writing —
    // usually a whole sentence — and it pushed everything else around as it
    // changed.
    Text {
        id: row

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 4

        // fills whatever the item settled on, minus its own margins
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
