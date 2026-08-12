import QtQuick

import "root:/"

// Translucent slab: compositor blur behind it (`layerrule = blur, kyber-.*`),
// frost film on top of it. No border — grouping comes from the shared slab,
// not from outlining every part of it.
Rectangle {
    id: root

    property real sheen: 1

    // Squares off the top edge so the slab hangs flush from the bar, film
    // included — a rounded film over a squared slab leaves corner notches.
    property bool squareTop: false

    // Same trick on the left edge, for a panel that hangs off the rail.
    property bool squareLeft: false

    color: "transparent"
    radius: Theme.radius
    antialiasing: true

    // The slab is drawn as a child rather than as this Rectangle's own fill so
    // squaring off the top can shift it up past its radius. One pixel past, in
    // fact: shifting by exactly the radius leaves the corner arc tangent to the
    // window edge, and its antialiased tail bleeds back in as a stub of border. The colour is
    // translucent — painting a second rect over the top band to square it off
    // would double the tint there and leave a visible strip.
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

        // The slab's only stroke, and it wraps the whole silhouette. When
        // squared off the top border rides off-screen with the rest of the
        // rect, so the outline runs down the sides and around the bottom and
        // the flares carry it back up to the bar.
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
