import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Mpris
import QtQuick

import "root:/"
import "root:/components"
import "root:/services"

PanelWindow {
    id: root

    required property string screenName

    readonly property bool shouldOpen:
        Globals.dashboard && Globals.focusedScreen === screenName

    property real offsetScale: shouldOpen ? 0 : 1

    readonly property bool open: offsetScale < 1

    readonly property var player: Player.current

    property int tab: 0

    visible: open

    WlrLayershell.namespace: "kyber-dashboard"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    color: "transparent"
    exclusiveZone: 0

    Behavior on offsetScale {
        Morph {}
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    MouseArea {
        anchors.fill: parent
        focus: true
        onClicked: Globals.dashboard = false
        Keys.onEscapePressed: Globals.dashboard = false
    }

    Binding {
        target: Globals
        property: "notchWidth"
        value: Math.round((sheet.width + 32) * (1 - root.offsetScale))
        when: root.open && Globals.focusedScreen === root.screenName
        restoreMode: Binding.RestoreNone
    }

    readonly property real screenInset: (screen?.width ?? width) - width

    Binding {
        target: Globals
        property: "notchX"
        value: Math.round(root.screenInset + sheet.x - 16 * (1 - root.offsetScale))
        when: root.open && Globals.focusedScreen === root.screenName
        restoreMode: Binding.RestoreNone
    }

    FlareCorner {
        anchors.right: sheet.left
        anchors.rightMargin: -1
        anchors.top: parent.top
        size: 16 * (1 - root.offsetScale)
        z: 1
    }

    FlareCorner {
        anchors.left: sheet.right
        anchors.leftMargin: -1
        anchors.top: parent.top
        size: 16 * (1 - root.offsetScale)
        mirrored: true
        z: 1
    }

    GlassPanel {
        id: sheet

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: -(height + Theme.gap) * root.offsetScale

        width: Math.max(view.width, tabs.width) + 32
        height: tabs.height + view.height + 44

        radius: Theme.radius + 4
        squareTop: true
        opacity: 1 - root.offsetScale

        MouseArea {
            anchors.fill: parent
        }

        Brackets {
            anchors.margins: 4
            topLeft: false
            bottomLeft: true
            bottomRight: true
            z: 200
        }

        component Card: Rectangle {
            radius: 14
            color: Theme.well
        }

        component Label: Text {
            color: Theme.faint
            font.family: Theme.fontMono
            font.pixelSize: 9
            font.letterSpacing: 1.2
        }

        component Meter: Column {
            id: meter

            property real value: 0
            property string caption: ""
            property string readout: ""

            spacing: 5

            Row {
                width: meter.width

                Label { text: meter.caption }

                Item { width: meter.width - 120; height: 1 }

                Text {
                    text: meter.readout
                    color: Theme.subtext
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                }
            }

            Rectangle {
                width: meter.width
                height: 6
                radius: 3
                color: Theme.alpha(Theme.text, 0.1)

                Rectangle {
                    width: parent.width * Math.max(0.01, Math.min(1, meter.value))
                    height: parent.height
                    radius: parent.radius
                    color: meter.value > 0.85 ? Theme.red : Theme.accent

                    Behavior on width { Morph {} }
                }
            }
        }

        component Pillar: Item {
            id: pillar

            property real value: 0
            property string glyph: ""

            width: 22

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                width: 6
                height: parent.height - 20
                radius: 3
                color: Theme.alpha(Theme.text, 0.1)

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: parent.height * Math.max(0.01, Math.min(1, pillar.value))
                    radius: parent.radius
                    color: pillar.value > 0.85 ? Theme.red : Theme.accent

                    Behavior on height { Morph {} }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                text: pillar.glyph
                color: Theme.faint
                font.family: Theme.fontIcon
                font.pixelSize: 11
            }
        }

        component Art: Rectangle {
            id: art

            property string source: ""
            property bool round: false

            color: Theme.alpha(Theme.surfaceAlt, 0.9)
            radius: 10

            ClippingRectangle {
                anchors.fill: parent
                color: "transparent"
                radius: art.radius

                Image {
                    anchors.fill: parent
                    source: art.source
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: status === Image.Ready
                }
            }

            Text {
                anchors.centerIn: parent
                visible: art.source === ""
                text: ""
                color: Theme.faint
                font.family: Theme.fontIcon
                font.pixelSize: art.width / 3
            }
        }

        component MediaControls: Row {
            spacing: 4

            Repeater {
                model: [
                    { glyph: "", act: "previous" },
                    { glyph: "", act: "toggle" },
                    { glyph: "", act: "next" }
                ]

                Rectangle {
                    required property var modelData

                    width: 32
                    height: 32
                    radius: Theme.radiusSm
                    color: btn.containsMouse ? Theme.surfaceHover : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: modelData.act === "toggle"
                            && root.player?.playbackState === MprisPlaybackState.Playing
                                ? "" : modelData.glyph
                        color: Theme.text
                        font.family: Theme.fontIcon
                        font.pixelSize: 16
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

        Item {
            id: tabs

            anchors.top: parent.top
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter

            readonly property real cell: 150

            width: cell * model.length
            height: 52

            readonly property var model: [
                { glyph: "", name: "Dashboard" },
                { glyph: "", name: "Media" },
                { glyph: "", name: "Performance" },
                { glyph: "", name: "Workspaces" },
                { glyph: "", name: "Agenda" }
            ]

            Repeater {
                model: tabs.model

                Item {
                    id: tabItem

                    required property var modelData
                    required property int index

                    readonly property bool current: root.tab === index

                    x: tabs.cell * index
                    width: tabs.cell
                    height: tabs.height - 4

                    Column {
                        anchors.centerIn: parent
                        spacing: 3

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: tabItem.modelData.glyph
                            color: tabItem.current
                                ? Theme.text
                                : tabMouse.containsMouse ? Theme.subtext : Theme.faint
                            font.family: Theme.fontIcon
                            font.pixelSize: 15

                            Behavior on color { CMorph {} }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: tabItem.modelData.name
                            color: tabItem.current
                                ? Theme.text
                                : tabMouse.containsMouse ? Theme.subtext : Theme.faint
                            font.family: Theme.font
                            font.pixelSize: 11

                            Behavior on color { CMorph {} }
                        }
                    }

                    MouseArea {
                        id: tabMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.tab = tabItem.index
                        onWheel: wheel => root.tab = Math.max(0, Math.min(
                            tabs.model.length - 1,
                            root.tab + (wheel.angleDelta.y < 0 ? 1 : -1)))
                    }
                }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                x: tabs.cell * root.tab + 6
                width: tabs.cell - 12
                height: parent.height - 10
                radius: Theme.radiusSm
                z: -1
                color: Theme.alpha(Theme.accent, 0.18)

                Behavior on x { Morph {} }
                Behavior on width { Morph {} }
            }
        }

        Rectangle {
            id: rule

            anchors.top: tabs.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 1
            height: 1
            color: Theme.alpha(Theme.text, 0.08)
        }

        ClippingRectangle {
            id: view

            anchors.top: rule.bottom
            anchors.topMargin: 14
            anchors.horizontalCenter: parent.horizontalCenter

            readonly property Item currentPane: panes.children[root.tab] ?? null

            width: currentPane?.implicitWidth ?? 820
            height: currentPane?.implicitHeight ?? 440
            color: "transparent"
            radius: 14

            Behavior on width { Morph {} }
            Behavior on height { Morph {} }

            Row {
                id: panes

                spacing: 40
                x: -(view.currentPane?.x ?? 0)

                Behavior on x { Morph {} }

                Item {
                    id: dashPane

                    implicitWidth: 820
                    implicitHeight: 440

                    width: implicitWidth
                    height: implicitHeight

                    readonly property real mediaWidth: 210
                    readonly property real leftWidth: width - mediaWidth - 12

                    Card {
                        id: weatherCard

                        width: (dashPane.leftWidth - 12) * 0.4
                        height: 100

                        Row {
                            anchors.centerIn: parent
                            spacing: 14

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Weather.icon
                                color: Theme.amber
                                font.family: Theme.fontIcon
                                font.pixelSize: 40
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Text {
                                    text: Weather.ready ? `${Weather.temp}°C` : "--"
                                    color: Theme.text
                                    font.family: Theme.font
                                    font.pixelSize: 30
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    text: Weather.ready ? Weather.condition : "no data"
                                    color: Theme.subtext
                                    font.family: Theme.font
                                    font.pixelSize: 11
                                }
                            }
                        }
                    }

                    Card {
                        id: hostCard

                        anchors.left: weatherCard.right
                        anchors.leftMargin: 12
                        width: dashPane.leftWidth - weatherCard.width - 12
                        height: 100

                        Row {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 14

                            Art {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 66
                                height: 66
                                round: true
                                source: root.player?.trackArtUrl ?? ""
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6

                                Repeater {
                                    model: [
                                        { glyph: "", value: SysInfo.distro },
                                        { glyph: "", value: SysInfo.wm },
                                        { glyph: "", value: `up ${SysInfo.uptime}` }
                                    ]

                                    Row {
                                        required property var modelData

                                        spacing: 8

                                        Text {
                                            text: modelData.glyph
                                            color: Theme.subtext
                                            font.family: Theme.fontIcon
                                            font.pixelSize: 12
                                        }

                                        Text {
                                            text: modelData.value
                                            color: Theme.text
                                            font.family: Theme.font
                                            font.pixelSize: 12
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Card {
                        id: clockCard

                        anchors.top: weatherCard.bottom
                        anchors.topMargin: 12
                        anchors.bottom: parent.bottom
                        width: 92

                        Column {
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: Qt.formatDateTime(clock.date, "HH")
                                color: Theme.text
                                font.family: Theme.font
                                font.pixelSize: 30
                                font.weight: Font.DemiBold
                            }

                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 4

                                Repeater {
                                    model: 3

                                    Rectangle {
                                        width: 4
                                        height: 4
                                        radius: 2
                                        color: Theme.faint
                                    }
                                }
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: Qt.formatDateTime(clock.date, "mm")
                                color: Theme.text
                                font.family: Theme.font
                                font.pixelSize: 30
                                font.weight: Font.DemiBold
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                topPadding: 6
                                text: Qt.formatDate(clock.date, "ddd, d")
                                color: Theme.amber
                                font.family: Theme.font
                                font.pixelSize: 11
                            }
                        }
                    }

                    Card {
                        id: calendarCard

                        anchors.left: clockCard.right
                        anchors.leftMargin: 12
                        anchors.top: clockCard.top
                        anchors.bottom: parent.bottom
                        width: dashPane.leftWidth - clockCard.width - pillarCard.width - 24

                        readonly property date today: clock.date
                        readonly property bool shamsi: Calendar.shamsiPrimary

                        readonly property var jToday: Calendar.toJalali(today)

                        readonly property string monthLabel: shamsi
                            ? `${Calendar.monthsFa[jToday.m - 1]} ${jToday.y}`
                            : Qt.formatDate(today, "MMMM yyyy")

                        readonly property string subLabel: shamsi
                            ? Qt.formatDate(today, "MMMM yyyy")
                            : `${Calendar.monthsFa[jToday.m - 1]} ${jToday.y}`

                        readonly property var days: {
                            const out = [];
                            const today = calendarCard.today;

                            if (calendarCard.shamsi) {
                                const j = Calendar.toJalali(today);
                                const first = Calendar.fromJalali(j.y, j.m, 1);
                                const lead = (first.getDay() + 1) % 7;
                                const len = Calendar.jalaliMonthLength(j.y, j.m);

                                for (let i = 0; i < 42; i++) {
                                    const offset = i - lead;
                                    const d = new Date(first);
                                    d.setDate(first.getDate() + offset);
                                    const jd = Calendar.toJalali(d);
                                    out.push({
                                        day: jd.d,
                                        alt: d.getDate(),
                                        inMonth: offset >= 0 && offset < len,
                                        isToday: d.toDateString() === today.toDateString(),
                                        busy: Calendar.eventsOn(d).length > 0
                                    });
                                }
                                return out;
                            }

                            const y = today.getFullYear();
                            const m = today.getMonth();
                            const first = new Date(y, m, 1);
                            const lead = (first.getDay() + 6) % 7;

                            for (let i = 0; i < 42; i++) {
                                const d = new Date(y, m, i - lead + 1);
                                out.push({
                                    day: d.getDate(),
                                    alt: Calendar.toJalali(d).d,
                                    inMonth: d.getMonth() === m,
                                    isToday: d.toDateString() === today.toDateString(),
                                    busy: Calendar.eventsOn(d).length > 0
                                });
                            }
                            return out;
                        }

                        Column {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 6

                            Row {
                                width: parent.width
                                spacing: 8

                                Column {
                                    width: parent.width - toggle.width - 8
                                    spacing: 1

                                    Text {
                                        text: calendarCard.monthLabel
                                        color: Theme.text
                                        font.family: Theme.font
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                    }

                                    Text {
                                        text: calendarCard.subLabel
                                        color: Theme.faint
                                        font.family: Theme.fontMono
                                        font.pixelSize: 9
                                        font.letterSpacing: Theme.trackingWide
                                    }
                                }

                                Rectangle {
                                    id: toggle

                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 44
                                    height: 20
                                    radius: Theme.radiusSm
                                    color: toggleMouse.containsMouse
                                        ? Theme.surfaceHover
                                        : Theme.alpha(Theme.surface, 0.7)
                                    border.width: 1
                                    border.color: Theme.rimSoft

                                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: calendarCard.shamsi ? "SHAMSI" : "GREG"
                                        color: calendarCard.shamsi ? Theme.accent : Theme.subtext
                                        font.family: Theme.fontMono
                                        font.pixelSize: 9
                                        font.letterSpacing: Theme.trackingWide
                                    }

                                    MouseArea {
                                        id: toggleMouse

                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Calendar.togglePrimary()
                                    }
                                }
                            }

                            Grid {
                                anchors.horizontalCenter: parent.horizontalCenter
                                columns: 7
                                columnSpacing: 3
                                rowSpacing: 1

                                Repeater {
                                    model: calendarCard.shamsi
                                        ? Calendar.weekdaysFa
                                        : ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

                                    Text {
                                        required property string modelData

                                        width: 40
                                        horizontalAlignment: Text.AlignHCenter
                                        text: modelData
                                        color: Theme.subtext
                                        font.family: Theme.font
                                        font.pixelSize: 10
                                        font.weight: Font.DemiBold
                                    }
                                }

                                Repeater {
                                    model: calendarCard.days

                                    Rectangle {
                                        required property var modelData

                                        width: 40
                                        height: 24
                                        radius: Theme.radiusSm
                                        color: modelData.isToday
                                            ? Theme.alpha(Theme.accent, 0.28)
                                            : "transparent"

                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 3

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: modelData.day
                                                color: modelData.isToday
                                                    ? Theme.text
                                                    : modelData.inMonth
                                                        ? Theme.subtext
                                                        : Theme.faint
                                                font.family: Theme.font
                                                font.pixelSize: 11
                                            }

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: modelData.alt
                                                color: Theme.faint
                                                opacity: modelData.inMonth ? 0.75 : 0.4
                                                font.family: Theme.fontMono
                                                font.pixelSize: 7
                                            }
                                        }

                                        Rectangle {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            anchors.bottom: parent.bottom
                                            anchors.bottomMargin: 1

                                            width: 8
                                            height: 1
                                            visible: modelData.busy && modelData.inMonth
                                            color: Theme.accent
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Card {
                        id: pillarCard

                        anchors.right: dashMediaCard.left
                        anchors.rightMargin: 12
                        anchors.top: clockCard.top
                        anchors.bottom: parent.bottom
                        width: 110

                        Row {
                            anchors.centerIn: parent
                            spacing: 16

                            Pillar {
                                height: pillarCard.height - 28
                                glyph: ""
                                value: SysInfo.cpu
                            }

                            Pillar {
                                height: pillarCard.height - 28
                                glyph: ""
                                value: SysInfo.memory
                            }

                            Pillar {
                                height: pillarCard.height - 28
                                glyph: ""
                                value: Battery.available ? Battery.level : 1
                            }
                        }
                    }

                    Card {
                        id: dashMediaCard

                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: dashPane.mediaWidth

                        Column {
                            anchors.centerIn: parent
                            spacing: 10
                            width: parent.width - 24

                            Art {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 140
                                height: 140
                                round: true
                                source: root.player?.trackArtUrl ?? ""
                            }

                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                text: root.player?.trackTitle ?? "Nothing playing"
                                color: Theme.text
                                font.family: Theme.font
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                text: root.player?.trackArtist ?? ""
                                color: Theme.subtext
                                font.family: Theme.font
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                text: root.player?.trackAlbum ?? ""
                                visible: text !== ""
                                color: Theme.faint
                                font.family: Theme.font
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }

                            MediaControls {
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }
                }

                Item {
                    implicitWidth: 640
                    implicitHeight: 280

                    width: implicitWidth
                    height: implicitHeight

                    Card {
                        anchors.fill: parent

                        Column {
                            anchors.centerIn: parent
                            width: parent.width - 44
                            spacing: 16

                            Item {
                                width: parent.width
                                height: 22

                                Row {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 8

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "ACCENT FROM COVER"
                                        color: Theme.faint
                                        font.family: Theme.fontMono
                                        font.pixelSize: 9
                                        font.letterSpacing: Theme.trackingWide
                                    }

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 12
                                        height: 12
                                        radius: 3
                                        color: Accent.valid ? Accent.color : Theme.faint
                                        border.width: 1
                                        border.color: Theme.rimSoft

                                        Behavior on color { CMorph {} }
                                    }
                                }

                                Row {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 4

                                    Repeater {
                                        model: [
                                            { key: "off", label: "OFF" },
                                            { key: "peek", label: "PEEK" },
                                            { key: "system", label: "SYSTEM" }
                                        ]

                                        Rectangle {
                                            id: accentSeg

                                            required property var modelData

                                            readonly property bool on:
                                                Accent.mode === modelData.key

                                            width: 58
                                            height: 22
                                            radius: Theme.radiusSm

                                            color: accentSeg.on
                                                ? Theme.alpha(Theme.accent, 0.2)
                                                : segMouse.containsMouse
                                                    ? Theme.surfaceHover
                                                    : Theme.alpha(Theme.surface, 0.7)

                                            border.width: 1
                                            border.color: accentSeg.on
                                                ? Theme.alpha(Theme.accent, 0.4)
                                                : Theme.rimSoft

                                            Behavior on color { CMorph { duration: Theme.animFast } }

                                            Text {
                                                anchors.centerIn: parent
                                                text: accentSeg.modelData.label
                                                color: accentSeg.on ? Theme.accent : Theme.subtext
                                                font.family: Theme.fontMono
                                                font.pixelSize: 9
                                                font.letterSpacing: Theme.trackingWide
                                            }

                                            MouseArea {
                                                id: segMouse

                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: Accent.mode = accentSeg.modelData.key
                                            }
                                        }
                                    }
                                }
                            }

                            Row {
                                spacing: 20

                                Art {
                                    width: 150
                                    height: 150
                                    source: root.player?.trackArtUrl ?? ""
                                }

                                NeonSlider {
                                    width: 56
                                    height: 150
                                    icon: Audio.icon
                                    value: Audio.volume
                                    onMoved: v => Audio.setVolume(v)
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 304
                                    spacing: 8

                                    Label { text: root.player?.identity ?? "NO PLAYER" }

                                    Text {
                                        width: parent.width
                                        text: root.player?.trackTitle ?? "Nothing playing"
                                        color: Theme.text
                                        font.family: Theme.font
                                        font.pixelSize: 20
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        width: parent.width
                                        text: root.player?.trackArtist ?? ""
                                        color: Theme.subtext
                                        font.family: Theme.font
                                        font.pixelSize: 13
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        width: parent.width
                                        text: root.player?.trackAlbum ?? ""
                                        color: Theme.faint
                                        font.family: Theme.font
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                    }

                                    MediaControls {}
                                }
                            }
                        }
                    }
                }

                Item {
                    implicitWidth: 560
                    implicitHeight: 260

                    width: implicitWidth
                    height: implicitHeight

                    Card {
                        anchors.fill: parent

                        Column {
                            anchors.centerIn: parent
                            width: parent.width - 44
                            spacing: 20

                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 28

                                Ring {
                                    width: 104
                                    height: 104
                                    caption: "CPU"
                                    tint: Theme.accent
                                    value: SysInfo.cpu
                                    readout: `${Math.round(SysInfo.cpu * 100)}%`
                                }

                                Ring {
                                    width: 104
                                    height: 104
                                    caption: "MEMORY"
                                    tint: Theme.cyan
                                    value: SysInfo.memory
                                    readout: `${Math.round(SysInfo.memory * 100)}%`
                                }

                                Ring {
                                    width: 104
                                    height: 104
                                    visible: Battery.available
                                    caption: "BATTERY"
                                    warnHigh: false
                                    tint: Theme.magenta
                                    value: Battery.level
                                    readout: `${Battery.percent}%`
                                }
                            }

                            Row {
                                spacing: 26

                                Repeater {
                                    model: [
                                        { k: "HOST", v: SysInfo.host || SysInfo.user },
                                        { k: "DISTRO", v: SysInfo.distro },
                                        { k: "UPTIME", v: SysInfo.uptime },
                                        { k: "NET DOWN", v: SysInfo.formatRate(SysInfo.rxRate) },
                                        { k: "NET UP", v: SysInfo.formatRate(SysInfo.txRate) }
                                    ]

                                    Column {
                                        required property var modelData

                                        spacing: 4

                                        Label { text: modelData.k }

                                        Text {
                                            text: modelData.v
                                            color: Theme.text
                                            font.family: Theme.font
                                            font.pixelSize: 12
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Item {
                    implicitWidth: 520
                    implicitHeight: 220

                    width: implicitWidth
                    height: implicitHeight

                    Card {
                        anchors.fill: parent

                        Flow {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 10

                            Repeater {
                                model: Hyprland.workspaces

                                Rectangle {
                                    id: ws

                                    required property var modelData

                                    readonly property bool current:
                                        Hyprland.focusedWorkspace?.id === modelData.id

                                    width: 88
                                    height: 62
                                    radius: 12

                                    color: current
                                        ? Theme.alpha(Theme.accent, 0.26)
                                        : wsMouse.containsMouse
                                            ? Theme.surfaceHover
                                            : Theme.alpha(Theme.surfaceAlt, 0.8)

                                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                    Column {
                                        anchors.centerIn: parent
                                        width: parent.width - 12
                                        spacing: 2

                                        Text {
                                            width: parent.width
                                            horizontalAlignment: Text.AlignHCenter
                                            elide: Text.ElideRight
                                            text: (ws.modelData.name ?? ws.modelData.id)
                                                .toString().replace(/^special:/, "")
                                            color: Theme.text
                                            font.family: Theme.font
                                            font.pixelSize: 16
                                            font.weight: Font.DemiBold
                                        }

                                        Text {
                                            width: parent.width
                                            horizontalAlignment: Text.AlignHCenter
                                            elide: Text.ElideRight
                                            text: ws.modelData.monitor?.name ?? ""
                                            color: Theme.faint
                                            font.family: Theme.fontMono
                                            font.pixelSize: 9
                                        }
                                    }

                                    MouseArea {
                                        id: wsMouse

                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor

                                        onClicked: {
                                            Globals.focusWorkspace(ws.modelData.id);
                                            Globals.dashboard = false;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Item {
                    id: agendaPane

                    implicitWidth: 560
                    implicitHeight: 300

                    width: implicitWidth
                    height: implicitHeight

                    Card {
                        anchors.fill: parent

                        Column {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 10

                            Row {
                                width: parent.width
                                spacing: 8

                                Column {
                                    width: parent.width - 120
                                    spacing: 1

                                    Text {
                                        text: Calendar.shamsiPrimary
                                            ? Calendar.jalaliLabel(clock.date)
                                            : Qt.formatDate(clock.date, "dddd, d MMMM yyyy")
                                        color: Theme.text
                                        font.family: Theme.font
                                        font.pixelSize: 15
                                        font.weight: Font.DemiBold
                                    }

                                    Text {
                                        text: Calendar.shamsiPrimary
                                            ? Qt.formatDate(clock.date, "dddd, d MMMM yyyy")
                                            : Calendar.jalaliLabel(clock.date)
                                        color: Theme.faint
                                        font.family: Theme.font
                                        font.pixelSize: 10
                                    }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: Calendar.upcoming.length > 0
                                        ? Calendar.upcoming.length + " UPCOMING"
                                        : "CLEAR"
                                    color: Theme.faint
                                    font.family: Theme.fontMono
                                    font.pixelSize: 9
                                    font.letterSpacing: Theme.trackingWide
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 1
                                color: Theme.alpha(Theme.faint, 0.4)
                            }

                            Text {
                                width: parent.width
                                visible: Calendar.upcoming.length === 0
                                text: "NOTHING SCHEDULED \u00b7 ~/.config/kyber/agenda.txt"
                                color: Theme.faint
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                font.letterSpacing: Theme.trackingWide
                            }

                            Repeater {
                                model: Calendar.upcoming.slice(0, 6)

                                Row {
                                    id: agendaRow

                                    required property var modelData

                                    readonly property bool isToday:
                                        modelData.date.toDateString()
                                            === clock.date.toDateString()

                                    width: parent.width
                                    height: 34
                                    spacing: 12

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 2
                                        height: 20
                                        radius: 1
                                        color: agendaRow.isToday ? Theme.accent : Theme.faint
                                    }

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 96
                                        spacing: 1

                                        Text {
                                            text: agendaRow.isToday
                                                ? "TODAY"
                                                : Qt.formatDate(agendaRow.modelData.date, "ddd d MMM")
                                            color: agendaRow.isToday ? Theme.accent : Theme.subtext
                                            font.family: Theme.fontMono
                                            font.pixelSize: 9
                                            font.letterSpacing: Theme.trackingWide
                                        }

                                        Text {
                                            text: Calendar.jalaliLabel(agendaRow.modelData.date)
                                            color: Theme.faint
                                            font.family: Theme.font
                                            font.pixelSize: 9
                                        }
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 44
                                        text: agendaRow.modelData.time
                                        color: Theme.subtext
                                        font.family: Theme.fontMono
                                        font.pixelSize: 10
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width - 178
                                        text: agendaRow.modelData.title
                                        color: Theme.text
                                        font.family: Theme.font
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
