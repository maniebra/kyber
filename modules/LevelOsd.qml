import Quickshell
import Quickshell.Wayland
import QtQuick

import "root:/"
import "root:/components"
import "root:/services"

PanelWindow {
    id: root

    required property string screenName

    property string mode: "volume"

    readonly property real level: mode === "volume"
        ? (Audio.muted ? 0 : Audio.volume)
        : Brightness.value

    readonly property string glyph: mode === "volume"
        ? Audio.icon
        : ""

    property bool shown: false

    readonly property bool shouldShow:
        shown && Globals.focusedScreen === screenName

    property real offsetScale: shouldShow ? 0 : 1
    Behavior on offsetScale { Morph {} }

    readonly property bool open: offsetScale < 1

    visible: open

    WlrLayershell.namespace: "kyber-level-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    color: "transparent"
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}

    function flash(which) {
        root.mode = which;
        root.shown = true;
        hide.restart();
    }

    Timer {
        id: ready

        interval: 1500
        running: true
    }

    Timer {
        id: hide

        interval: 1200
        onTriggered: root.shown = false
    }

    Connections {
        target: Audio
        enabled: !ready.running

        function onVolumeChanged() { root.flash("volume"); }
        function onMutedChanged() { root.flash("volume"); }
    }

    Connections {
        target: Brightness
        enabled: !ready.running

        function onValueChanged() { root.flash("brightness"); }
    }

    readonly property bool owns:
        open && Globals.focusedScreen === screenName && !Globals.dashboard

    Binding {
        target: Globals
        property: "notchWidth"
        value: Math.round((sheet.width + 40) * (1 - root.offsetScale))
        when: root.owns
        restoreMode: Binding.RestoreNone
    }

    readonly property real screenInset: (screen?.width ?? width) - width

    Binding {
        target: Globals
        property: "notchX"
        value: Math.round(root.screenInset + sheet.x - 20 * (1 - root.offsetScale))
        when: root.owns
        restoreMode: Binding.RestoreNone
    }

    FlareCorner {
        anchors.right: sheet.left
        anchors.rightMargin: -1
        anchors.top: parent.top
        size: 20 * (1 - root.offsetScale)
        z: 1
    }

    FlareCorner {
        anchors.left: sheet.right
        anchors.leftMargin: -1
        anchors.top: parent.top
        size: 20 * (1 - root.offsetScale)
        mirrored: true
        z: 1
    }

    GlassPanel {
        id: sheet

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: -height * Math.max(0, root.offsetScale)

        width: 236
        height: 46

        radius: Theme.radius + 4 + 12 * root.offsetScale
        squareTop: true
        opacity: Math.max(0, 1 - root.offsetScale * 1.4)

        Scanlines {
            radius: sheet.radius
            squareTop: true
            z: 200
        }

        Brackets {
            anchors.margins: 3
            topLeft: true
            topRight: false
            bottomLeft: false
            bottomRight: true
            z: 201
        }

        Row {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.topMargin: -6 * root.offsetScale
            spacing: 12

            Text {
                anchors.verticalCenter: parent.verticalCenter

                text: root.glyph
                color: Theme.accent
                font.family: Theme.fontIcon
                font.pixelSize: 16

                Text {
                    x: 1.5
                    y: -0.5
                    text: parent.text
                    color: Theme.alpha(Theme.red, 0.45)
                    font: parent.font
                    z: -1
                }
            }

            Rectangle {
                id: rail

                anchors.verticalCenter: parent.verticalCenter

                width: parent.width - 28 - parent.spacing
                height: 8
                radius: 1
                color: Theme.alpha(Theme.text, 0.08)

                readonly property int cells: 24

                Rectangle {
                    id: charge

                    width: parent.width * Math.max(0, Math.min(1, root.level))
                    height: parent.height
                    radius: parent.radius
                    color: Theme.accent

                    Behavior on width { Morph { duration: Theme.animMed } }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        width: Math.min(parent.width, 48)
                        height: parent.height + 6
                        radius: 1
                        color: Theme.alpha(Theme.accent, 0.22)
                        z: -1
                    }
                }

                Rectangle {
                    x: charge.width - 1
                    width: 2
                    height: parent.height + 4
                    anchors.verticalCenter: parent.verticalCenter
                    color: Qt.lighter(Theme.accent, 1.6)
                    visible: charge.width > 1
                }

                Row {
                    anchors.fill: parent
                    spacing: 0

                    Repeater {
                        model: rail.cells

                        Item {
                            width: rail.width / rail.cells
                            height: rail.height

                            Rectangle {
                                anchors.right: parent.right
                                width: 1
                                height: parent.height
                                color: Theme.panel
                            }
                        }
                    }
                }
            }
        }
    }
}
