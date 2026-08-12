import QtQuick

import "root:/"

// The bar's building block: a hoverable rounded cell holding whatever you
// put in it.
Rectangle {
    id: root

    property color accent: Theme.accent
    property bool active: false
    property bool interactive: true
    property alias hovered: mouse.containsMouse
    property alias acceptedButtons: mouse.acceptedButtons
    property int padding: 8

    default property alias content: layout.data

    signal clicked(var mouse)
    signal wheel(real delta)

    implicitWidth: layout.implicitWidth + padding * 2
    implicitHeight: 22

    radius: Theme.radiusSm
    antialiasing: true

    // Ghost by default: a bar of filled pills reads as a phone status bar. The
    // cell only takes a surface once it's hovered or actually holding a state.
    color: active
        ? Theme.alpha(accent, 0.16)
        : mouse.containsMouse
            ? Theme.surfaceHover
            : "transparent"

    // Presses register in the geometry, not just the fill — a chip that only
    // changes colour on click feels like a web button, not a physical control.
    scale: mouse.pressed ? 0.96 : 1

    Behavior on color {
        ColorAnimation { duration: Theme.animFast }
    }
    Behavior on scale {
        Morph { duration: Theme.animMed }
    }

    Row {
        id: layout
        anchors.centerIn: parent
        spacing: 6
    }

    // Armed marker: a short accent rule under a chip that is holding state.
    // Grows from the middle, so it reads as the cell latching rather than as a
    // second border appearing.
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 1

        width: root.active ? parent.width - 10 : 0
        height: 1
        color: root.accent

        Behavior on width { Morph { duration: Theme.animMed } }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: mouse => root.clicked(mouse)
        onWheel: wheel => root.wheel(wheel.angleDelta.y)
    }
}
