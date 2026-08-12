import Quickshell
import Quickshell.Wayland
import QtQuick

import "root:/"
import "root:/components"
import "root:/services"

// Volume / brightness readout: a small flared sheet that drops out of the bar
// whenever a level moves, and tucks back once it stops. Icon and a bar, nothing
// else — it exists to be read at a glance, not operated.
PanelWindow {
    id: root

    required property string screenName

    // Which level is being shown. Whichever moved last wins, so holding a
    // brightness key while music ducks doesn't flip the sheet back and forth.
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

    // 0 = fully down, 1 = parked above the screen. One driver, and `visible`
    // derives from it, so the slide always gets to play.
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

    // Whichever level moved last owns the sheet.
    function flash(which) {
        root.mode = which;
        root.shown = true;
        hide.restart();
    }

    // Swallows the settling values the services emit on startup.
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

    // The bar holds its hairline back over the sheet's span, flares included.
    // The media peek and the dashboard use the same notch, so this yields to
    // both rather than fighting them for it.
    readonly property bool owns:
        open && Globals.focusedScreen === screenName && !Globals.dashboard

    Binding {
        target: Globals
        property: "notchWidth"
        value: Math.round((sheet.width + 40) * (1 - root.offsetScale))
        when: root.owns
        restoreMode: Binding.RestoreNone
    }

    // The bar measures in screen coordinates, this window in its own — the
    // compositor parks it past the rail's exclusive zone.
    readonly property real screenInset: (screen?.width ?? width) - width

    Binding {
        target: Globals
        property: "notchX"
        value: Math.round(root.screenInset + sheet.x - 20 * (1 - root.offsetScale))
        when: root.owns
        restoreMode: Binding.RestoreNone
    }

    // Concave wedges either side, so the sheet reads as carved out of the bar.
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
        anchors.topMargin: -height * root.offsetScale

        width: 236
        height: 46

        // Swells while still attached to the bar, relaxes as it lands — same
        // pinch-off as the media peek.
        radius: Theme.radius + 4 + 12 * root.offsetScale
        squareTop: true
        opacity: Math.max(0, 1 - root.offsetScale * 1.4)

        Row {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.topMargin: -6 * root.offsetScale
            spacing: 12

            Text {
                anchors.verticalCenter: parent.verticalCenter

                text: root.glyph
                color: Theme.text
                font.family: Theme.fontIcon
                font.pixelSize: 16
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter

                width: parent.width - 28 - parent.spacing
                height: 5
                radius: 2.5
                color: Theme.alpha(Theme.text, 0.1)

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, root.level))
                    height: parent.height
                    radius: parent.radius
                    color: Theme.accent

                    Behavior on width { Morph { duration: Theme.animMed } }

                    // Bloom trailing the head, so the filled part reads wet.
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        width: Math.min(parent.width, 48)
                        height: parent.height + 6
                        radius: height / 2
                        color: Theme.alpha(Theme.accent, 0.22)
                        z: -1
                    }
                }
            }
        }
    }
}
