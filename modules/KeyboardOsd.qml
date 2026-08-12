import Quickshell
import Quickshell.Wayland
import QtQuick

import "root:/"
import "root:/components"
import "root:/services"

PanelWindow {
    id: root

    required property string screenName

    readonly property bool shouldShow:
        shown && Globals.focusedScreen === screenName

    property bool shown: false

    property real slide: shouldShow ? 0 : 1
    Behavior on slide { Morph {} }

    readonly property bool open: slide < 1

    visible: open

    WlrLayershell.namespace: "kyber-kbd-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        left: true
        bottom: true
    }

    implicitWidth: 320
    color: "transparent"
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}

    Connections {
        target: Globals

        function onKeyboardLayoutTickChanged() {
            root.shown = true;
            hide.restart();
        }
    }

    Timer {
        id: hide

        interval: 900
        onTriggered: root.shown = false
    }

    Binding {
        target: Globals
        property: "osdNotchY"
        value: Math.round(panel.y - 16 * (1 - root.slide))
        when: root.open && !Globals.launcher
        restoreMode: Binding.RestoreNone
    }

    Binding {
        target: Globals
        property: "osdNotchHeight"
        value: Math.round((panel.height + 32) * (1 - root.slide))
        when: root.open && !Globals.launcher
        restoreMode: Binding.RestoreNone
    }

    Item {
        id: stage

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        width: panel.width
        clip: true

        FlareCorner {
            x: -1
            anchors.bottom: panel.top
            anchors.bottomMargin: -1
            size: 16 * (1 - root.slide)
            mirrored: true
            flipped: true
            z: 1
        }

        FlareCorner {
            x: -1
            anchors.top: panel.bottom
            anchors.topMargin: -1
            size: 16 * (1 - root.slide)
            mirrored: true
            z: 1
        }

        GlassPanel {
            id: panel

            y: 8 + 26 + 8 - (height - 14) / 2
            x: -width * Math.max(0, root.slide)

            width: label.implicitWidth + 32
            height: 44
            radius: Theme.radius + 4
            squareLeft: true

            Behavior on width { Morph {} }

            Row {
                id: label

                anchors.centerIn: parent
                spacing: 10

                Text {
                    anchors.verticalCenter: parent.verticalCenter

                    text: Globals.keyboardLayout.slice(0, 2).toUpperCase()
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize + 4
                    font.bold: true
                    color: Theme.accent
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter

                    text: Globals.keyboardLayout
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    color: Theme.subtext
                }
            }
        }
    }
}
