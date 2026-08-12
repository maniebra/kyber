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

        MouseArea {
            anchors.fill: parent
            onClicked: Globals.closeAll()
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(1, 1, 1, 0.05)
        }

        readonly property int railEnd: Theme.railWidth + 16

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

                x: modelData < 0 ? slab.railEnd : slab.notchEnd
                width: modelData < 0
                    ? Math.max(0, slab.notchX - slab.railEnd)
                    : Math.max(0, slab.width - slab.notchEnd)
            }
        }

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

        Row {
            id: centerBlock

            anchors.centerIn: parent
            spacing: Theme.gap

            Clock {}
        }

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
