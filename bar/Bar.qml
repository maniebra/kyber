import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import QtQuick

import "root:/"
import "root:/components"
import "root:/services"

PanelWindow {
    id: root

    readonly property var hyprMonitor: Hyprland.monitorFor(screen)

    WlrLayershell.namespace: "kyber-bar"

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Theme.barHeight
    exclusiveZone: Theme.barHeight
    color: "transparent"

    Rectangle {
        id: slab

        anchors.fill: parent
        color: Theme.panel

        // Click-away: the dropdowns are layer-shell windows parked inside the
        // bar's exclusive zone, so their own full-window catcher can't see a
        // click on the bar itself.
        MouseArea {
            anchors.fill: parent
            onClicked: Globals.closeAll()
        }

        // matches GlassSheen's film, or the joint where a dropdown meets the
        // bar shows a brightness step
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(1, 1, 1, 0.05)
        }

        // Bottom hairline, in two halves so an open dropdown breaks it: the
        // line runs to the flare on each side and the flare's arc takes it
        // down around the sheet.
        // rail width plus the fillet that rounds the corner between them
        readonly property int railEnd: Theme.railWidth + 16

        // With nothing open the notch collapses to the far end, so the left
        // segment runs the whole bar and the right one is empty — not to 0,
        // which would collapse the *left* segment instead and blank the line.
        readonly property bool notched:
            Globals.focusedScreen === root.screen.name && Globals.notchWidth > 0
        readonly property real notchX: notched ? Globals.notchX : width
        readonly property real notchEnd: notched ? Globals.notchX + Globals.notchWidth : width

        Repeater {
            model: [-1, 1]

            Rectangle {
                required property int modelData

                y: slab.height - 1
                height: 1
                color: Theme.rim

                // The left segment starts past the rail and its fillet — the
                // fillet's arc is what turns this line down the rail's edge, so
                // running the hairline over the rail would draw a T across it.
                x: modelData < 0 ? slab.railEnd : slab.notchEnd
                width: modelData < 0
                    ? Math.max(0, slab.notchX - slab.railEnd)
                    : Math.max(0, slab.width - slab.notchEnd)
            }
        }


        // ---- LEFT ------------------------------------------------------
        Row {
            anchors {
                left: parent.left
                leftMargin: 6
                verticalCenter: parent.verticalCenter
            }

            spacing: Theme.gap

            Workspaces {
                monitor: root.hyprMonitor
            }

            ActiveWindow {
                maxWidth: Math.max(0, (slab.width - centerBlock.width) / 2 - 200)
            }
        }

        // ---- CENTER ----------------------------------------------------
        Row {
            id: centerBlock

            anchors.centerIn: parent
            spacing: Theme.gap

            Clock {}
        }

        // ---- RIGHT -----------------------------------------------------
        Row {
            anchors {
                right: parent.right
                rightMargin: 6
                verticalCenter: parent.verticalCenter
            }

            spacing: Theme.gap

            SysMonitor {}

            Tray {}

            StatusIsland {}
        }
    }
}
