import QtQuick
import QtQuick.Shapes

import "root:/"

Shape {
    id: root

    property real size: 14
    property bool mirrored: false
    property bool flipped: false
    property color fill: Theme.panel

    implicitWidth: size
    implicitHeight: size
    preferredRendererType: Shape.CurveRenderer

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

        PathArc {
            x: 0
            y: 0
            radiusX: root.size
            radiusY: root.size
            direction: PathArc.Counterclockwise
        }
    }

    Wedge { fillColor: root.fill }
    Wedge { fillColor: Qt.rgba(1, 1, 1, 0.05) }

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
