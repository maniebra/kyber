import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick

import "root:/"
import "root:/components"
import "root:/services"

// Thin strip down the left edge, under the bar: app menu at the top, dock at
// the bottom. It also gives the app menu a surface to slide out of — the menu's
// flares curve into this edge the way the dropdowns' flares curve into the bar.
PanelWindow {
    id: root

    WlrLayershell.namespace: "kyber-rail"

    anchors {
        top: true
        left: true
        bottom: true
    }

    // Wider than the rail itself: the extra strip is where the fillet that
    // rounds the bar/rail corner is drawn. It reserves only the rail's width, so
    // windows still tile flush against the rail.
    implicitWidth: Theme.railWidth + fillet
    exclusiveZone: Theme.railWidth
    color: "transparent"

    readonly property int fillet: 16

    // Whatever is running, in a stable order. No pins — the rail lists what
    // exists, it isn't a bookmark bar.
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

    // Rounds the inside of the L the bar and the rail make, and carries the
    // hairline around the turn so the two edges read as one bent line.
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

        // matches GlassSheen's film, so the joint where the menu meets the rail
        // shows no brightness step
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(1, 1, 1, 0.05)
        }

        // The rail's silhouette: only the right edge is on screen, and the menu
        // breaks the line over the span it hangs off.
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

                // starts below the fillet, whose arc already carries the line
                // down from the bar
                y: modelData < 0 ? root.fillet : parent.notchEnd
                height: modelData < 0
                    ? Math.max(0, parent.notchY - root.fillet)
                    : Math.max(0, parent.height - parent.notchEnd)
            }
        }

        // ---- app menu ---------------------------------------------------
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

        // ---- keyboard layout ----------------------------------------------
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: menuButton.bottom
            anchors.topMargin: 8

            // "English (US)" -> "EN", "Persian" -> "PE"
            text: Globals.keyboardLayout.slice(0, 2).toUpperCase()
            visible: text !== ""

            font.family: Theme.font
            font.pixelSize: Theme.fontSizeSm
            font.bold: true
            color: Theme.subtext
        }

        // ---- dock ---------------------------------------------------------
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

                    // Running indicator on the rail's outer edge — the dock is
                    // vertical now, so the dot sits beside the icon, not under it.
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
