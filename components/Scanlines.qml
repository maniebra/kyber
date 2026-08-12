import QtQuick
import Quickshell.Widgets

import "root:/"

// CRT rows over a panel: one dark line every few pixels, far below the level
// where you'd call it a texture — it shows up as a faint tooth on the frost,
// not as stripes. Clipped to the panel's radius so it can't square off a
// rounded corner, and it takes no input.
ClippingRectangle {
    id: root

    property real pitch: 4
    property real strength: 0.05
    property bool squareTop: false

    anchors.fill: parent
    color: "transparent"
    radius: Theme.radius

    // Same trick GlassSheen uses: to square off the top, grow past the radius
    // rather than painting a second rect over the top band.
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
