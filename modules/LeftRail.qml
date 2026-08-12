import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick

import "root:/"
import "root:/components"
import "root:/services"

PanelWindow {
    id: root

    WlrLayershell.namespace: "kyber-rail"

    anchors {
        top: true
        left: true
        bottom: true
    }

    implicitWidth: Theme.railWidth + fillet
    exclusiveZone: Theme.railWidth
    color: "transparent"

    readonly property int fillet: 16

    readonly property var items: {
        const running = {};
        for (const t of ToplevelManager.toplevels.values) {
            const entry = DesktopEntries.heuristicLookup(t.appId);
            const key = (entry?.id ?? t.appId ?? "").toLowerCase();
            if (key === "")
                continue;
            if (!running[key])
                running[key] = { entry: entry, appId: t.appId, count: 0 };
            running[key].count++;
        }

        return Object.keys(running)
            .sort()
            .map(k => running[k]);
    }

    FlareCorner {
        x: Theme.railWidth
        y: 0
        size: root.fillet
        mirrored: true
    }

    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        width: Theme.railWidth

        color: Theme.panel

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(1, 1, 1, 0.05)
        }

        readonly property bool notched: Globals.railNotchHeight > 0
        readonly property real notchY: notched ? Globals.railNotchY : height
        readonly property real notchEnd:
            notched ? Globals.railNotchY + Globals.railNotchHeight : height

        Repeater {
            model: [-1, 1]

            Rectangle {
                required property int modelData

                x: parent.width - 1
                width: 1
                color: Theme.rim

                y: modelData < 0 ? root.fillet : parent.notchEnd
                height: modelData < 0
                    ? Math.max(0, parent.notchY - root.fillet)
                    : Math.max(0, parent.height - parent.notchEnd)
            }
        }

        Rectangle {
            id: menuButton

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 8

            width: 26
            height: 26
            radius: Theme.radiusSm

            color: Globals.launcher
                ? Theme.alpha(Theme.accent, 0.16)
                : mouse.containsMouse
                    ? Theme.surfaceHover
                    : "transparent"

            Behavior on color { ColorAnimation { duration: Theme.animFast } }

            Text {
                anchors.centerIn: parent
                text: ""
                font.family: Theme.fontIcon
                font.pixelSize: 14
                color: Globals.launcher ? Theme.accent : Theme.subtext

                Behavior on color { ColorAnimation { duration: Theme.animFast } }
            }

            MouseArea {
                id: mouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: Globals.toggleLauncher()
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: menuButton.bottom
            anchors.topMargin: 8

            text: Globals.keyboardLayout.slice(0, 2).toUpperCase()
            visible: text !== ""

            font.family: Theme.font
            font.pixelSize: Theme.fontSizeSm
            font.bold: true
            color: Theme.subtext
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8
            spacing: 4

            Repeater {
                model: root.items

                Rectangle {
                    id: item

                    required property var modelData

                    width: 28
                    height: 28
                    radius: Theme.radiusSm

                    color: tap.containsMouse ? Theme.surfaceHover : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    AppIcon {
                        anchors.centerIn: parent
                        size: 20
                        name: item.modelData.entry?.icon ?? ""
                        glyph: ""
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.leftMargin: -5
                        anchors.verticalCenter: parent.verticalCenter

                        width: 3
                        height: item.modelData.count > 1 ? 12 : 5
                        radius: 1.5

                        visible: item.modelData.count > 0
                        color: Theme.subtext

                        Behavior on height { NumberAnimation { duration: Theme.animFast } }
                    }

                    MouseArea {
                        id: tap

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton

                        onClicked: mouse => {
                            const wantNew = mouse.button === Qt.MiddleButton
                                || item.modelData.count === 0;

                            if (wantNew) {
                                item.modelData.entry?.execute();
                                return;
                            }

                            const match = ToplevelManager.toplevels.values.find(
                                t => t.appId === item.modelData.appId
                            );
                            if (match)
                                match.activate();
                            else
                                item.modelData.entry?.execute();
                        }
                    }
                }
            }
        }
    }
}
