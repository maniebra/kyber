import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Shapes

import "root:/"
import "root:/components"
import "root:/services"

PanelWindow {
    id: root

    required property string screenName

    readonly property var player: Player.current

    readonly property color accent:
        Accent.mode === "off" ? Theme.accent : Accent.color

    readonly property bool wantOpen:
        (Globals.mediaDotHovered || sheetHover.hovered)
        && Globals.focusedScreen === screenName
        && player !== null
        && !Globals.dashboard && !Globals.controlCenter

    property bool shouldOpen: false

    Timer {
        id: settle

        interval: root.wantOpen ? 220 : 160
        running: root.wantOpen !== root.shouldOpen
        onTriggered: root.shouldOpen = root.wantOpen
    }

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

    mask: Region {
        item: sheet
    }

    Binding {
        target: Globals
        property: "mediaPeek"
        value: root.shouldOpen
        when: Globals.focusedScreen === root.screenName
        restoreMode: Binding.RestoreBindingOrValue
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.open
            && root.player?.playbackState === MprisPlaybackState.Playing
        onTriggered: root.player.positionChanged()
    }

    Binding {
        target: Globals
        property: "notchWidth"
        value: Math.round((sheet.width + 40) * (1 - root.offsetScale))
        when: root.open && Globals.focusedScreen === root.screenName
            && !Globals.dashboard
        restoreMode: Binding.RestoreNone
    }

    readonly property real screenInset: (screen?.width ?? width) - width

    Binding {
        target: Globals
        property: "notchX"
        value: Math.round(root.screenInset + sheet.x - 20 * (1 - root.offsetScale))
        when: root.open && Globals.focusedScreen === root.screenName
            && !Globals.dashboard
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

        width: 380
        height: 116

        radius: Theme.radius + 4 + 12 * root.offsetScale
        squareTop: true

        opacity: Math.max(0, 1 - root.offsetScale * 1.4)

        HoverHandler {
            id: sheetHover
        }

        WheelHandler {
            onWheel: event => Audio.setVolume(
                Audio.volume + (event.angleDelta.y > 0 ? 0.02 : -0.02))
        }

        ClippingRectangle {
            id: viz

            anchors.fill: parent
            anchors.margins: 1
            color: "transparent"
            radius: sheet.radius - 1
            z: 1
            opacity: Spectrum.active ? 1 : 0

            Behavior on opacity { NumberAnimation { duration: Theme.animMed } }

            readonly property int resolution: 90
            readonly property real floorY: height - 1

            property var smoothed: new Array(Spectrum.bandCount).fill(0)

            Timer {
                interval: 16
                running: viz.opacity > 0
                repeat: true

                onTriggered: {
                    const target = Spectrum.bars;
                    const cur = viz.smoothed;
                    const out = [];

                    for (let i = 0; i < cur.length; i++) {
                        const t = target[i] ?? 0;
                        const rate = t > cur[i] ? 0.45 : 0.16;
                        out.push(cur[i] + (t - cur[i]) * rate);
                    }

                    viz.smoothed = out;
                }
            }

            readonly property var curve: {
                const src = viz.smoothed;
                const n = src.length;
                const pts = [];

                for (let i = 0; i < viz.resolution; i++) {
                    const x = i / (viz.resolution - 1) * (n - 1);
                    const i0 = Math.floor(x);
                    const i1 = Math.min(n - 1, i0 + 1);
                    const f = x - i0;
                    const smooth = (1 - Math.cos(f * Math.PI)) / 2;
                    const v = src[i0] * (1 - smooth) + src[i1] * smooth;

                    pts.push(Qt.point(
                        i / (viz.resolution - 1) * viz.width,
                        viz.floorY - v * viz.height * 0.66
                    ));
                }

                return pts;
            }

            readonly property var filled: {
                const pts = [Qt.point(0, viz.floorY)];
                for (const p of viz.curve)
                    pts.push(p);
                pts.push(Qt.point(viz.width, viz.floorY));
                return pts;
            }

            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                asynchronous: false

                ShapePath {
                    strokeWidth: 0
                    strokeColor: "transparent"

                    fillColor: Theme.alpha(root.accent, 0.16)

                    PathPolyline {
                        path: viz.filled
                    }
                }

                ShapePath {
                    strokeWidth: 1.5
                    strokeColor: Qt.lighter(root.accent, 1.35)
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin

                    PathPolyline {
                        path: viz.curve
                    }
                }
            }
        }

        Scanlines {
            radius: sheet.radius
            squareTop: true
            z: 200
        }

        Brackets {
            color: root.accent
            anchors.margins: 3
            topLeft: false
            bottomLeft: true
            bottomRight: true
            z: 201
        }

        Row {
            anchors.fill: parent
            anchors.margins: 16
            anchors.topMargin: 16 - 10 * root.offsetScale
            spacing: 14
            z: 2

            Rectangle {
                id: art

                width: 84
                height: 84

                radius: 10 + 26 * root.offsetScale
                scale: (1 - 0.08 * root.offsetScale) * (1 + Spectrum.bass * 0.06)

                Behavior on scale { NumberAnimation { duration: 90 } }
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
                            color: root.accent

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right
                                width: Math.min(parent.width, 56)
                                height: parent.height + 6
                                radius: height / 2
                                color: Theme.alpha(root.accent, 0.22)
                                z: -1
                            }

                            Behavior on width {
                                enabled: !bar.pressed
                                NumberAnimation { duration: Theme.animMed }
                            }
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            x: fill.width - width / 2
                            width: 9
                            height: 9
                            radius: 4.5
                            color: root.accent
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

                                radius: height / 2
                                color: btn.pressed
                                    ? Theme.alpha(root.accent, 0.22)
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
                                    ? Theme.alpha(root.accent, 0.16)
                                    : pick.containsMouse
                                        ? Theme.surfaceHover
                                        : "transparent"

                                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                AppIcon {
                                    anchors.centerIn: parent
                                    size: 14
                                    glyph: ""
                                    glyphColor: srcItem.selected
                                        ? root.accent
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
