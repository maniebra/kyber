import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Quickshell.Widgets
import QtQuick

import "root:/"
import "root:/components"
import "root:/services"

PanelWindow {
    id: root

    required property string screenName

    readonly property bool shouldOpen:
        Globals.controlCenter && Globals.focusedScreen === screenName

    property real reveal: shouldOpen ? 1 : 0
    Behavior on reveal { Morph {} }

    property int page: 0
    property string pendingSsid: ""

    onPageChanged: {
        pendingSsid = "";
        if (page === 1)
            Network.scan();
    }

    onShouldOpenChanged: {
        if (!shouldOpen)
            page = 0;
    }

    readonly property bool open: reveal > 0

    visible: open

    WlrLayershell.namespace: "kyber-control"
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

    MouseArea {
        anchors.fill: parent
        onClicked: Globals.controlCenter = false
    }

    Binding {
        target: Globals
        property: "notchWidth"
        value: Math.round((panel.width + 16) * root.reveal)
        when: root.open
        restoreMode: Binding.RestoreNone
    }

    readonly property real screenInset: (screen?.width ?? width) - width

    Binding {
        target: Globals
        property: "notchX"
        value: Math.round(root.screenInset + root.width
            - (panel.width + 16) * root.reveal)
        when: root.open
        restoreMode: Binding.RestoreNone
    }

    FlareCorner {
        anchors.right: dropdown.left
        anchors.rightMargin: -1
        anchors.top: parent.top
        size: 16 * root.reveal
        z: 1
    }

    Item {
        id: dropdown

        anchors.right: parent.right

        width: panel.width
        height: panel.height

        y: -height * Math.max(0, 1 - root.reveal)

        opacity: Math.max(0, 1 - (1 - root.reveal) * 1.4)

        GlassPanel {
            id: panel

            width: 340
            height: viewport.height + 28
            radius: Theme.radius + 4
            squareTop: true

            MouseArea {
                anchors.fill: parent
            }

            Brackets {
                anchors.margins: 3
                topLeft: false
                bottomLeft: true
                bottomRight: true
                z: 201
            }

        Item {
            id: viewport

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 14

            readonly property Item current:
                root.page === 1 ? wifiPage : root.page === 2 ? powerPage : mainPage

            height: current.implicitHeight
            clip: true

            Behavior on height { Morph {} }

            Row {
                x: -root.page * viewport.width

                Behavior on x { Morph {} }

                Column {
                    id: mainPage

                    width: viewport.width
                    spacing: 12

            Item {
                width: parent.width
                height: 36

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                Rectangle {
                    width: 36
                    height: 36
                    radius: 5
                    color: Theme.alpha(Theme.cyan, 0.24)
                    border.width: 1
                    border.color: Theme.alpha(Theme.cyan, 0.45)

                    Brackets {
                        inset: 2
                        arm: 6
                        topLeft: true
                        bottomRight: true
                        strength: 1
                    }

                    Text {
                        anchors.centerIn: parent
                        text: (SysInfo.user[0] ?? "?").toUpperCase()
                        color: Theme.cyan
                        font.family: Theme.font
                        font.pixelSize: 16
                        font.bold: true
                    }
                }

                Column {
                    id: identityText

                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Row {
                        spacing: 6

                        Text {
                            text: SysInfo.user.toUpperCase()
                            color: Theme.text
                            font.family: Theme.font
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            font.letterSpacing: Theme.trackingWide
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "//SYS.CTRL"
                            color: Theme.alpha(Theme.accent, 0.7)
                            font.family: Theme.fontMono
                            font.pixelSize: 8
                            font.letterSpacing: Theme.trackingWide
                        }
                    }

                    Text {
                        text: `up ${SysInfo.uptime} · ${SysInfo.memUsedMb}/${SysInfo.memTotalMb} MB`
                        color: Theme.faint
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                    }
                }

                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Repeater {
                    model: [
                        { glyph: "", page: 1, tint: Theme.cyan },
                        { glyph: "", page: 2, tint: Theme.red }
                    ]

                    Rectangle {
                        id: nav

                        required property var modelData

                        anchors.verticalCenter: parent.verticalCenter
                        width: 30
                        height: 30
                        radius: Theme.radiusSm
                        color: navMouse.containsMouse ? Theme.surfaceHover : "transparent"

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        Text {
                            anchors.centerIn: parent
                            text: nav.modelData.glyph
                            color: navMouse.containsMouse ? nav.modelData.tint : Theme.subtext
                            font.family: Theme.fontIcon
                            font.pixelSize: 14
                        }

                        MouseArea {
                            id: navMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.page = nav.modelData.page
                        }
                    }
                    }
                }
            }

            Grid {
                width: parent.width
                columns: 2
                columnSpacing: 8
                rowSpacing: 8

                readonly property real cell: (width - columnSpacing) / 2

                ToggleTile {
                    width: parent.cell
                    icon: Network.type === "ethernet" ? "" : ""
                    label: Network.wifiEnabled ? "Wi-Fi" : "Wi-Fi off"
                    sublabel: Network.label
                    active: Network.connected
                    accent: Theme.cyan

                    onClicked: Network.toggleWifi()
                    onSecondaryClicked: root.page = 1
                }

                ToggleTile {
                    width: parent.cell
                    icon: ""
                    label: "Bluetooth"
                    sublabel: Bluetooth.defaultAdapter
                        ? (Bluetooth.defaultAdapter.enabled ? "On" : "Off")
                        : "No adapter"
                    active: Bluetooth.defaultAdapter?.enabled ?? false
                    accent: Theme.accent

                    onClicked: {
                        if (Bluetooth.defaultAdapter)
                            Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled;
                    }
                }

                ToggleTile {
                    width: parent.cell
                    icon: Globals.dnd ? "" : ""
                    label: "Do not disturb"
                    sublabel: Globals.dnd ? "Silenced" : `${Notifs.count} notifications`
                    active: Globals.dnd
                    accent: Theme.accent

                    onClicked: Globals.dnd = !Globals.dnd
                }

                ToggleTile {
                    width: parent.cell
                    icon: Audio.micMuted ? "" : ""
                    label: "Microphone"
                    sublabel: Audio.micMuted ? "Muted" : "Live"
                    active: !Audio.micMuted
                    accent: Theme.accent

                    onClicked: Audio.toggleMic()
                }
            }

            Row {
                id: mediaRow

                width: parent.width
                height: 150
                spacing: 8

                readonly property int faderWidth: 34
                readonly property int faders: Brightness.available ? 2 : 1

                Rectangle {
                    id: mediaCard

                    width: parent.width
                        - (mediaRow.faderWidth + mediaRow.spacing) * mediaRow.faders
                    height: parent.height
                    radius: Theme.radiusSm + 3
                    color: Theme.alpha(Theme.surface, 0.85)

                    readonly property var mediaPlayer: Player.current

                    Column {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        ClippingRectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 62
                            height: 62
                            radius: Theme.radiusSm
                            color: Theme.alpha(Theme.surfaceAlt, 0.9)

                            Image {
                                anchors.fill: parent
                                source: mediaCard.mediaPlayer?.trackArtUrl ?? ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                smooth: true
                                mipmap: true
                                antialiasing: true
                                visible: status === Image.Ready
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: (mediaCard.mediaPlayer?.trackArtUrl ?? "") === ""
                                text: ""
                                color: Theme.faint
                                font.family: Theme.fontIcon
                                font.pixelSize: 22
                            }
                        }

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: mediaCard.mediaPlayer?.trackTitle ?? "Nothing playing"
                            color: Theme.text
                            font.family: Theme.font
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: mediaCard.mediaPlayer?.trackArtist ?? ""
                            color: Theme.faint
                            font.family: Theme.font
                            font.pixelSize: 10
                            elide: Text.ElideRight
                        }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 4

                            Repeater {
                                model: [
                                    { glyph: "", act: "previous" },
                                    { glyph: "", act: "toggle" },
                                    { glyph: "", act: "next" }
                                ]

                                Rectangle {
                                    required property var modelData

                                    width: 30
                                    height: 30
                                    radius: Theme.radiusSm
                                    color: ctrl.containsMouse ? Theme.surfaceHover : "transparent"

                                    Behavior on color {
                                        ColorAnimation { duration: Theme.animFast }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.act === "toggle"
                                            && mediaCard.mediaPlayer?.playbackState === MprisPlaybackState.Playing
                                                ? ""
                                                : modelData.glyph
                                        color: Theme.text
                                        font.family: Theme.fontIcon
                                        font.pixelSize: 15
                                    }

                                    MouseArea {
                                        id: ctrl

                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor

                                        onClicked: {
                                            const p = mediaCard.mediaPlayer;
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
                    }
                }

                NeonSlider {
                    width: mediaRow.faderWidth
                    height: parent.height
                    icon: Audio.icon
                    value: Audio.volume
                    onMoved: v => Audio.setVolume(v)
                }

                NeonSlider {
                    width: mediaRow.faderWidth
                    height: parent.height
                    visible: Brightness.available
                    icon: ""
                    value: Brightness.value
                    onMoved: v => Brightness.set(v)
                }
            }

            Column {
                width: parent.width
                spacing: 6
                visible: Notifs.history.length > 0

                Item {
                    width: parent.width
                    height: 12

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: `NOTIFICATIONS · ${Notifs.count}`
                        color: Theme.faint
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        font.letterSpacing: 1.2
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "clear"
                        color: clearMouse.containsMouse ? Theme.magenta : Theme.faint
                        font.family: Theme.fontMono
                        font.pixelSize: 9

                        MouseArea {
                            id: clearMouse

                            anchors.fill: parent
                            anchors.margins: -6
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Notifs.clearHistory()
                        }
                    }
                }

                Repeater {
                    model: Notifs.history.slice(0, 4)

                    Rectangle {
                        id: notifRow

                        required property var modelData

                        width: parent.width
                        height: notifBody.implicitHeight + 18
                        radius: Theme.radiusSm
                        color: notifHover.containsMouse
                            ? Theme.surfaceHover
                            : Theme.alpha(Theme.surface, 0.7)
                        border.width: 1
                        border.color: Theme.rimSoft

                        Behavior on color {
                            ColorAnimation { duration: Theme.animFast }
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.leftMargin: 1
                            anchors.verticalCenter: parent.verticalCenter
                            width: 3
                            height: parent.height * 0.55
                            radius: 2
                            color: Theme.accent
                        }

                        Row {
                            id: notifBody

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 12
                            anchors.rightMargin: 10
                            spacing: 9

                            AppIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                size: 20
                                source: notifRow.modelData.image
                                name: notifRow.modelData.image !== ""
                                    ? ""
                                    : notifRow.modelData.appIcon
                                glyph: ""
                            }

                            Column {
                                width: parent.width - 32
                                spacing: 2

                                Text {
                                    width: parent.width
                                    text: notifRow.modelData.appName
                                    visible: text !== ""
                                    color: Theme.faint
                                    font.family: Theme.fontMono
                                    font.pixelSize: 8
                                    font.letterSpacing: 1
                                    font.capitalization: Font.AllUppercase
                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width
                                    text: notifRow.modelData.summary
                                    color: Theme.text
                                    font.family: Theme.font
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width
                                    text: notifRow.modelData.body
                                    visible: text !== ""
                                    color: Theme.subtext
                                    font.family: Theme.font
                                    font.pixelSize: 10
                                    textFormat: Text.StyledText
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        MouseArea {
                            id: notifHover

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: notifRow.modelData.dismiss()
                        }
                    }
                }
            }
                }

                Column {
                    id: wifiPage

                    width: viewport.width
                    spacing: 12

                    PageHeader {
                        width: parent.width
                        title: !Network.wifiEnabled
                            ? "Wi-Fi is off"
                            : Network.scanning ? "Scanning…" : "Networks"
                    }

            Column {
                width: parent.width
                spacing: 6

                Row {
                    width: parent.width

                    Item {
                        width: parent.width - 80
                        height: 1
                    }

                    Text {
                        text: "rescan"
                        color: rescan.containsMouse ? Theme.cyan : Theme.faint
                        font.family: Theme.fontMono
                        font.pixelSize: 9

                        MouseArea {
                            id: rescan

                            anchors.fill: parent
                            anchors.margins: -6
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Network.scan()
                        }
                    }

                    Item { width: 10; height: 1 }

                    Text {
                        text: "nmtui"
                        color: editor.containsMouse ? Theme.cyan : Theme.faint
                        font.family: Theme.fontMono
                        font.pixelSize: 9

                        MouseArea {
                            id: editor

                            anchors.fill: parent
                            anchors.margins: -6
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Network.openEditor()
                        }
                    }
                }

                Text {
                    width: parent.width
                    text: Network.error
                    visible: text !== ""
                    color: Theme.magenta
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    wrapMode: Text.WordWrap
                }

                Repeater {
                    model: Network.networks

                    Rectangle {
                        id: ap

                        required property var modelData

                        readonly property bool expanded:
                            root.pendingSsid === modelData.ssid

                        width: parent.width
                        height: expanded ? 66 : 32
                        radius: Theme.radiusSm
                        color: modelData.active
                            ? Theme.alpha(Theme.cyan, 0.16)
                            : apMouse.containsMouse
                                ? Theme.surfaceHover
                                : Theme.alpha(Theme.surface, 0.7)

                        Behavior on height { Morph {} }
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        Row {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            height: 32
                            spacing: 8

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: ap.modelData.secured ? "\ue10b" : "\ue1ae"
                                color: ap.modelData.active ? Theme.cyan : Theme.faint
                                font.family: Theme.fontIcon
                                font.pixelSize: 12
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 110
                                text: ap.modelData.ssid
                                color: Theme.text
                                font.family: Theme.font
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: `${ap.modelData.signal}%`
                                color: Theme.faint
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "forget"
                                visible: ap.modelData.known
                                color: forgetMouse.containsMouse ? Theme.magenta : Theme.faint
                                font.family: Theme.fontMono
                                font.pixelSize: 9

                                MouseArea {
                                    id: forgetMouse

                                    anchors.fill: parent
                                    anchors.margins: -5
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Network.forget(ap.modelData.ssid)
                                }
                            }
                        }

                        MouseArea {
                            id: apMouse

                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 32
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            z: -1

                            onClicked: {
                                if (ap.modelData.active)
                                    return;
                                if (ap.modelData.known || !ap.modelData.secured) {
                                    Network.connect(ap.modelData.ssid, "");
                                    return;
                                }
                                root.pendingSsid = ap.expanded ? "" : ap.modelData.ssid;
                                pass.text = "";
                                if (root.pendingSsid !== "")
                                    pass.forceActiveFocus();
                            }
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 6
                            height: 26
                            radius: Theme.radiusSm
                            color: Theme.alpha(Theme.surfaceAlt, 0.9)
                            visible: ap.expanded
                            clip: true

                            TextInput {
                                id: pass

                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                verticalAlignment: TextInput.AlignVCenter

                                echoMode: TextInput.Password
                                color: Theme.text
                                font.family: Theme.font
                                font.pixelSize: 11
                                selectByMouse: true
                                selectionColor: Theme.alpha(Theme.accent, 0.35)

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: pass.text === ""
                                    text: "Password, enter to join"
                                    color: Theme.faint
                                    font: pass.font
                                }

                                onAccepted: {
                                    Network.connect(ap.modelData.ssid, pass.text);
                                    root.pendingSsid = "";
                                }

                                Keys.onEscapePressed: root.pendingSsid = ""
                            }
                        }
                    }
                }
            }
                }

                Column {
                    id: powerPage

                    width: viewport.width
                    spacing: 12

                    PageHeader {
                        width: parent.width
                        title: "Session"
                    }

            Column {
                id: powerList

                width: parent.width
                spacing: 6

                property string armed: ""

                Repeater {
                    model: [
                        { key: "lock", glyph: "\ue10b", name: "Lock", tint: Theme.accent, cmd: ["sh", "-c", "loginctl lock-session || hyprlock"], confirm: false },
                        { key: "suspend", glyph: "\ue11e", name: "Suspend", tint: Theme.accent, cmd: ["systemctl", "suspend"], confirm: false },
                        { key: "logout", glyph: "\ue10e", name: "Log out", tint: Theme.subtext, cmd: [], confirm: true },
                        { key: "reboot", glyph: "\ue149", name: "Restart", tint: Theme.amber, cmd: ["systemctl", "reboot"], confirm: true },
                        { key: "off", glyph: "\ue140", name: "Shut down", tint: Theme.red, cmd: ["systemctl", "poweroff"], confirm: true }
                    ]

                    Rectangle {
                        id: powerBtn

                        required property var modelData

                        readonly property bool armed: powerList.armed === modelData.key

                        width: parent.width
                        height: 38
                        radius: Theme.radiusSm

                        color: armed
                            ? Theme.alpha(modelData.tint, 0.3)
                            : pw.containsMouse
                                ? Theme.surfaceHover
                                : Theme.alpha(Theme.surface, 0.85)

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 10

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: powerBtn.modelData.glyph
                                color: pw.containsMouse || powerBtn.armed
                                    ? powerBtn.modelData.tint
                                    : Theme.subtext
                                font.family: Theme.fontIcon
                                font.pixelSize: 15
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: powerBtn.armed
                                    ? "Click again to confirm"
                                    : powerBtn.modelData.name
                                color: powerBtn.armed ? powerBtn.modelData.tint : Theme.text
                                font.family: Theme.font
                                font.pixelSize: 12
                            }
                        }

                        MouseArea {
                            id: pw

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                if (powerBtn.modelData.confirm && !powerBtn.armed) {
                                    powerList.armed = powerBtn.modelData.key;
                                    disarm.restart();
                                    return;
                                }
                                powerList.armed = "";
                                Globals.controlCenter = false;
                                if (powerBtn.modelData.cmd.length === 0)
                                    Hyprland.dispatch("hl.dsp.exit()");
                                else
                                    Quickshell.execDetached(powerBtn.modelData.cmd);
                            }
                        }

                        Timer {
                            id: disarm
                            interval: 3000
                            onTriggered: powerList.armed = ""
                        }
                    }
                }
            }
                }
            }
        }

        component PageHeader: Row {
            property string title

            spacing: 8

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "\ue06e"
                color: back.containsMouse ? Theme.accent : Theme.subtext
                font.family: Theme.fontIcon
                font.pixelSize: 15

                MouseArea {
                    id: back

                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.page = 0
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: parent.title
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }
        }
    }
}
}
