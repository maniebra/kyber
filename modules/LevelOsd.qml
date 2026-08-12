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
        anchors.topMargin: -height * Math.max(0, root.offsetScale)

        width: 236
        height: 46

        // Swells while still attached to the bar, relaxes as it lands — same
        // pinch-off as the media peek.
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

                // Offset ghost of the same glyph: a hair of misregistration,
                // the way a cheap panel fringes. Faint enough to read as glow
                // until you look straight at it.
                Text {
                    x: 1.5
                    y: -0.5
                    text: parent.text
                    color: Theme.alpha(Theme.red, 0.45)
                    font: parent.font
                    z: -1
                }
            }

            // Squared off, not a pill: the readout is an instrument, and the
            // segments below only read as cells against a straight rail.
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

                    // Bloom trailing the head, so the filled part reads wet.
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

                // Hot leading edge — the meniscus of the charge, and the one
                // bit of the sheet that's brighter than the accent.
                Rectangle {
                    x: charge.width - 1
                    width: 2
                    height: parent.height + 4
                    anchors.verticalCenter: parent.verticalCenter
                    color: Qt.lighter(Theme.accent, 1.6)
                    visible: charge.width > 1
                }

                // Cut the rail into cells. Drawn over both the track and the
                // charge so the fill reads as segments lighting up rather than
                // a bar growing.
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
