import QtQuick
import QtQuick.Shapes

import "root:/"

// The concave wedge that makes a dropdown look carved out of the bar:
//   ──\____/──
// Sits beside a panel's top corner, filled with the panel colour, with a
// quarter disc bitten out of it.
Shape {
    id: root

    property real size: 14
    property bool mirrored: false   // true = right-hand corner
    property bool flipped: false    // true = wedge hangs under, not over
    property color fill: Theme.panel

    implicitWidth: size
    implicitHeight: size
    preferredRendererType: Shape.CurveRenderer

    // Four orientations out of one wedge: which two edges the fill hugs decides
    // which corner it can sit in.
    transform: Scale {
        origin.x: root.width / 2
        origin.y: root.height / 2
        xScale: root.mirrored ? -1 : 1
        yScale: root.flipped ? -1 : 1
    }

    component Wedge: ShapePath {
        strokeWidth: 0
        strokeColor: "transparent"

        startX: 0
        startY: 0

        PathLine { x: root.size; y: 0 }
        PathLine { x: root.size; y: root.size }

        // back to the origin around a centre at the bottom-left corner
        PathArc {
            x: 0
            y: 0
            radiusX: root.size
            radiusY: root.size
            direction: PathArc.Counterclockwise
        }
    }

    // Slab tint, then the same frost film GlassSheen lays over a panel — one
    // pass alone reads as a darker patch beside the panel the wedge butts.
    Wedge { fillColor: root.fill }
    Wedge { fillColor: Qt.rgba(1, 1, 1, 0.05) }

    // The concave edge alone, stroked: this is the segment that carries the
    // panel's outline back up to the bar, so the whole shape wears one line.
    ShapePath {
        fillColor: "transparent"
        strokeColor: Theme.rim
        strokeWidth: 1

        startX: root.size
        startY: root.size

        PathArc {
            x: 0
            y: 0
            radiusX: root.size
            radiusY: root.size
            direction: PathArc.Counterclockwise
        }
    }
}
