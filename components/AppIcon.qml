import QtQuick
import Quickshell
import Quickshell.Widgets

import "root:/"

// An app/tray icon that never shows Qt's magenta checkerboard. A themed icon
// can be missing for all sorts of ordinary reasons — a player with no desktop
// entry, a tray app shipping a name no icon theme carries — and the placeholder
// is worse than showing nothing, so a glyph stands in instead.
Item {
    id: root

    // Two ways in: a themed icon *name* (resolved here, with an existence
    // check) or a ready-made url. The name path matters — Quickshell's icon
    // loader happily returns its magenta checkerboard for a name no theme
    // carries, and that image loads fine, so watching `status` catches
    // nothing. Asking iconPath to verify first is the only reliable test.
    property string name: ""
    property string source: ""
    property real size: 20
    property string glyph: ""
    property color glyphColor: Theme.subtext

    implicitWidth: size
    implicitHeight: size

    IconImage {
        id: image

        anchors.fill: parent
        readonly property string resolved: root.name !== ""
            ? Quickshell.iconPath(root.name, true)
            : root.source

        source: resolved
        visible: resolved !== "" && status === Image.Ready
        smooth: true
        mipmap: true
        antialiasing: true
    }

    Text {
        anchors.centerIn: parent
        visible: !image.visible

        text: root.glyph
        color: root.glyphColor
        font.family: Theme.fontIcon
        font.pixelSize: root.size * 0.72
    }
}
