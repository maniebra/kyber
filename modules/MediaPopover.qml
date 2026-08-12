import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Mpris
import QtQuick

import "root:/"
import "root:/components"
import "root:/services"

// Media peek: hovering the bar's clock chip drops a small flared sheet with the
// current track and its transport. Same carve-out as the dashboard, a third the
// size — a hover reveal shouldn't feel like opening something.
PanelWindow {
    id: root

    required property string screenName

    readonly property var player: Player.current

    // The chip's hover, plus the sheet's own, so the pointer can cross the gap
    // between them. Nothing to show without a player.
    readonly property bool wantOpen:
        (Globals.clockHovered || sheetHover.hovered)
        && Globals.focusedScreen === screenName
        && player !== null
        // a click opened the real thing — the peek gets out of the way
        && !Globals.dashboard && !Globals.controlCenter

    property bool shouldOpen: false

    // Opening waits a beat so the sheet doesn't flash when the pointer merely
    // crosses the chip; closing waits too, so the trip from chip to sheet
    // doesn't drop it.
    Timer {
        id: settle

        interval: root.wantOpen ? 220 : 160
        running: root.wantOpen !== root.shouldOpen
        onTriggered: root.shouldOpen = root.wantOpen
    }

    // 0 = fully down, 1 = parked above the screen. Same single driver as the
    // dashboard: `visible` derives from it, so the slide can't outrun the map.
    property real offsetScale: shouldOpen ? 0 : 1
    Behavior on offsetScale { Morph {} }

    readonly property bool open: offsetScale < 1

    visible: open

    WlrLayershell.namespace: "kyber-media-peek"
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

    // Only the sheet takes the pointer — a full-window mask would eat every
    // click on the desktop for as long as the peek is up.
    mask: Region {
        item: sheet
    }

    // MPRIS position is pull-only; nothing pushes it. Poll while the sheet is
    // up and the track is actually moving, and not a tick more.
    Timer {
        interval: 1000
        repeat: true
        running: root.open
            && root.player?.playbackState === MprisPlaybackState.Playing
        onTriggered: root.player.positionChanged()
    }

    // The bar holds its hairline back over the sheet's span, flares included,
    // so the line meets the arcs instead of cutting across the sheet.
    Binding {
        target: Globals
        property: "notchWidth"
        value: Math.round((sheet.width + 40) * (1 - root.offsetScale))
        when: root.open && Globals.focusedScreen === root.screenName
            && !Globals.dashboard
        restoreMode: Binding.RestoreNone
    }

    // The bar measures in screen coordinates, this window in its own — the
    // compositor parks it past the rail's exclusive zone.
    readonly property real screenInset: (screen?.width ?? width) - width

    Binding {
        target: Globals
        property: "notchX"
        value: Math.round(root.screenInset + sheet.x - 20 * (1 - root.offsetScale))
        when: root.open && Globals.focusedScreen === root.screenName
            && !Globals.dashboard
        restoreMode: Binding.RestoreNone
    }

    // Concave wedges either side: the sheet reads as carved out of the bar
    // rather than glued under it.  ──\____/──
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

        width: 380
        height: 116

        // The corner swells while the sheet is still attached to the bar and
        // relaxes as it lands — a drop pinching off a lip, not a box sliding.
        radius: Theme.radius + 4 + 12 * root.offsetScale
        squareTop: true

        // Opacity trails the slide slightly (the 1.4x, clamped), so the sheet
        // is already most of the way down before it reads as solid.
        opacity: Math.max(0, 1 - root.offsetScale * 1.4)

        // A HoverHandler, not a MouseArea: the buttons' own MouseAreas sit on
        // top and would take the hover away from a MouseArea underneath them,
        // which closed the sheet the moment you reached for a control.
        HoverHandler {
            id: sheetHover
        }

        // scroll the sheet to set volume — the pointer is already here
        WheelHandler {
            onWheel: event => Audio.setVolume(
                Audio.volume + (event.angleDelta.y > 0 ? 0.02 : -0.02))
        }

        Scanlines {
            radius: sheet.radius
            squareTop: true
            z: 200
        }

        Brackets {
            anchors.margins: 3
            topLeft: false
            bottomLeft: true
            bottomRight: true
            z: 201
        }

        // Contents drag behind the sheet by a few pixels and catch up at the
        // end — surface tension, the same reason the flares overshoot.
        Row {
            anchors.fill: parent
            anchors.margins: 16
            anchors.topMargin: 16 - 10 * root.offsetScale
            spacing: 14

            // ---- album art ------------------------------------------------
            Rectangle {
                id: art

                width: 84
                height: 84

                // Rounds hard while it is still folded away, so the art reads
                // as a bead that squares itself off once it settles.
                radius: 10 + 26 * root.offsetScale
                scale: 1 - 0.08 * root.offsetScale
                color: Theme.alpha(Theme.surfaceAlt, 0.9)

                ClippingRectangle {
                    anchors.fill: parent
                    color: "transparent"
                    radius: art.radius

                    Image {
                        anchors.fill: parent
                        source: root.player?.trackArtUrl ?? ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: status === Image.Ready
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: (root.player?.trackArtUrl ?? "") === ""
                    text: ""
                    color: Theme.faint
                    font.family: Theme.fontIcon
                    font.pixelSize: 28
                }
            }

            // ---- track + transport ------------------------------------------
            Column {
                width: parent.width - art.width - parent.spacing
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Text {
                    width: parent.width
                    text: root.player?.trackTitle ?? "Nothing playing"
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize + 2
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: root.player?.trackArtist ?? ""
                    color: Theme.subtext
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSizeSm
                    elide: Text.ElideRight
                    visible: text !== ""
                }

                // Progress, and a seek target. The hairline stays a hairline —
                // the hit area is a taller transparent strip around it, so it
                // can be hit without the bar itself getting chunky.
                Item {
                    id: seek

                    width: parent.width
                    height: 14
                    visible: (root.player?.length ?? 0) > 0

                    readonly property bool seekable: root.player?.canSeek ?? false

                    function seekTo(x) {
                        const p = root.player;
                        if (!p || !seek.seekable || !(p.length > 0))
                            return;
                        p.position = Math.max(0, Math.min(1, x / seek.width)) * p.length;
                    }

                    Rectangle {
                        id: track

                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: bar.containsMouse && seek.seekable ? 5 : 3
                        radius: height / 2
                        color: Theme.alpha(Theme.text, 0.1)

                        Behavior on height { NumberAnimation { duration: Theme.animFast } }

                        Rectangle {
                            id: fill

                            width: parent.width * Math.max(0, Math.min(1,
                                (root.player?.position ?? 0) / (root.player?.length ?? 1)))
                            height: parent.height
                            radius: parent.radius
                            color: Theme.accent

                            // Bloom under the fill, so the played part reads
                            // wet rather than printed.
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right
                                width: Math.min(parent.width, 56)
                                height: parent.height + 6
                                radius: height / 2
                                color: Theme.alpha(Theme.accent, 0.22)
                                z: -1
                            }

                            // No easing while dragging: the handle would lag the
                            // pointer, which reads as the seek not taking.
                            Behavior on width {
                                enabled: !bar.pressed
                                NumberAnimation { duration: Theme.animMed }
                            }
                        }

                        // Grabbable head, only once the strip is under the pointer
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            x: fill.width - width / 2
                            width: 9
                            height: 9
                            radius: 4.5
                            color: Theme.accent
                            opacity: bar.containsMouse && seek.seekable ? 1 : 0

                            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                        }
                    }

                    MouseArea {
                        id: bar

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: seek.seekable
                            ? Qt.PointingHandCursor
                            : Qt.ArrowCursor

                        onPressed: mouse => seek.seekTo(mouse.x)
                        onPositionChanged: mouse => {
                            if (pressed)
                                seek.seekTo(mouse.x);
                        }
                    }
                }

                // ---- transport + player switcher ---------------------------
                Item {
                    width: parent.width
                    height: 28

                    Row {
                        anchors.left: parent.left
                        spacing: 2

                        Repeater {
                            model: [
                                { glyph: "", act: "previous" },
                                { glyph: "", act: "toggle" },
                                { glyph: "", act: "next" }
                            ]

                            Rectangle {
                                required property var modelData

                                width: 28
                                height: 28

                                // Full round, and it squashes under the press:
                                // the control gives like a bead of liquid
                                // instead of clicking like a key.
                                radius: height / 2
                                color: btn.pressed
                                    ? Theme.alpha(Theme.accent, 0.22)
                                    : btn.containsMouse
                                        ? Theme.surfaceHover
                                        : "transparent"

                                scale: btn.pressed ? 0.88 : 1

                                Behavior on color { CMorph { duration: Theme.animFast } }
                                Behavior on scale { Morph { duration: Theme.animMed } }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.act === "toggle"
                                        && root.player?.playbackState === MprisPlaybackState.Playing
                                            ? "" : modelData.glyph
                                    color: Theme.text
                                    font.family: Theme.fontIcon
                                    font.pixelSize: 14
                                }

                                MouseArea {
                                    id: btn

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor

                                    onClicked: {
                                        const p = root.player;
                                        if (!p)
                                            return;
                                        if (modelData.act === "next")
                                            p.next();
                                        else if (modelData.act === "previous")
                                            p.previous();
                                        else
                                            p.togglePlaying();
                                    }
                                }
                            }
                        }
                    }

                // Only worth showing with something to switch *to*. Clicking a
                // source pins it; clicking the pinned one hands control back to
                // the scorer.
                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        visible: Player.sources.length > 1

                        Repeater {
                            model: Player.sources

                            Rectangle {
                                id: srcItem

                                required property var modelData

                                readonly property bool selected:
                                    root.player?.dbusName === modelData.dbusName

                                width: 24
                                height: 24
                                radius: Theme.radiusSm

                                color: selected
                                    ? Theme.alpha(Theme.accent, 0.16)
                                    : pick.containsMouse
                                        ? Theme.surfaceHover
                                        : "transparent"

                                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                AppIcon {
                                    anchors.centerIn: parent
                                    size: 14
                                    glyph: ""
                                    glyphColor: srcItem.selected
                                        ? Theme.accent
                                        : Theme.subtext
                                    opacity: srcItem.selected ? 1 : 0.55
                                    name: DesktopEntries.heuristicLookup(
                                        srcItem.modelData.desktopEntry
                                            ?? srcItem.modelData.identity ?? ""
                                    )?.icon ?? ""
                                }

                                MouseArea {
                                    id: pick

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor

                                    onClicked: Player.pin(
                                        srcItem.selected ? "" : srcItem.modelData.dbusName)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
