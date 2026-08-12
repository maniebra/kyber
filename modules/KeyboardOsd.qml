import Quickshell
import Quickshell.Wayland
import QtQuick

import "root:/"
import "root:/components"
import "root:/services"

// Layout switch OSD: slides out of the left rail beside the rail's layout
// indicator, the same way the app menu does, and tucks back after a beat. A
// receipt, not a panel — it takes no input.
PanelWindow {
    id: root

    required property string screenName

    // Only on the screen holding focus: the switch is global, but a copy on
    // every monitor reads as a glitch.
    readonly property bool shouldShow:
        shown && Globals.focusedScreen === screenName

    property bool shown: false

    // 0 = out, 1 = tucked back behind the rail. `visible` derives from it so
    // the slide back in gets to play before the window unmaps.
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

        // The tick, not the name: switching back to a layout you were just on
        // still deserves a confirmation.
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

    // holds back the rail's hairline over the span the slab grows out of — same
    // deal as the app menu, and only while the menu isn't itself notching it
    Binding {
        target: Globals
        property: "railNotchY"
        value: Math.round(panel.y - 16 * (1 - root.slide))
        when: root.open && !Globals.launcher
        restoreMode: Binding.RestoreNone
    }

    Binding {
        target: Globals
        property: "railNotchHeight"
        value: Math.round((panel.height + 32) * (1 - root.slide))
        when: root.open && !Globals.launcher
        restoreMode: Binding.RestoreNone
    }

    // Clipped to the panel's width so the slab slides out from behind the rail
    // instead of sliding over it. x = 0 is already the rail's right edge.
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

            // Beside the rail's layout indicator: 8 top margin, the 26px menu
            // button, 8 gap, then the label. The slab centres on that label.
            y: 8 + 26 + 8 - (height - 14) / 2
            x: -width * root.slide

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
