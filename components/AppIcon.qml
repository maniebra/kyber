import QtQuick
import Quickshell
import Quickshell.Widgets

import "root:/"

Item {
    id: root

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
