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

    // 0 = tucked into the bar, 1 = fully out. One driver runs the whole thing
    // and `visible` derives from it: binding `visible` straight to the toggle
    // unmaps the window on the first frame of the close, which both skips the
    // animation and freezes the bar's notch at its last width — leaving a stub
    // of missing hairline behind.
    property real reveal: shouldOpen ? 1 : 0
    Behavior on reveal { Morph {} }

    // 0 = main, 1 = networks, 2 = session. Sub-pages slide in from the right.
    property int page: 0
    // which network row has its password field out
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
    // OnDemand, not Exclusive: the panel only needs the keyboard while the
    // wifi password field is focused, and grabbing it outright would swallow
    // typing meant for whatever is underneath.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    color: "transparent"
    exclusiveZone: 0

    // click-away
    MouseArea {
        anchors.fill: parent
        onClicked: Globals.controlCenter = false
    }

    // holds back the bar's hairline over the span this dropdown occupies. It is
    // flush with the screen's right edge, so the notch runs to the end of the
    // bar and only the left side needs a flare.
    Binding {
        target: Globals
        property: "notchWidth"
        value: Math.round((panel.width + 16) * root.reveal)
        when: root.open
        restoreMode: Binding.RestoreNone
    }

    // same screen-vs-window offset the dashboard corrects for
    readonly property real screenInset: (screen?.width ?? width) - width

    Binding {
        target: Globals
        property: "notchX"
        value: Math.round(root.screenInset + root.width
            - (panel.width + 16) * root.reveal)
        when: root.open
        restoreMode: Binding.RestoreNone
    }

    // Notch: hangs off the right end of the bar, under the status island, square
    // on top, rounded below, one concave flare on its open side.  ──\____|
    // Pinned to the bar's edge rather than to the sheet: riding the sheet would
    // drag the flare up behind the bar for the whole slide.
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

        // Slides down out of the bar and back up into it. This window starts at
        // the bar's bottom edge, so a negative y parks the sheet behind the bar
        // — no clip needed, and nothing pops.
        y: -height * Math.max(0, 1 - root.reveal)

        // Trails the slide (the 1.4x, clamped) so it is most of the way out
        // before it reads as solid, instead of fading in place.
        opacity: Math.max(0, 1 - (1 - root.reveal) * 1.4)

        GlassPanel {
            id: panel

            width: 340
            height: viewport.height + 28
            radius: Theme.radius + 4
            squareTop: true

            MouseArea {
                anchors.fill: parent
                // swallow clicks so click-away doesn't fire
            }

        // The panel is one window with three pages side by side: main, the
        // network list, the power actions. Sub-pages slide in from the right
        // instead of pushing the main page around, so nothing reflows.
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

                // ============ page 0: main ==============================
                Column {
                    id: mainPage

                    width: viewport.width
                    spacing: 12

                    // ---- identity ------------------------------------------
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
                    radius: 11
                    color: Theme.alpha(Theme.cyan, 0.24)

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

                    Text {
                        text: SysInfo.user
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: `up ${SysInfo.uptime} · ${SysInfo.memUsedMb}/${SysInfo.memTotalMb} MB`
                        color: Theme.faint
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                    }
                }

                }

                // page buttons, pinned to the panel's right edge
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

                    // ---- toggles -------------------------------------------
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

                    // ---- media + faders -------------------------------------
            // Media is the big square block and the faders are thin columns
            // beside it: the sliders are aimed at, not read, so they need
            // height, not width.
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

                    // ---- notifications --------------------------------------
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

                        // same accent spine as the toasts, so history reads as
                        // the same object the popup was
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

                            IconImage {
                                anchors.verticalCenter: parent.verticalCenter
                                implicitSize: 20
                                visible: source !== ""
                                source: notifRow.modelData.image !== ""
                                    ? notifRow.modelData.image
                                    : Quickshell.iconPath(notifRow.modelData.appIcon, true)
                                smooth: true
                                mipmap: true
                                antialiasing: true
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

                // ============ page 1: networks ==========================
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

                    // ---- wifi picker ----------------------------------------
            // Right-click on the Wi-Fi tile opens this. Kept inside the panel
            // rather than in a window of its own: it is a list, not a mode.
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

                            // Known or open networks connect straight away;
                            // only an unknown secured one needs the field.
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

                // ============ page 2: power =============================
                Column {
                    id: powerPage

                    width: viewport.width
                    spacing: 12

                    PageHeader {
                        width: parent.width
                        title: "Session"
                    }

                    // ---- power ------------------------------------------------
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

                            // Destructive actions need a second click; the armed
                            // state expires on its own after 3s.
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

        // Back chevron plus title, shared by both sub-pages.
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
