import QtQuick
import Quickshell.Widgets

import "root:/"

// The optical half of "frosted glass": the compositor blurs what's behind,
// this lays an even frost film over it. Flat — no gradients, no rim strokes,
// so the surface reads as one sheet of frost instead of a lit bevel.
Item {
    id: root

    property real radius: Theme.radius
    property real band: 7
    property real strength: 1
    property bool squareTop: false
    property bool squareLeft: false

    readonly property color film: Qt.rgba(1, 1, 1, 0.05 * strength)

    anchors.fill: parent

    // One pass only. To square off the top, the film grows upward by its own
    // radius so its rounded top corners land outside the slab. Stacking a
    // second rect over the top band instead paints the film twice there and
    // leaves a lighter strip the width of the slab.
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
