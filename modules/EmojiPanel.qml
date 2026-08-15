import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

import "root:/"
import "root:/components"
import "root:/services"

PanelWindow {
    id: root

    required property string screenName

    readonly property bool shouldOpen:
        Globals.emoji && Globals.focusedScreen === screenName

    property real slide: shouldOpen ? 0 : 1
    Behavior on slide { Morph {} }

    readonly property bool open: slide < 1

    visible: open

    WlrLayershell.namespace: "kyber-emoji"
    WlrLayershell.layer: WlrLayer.Overlay
    // focus is handed back to the app while typing, so wtype lands there
    WlrLayershell.keyboardFocus: shouldOpen && !typing
        ? WlrKeyboardFocus.Exclusive
        : WlrKeyboardFocus.None

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    color: "transparent"
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore

    onShouldOpenChanged: {
        typing = false;
        if (shouldOpen) {
            search.text = "";
            group = 0;
            grid.currentIndex = 0;
            search.forceActiveFocus();
        }
    }

    readonly property int columns: 8

    // active category tab; ignored while searching
    property int group: 0

    readonly property var results: {
        const query = search.text.trim().toLowerCase();

        // tone variants stay out of the way until asked for by name
        const wantTones = query.includes("tone");

        if (query === "")
            return EmojiData.list.filter(
                e => e[3] === root.group && !e[1].includes("skin tone"));

        const words = query.split(/\s+/);
        return EmojiData.list
            .filter(e => (wantTones || !e[1].includes("skin tone"))
                && words.every(w => e[1].includes(w) || e[2].includes(w)))
            .slice(0, 400);
    }

    // wtype types into whatever has focus, so the panel drops its exclusive
    // keyboard focus for a moment, types, then takes it back and stays open.
    // No wtype on PATH: fall back to the clipboard and close.
    property bool canType: false
    property bool typing: false

    Process {
        running: true
        command: ["sh", "-c", "command -v wtype"]
        stdout: StdioCollector {
            onStreamFinished: root.canType = text.trim() !== ""
        }
    }

    Timer {
        id: typeDelay

        // let the compositor deliver the focus change to the app first
        interval: 150
        onTriggered: {
            // Paste rather than type the glyph: wtype's own keymap is the part
            // clients mis-decode (Hyprland reports it as "error" and the app
            // fires whatever key used to sit at that keycode). Ctrl+V is a
            // plain keysym, so nothing has to be remapped.
            typer.command = ["wtype", "-s", "60", "-M", "ctrl", "-k", "v",
                "-m", "ctrl"];
            typer.running = true;
        }
    }

    Process {
        id: typer

        // focus is only taken back once wtype has actually finished, otherwise
        // the panel grabs the keyboard mid-type and eats the glyph
        onExited: {
            root.typing = false;
            search.forceActiveFocus();
        }
    }

    // Return arms on press, fires on release
    property var armed: undefined

    function arm(event) {
        event.accepted = true;
        if (event.isAutoRepeat)
            return;
        root.armed = root.results[grid.currentIndex];
    }

    function fire() {
        const entry = root.armed;
        root.armed = undefined;
        root.pick(entry);
    }

    function pick(entry) {
        if (entry === undefined)
            return;

        if (!root.canType) {
            Globals.emoji = false;
            Clipboard.copy(entry[0]);
            return;
        }

        Clipboard.copy(entry[0]);
        root.typing = true;
        typeDelay.restart();
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Globals.emoji = false
    }

    Binding {
        target: Globals
        property: "launcherNotchY"
        value: Math.round(panel.y - 16 * (1 - root.slide))
        when: root.open
        restoreMode: Binding.RestoreNone
    }

    Binding {
        target: Globals
        property: "launcherNotchHeight"
        value: Math.round((panel.height + 32) * (1 - root.slide))
        when: root.open
        restoreMode: Binding.RestoreNone
    }

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

            anchors.verticalCenter: parent.verticalCenter
            x: -width * Math.max(0, root.slide)

            width: Math.min(420, root.width - 80)
            height: 64 + (root.results.length ? 6 * 46 + 42 : 40)
            radius: Theme.radius + 4
            squareLeft: true

            Behavior on height { Morph {} }

            MouseArea {
                anchors.fill: parent
            }

            Brackets {
                anchors.margins: 3
                topLeft: false
                topRight: true
                bottomLeft: false
                bottomRight: true
                z: 200
            }

            Item {
                id: field

                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: 6
                }

                height: 52

                Text {
                    id: prompt

                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter

                    text: "\ue164"
                    color: Theme.accent
                    font.family: Theme.fontIcon
                    font.pixelSize: 17
                }

                TextInput {
                    id: search

                    anchors {
                        left: prompt.right
                        leftMargin: 12
                        right: counter.left
                        rightMargin: 12
                        verticalCenter: parent.verticalCenter
                    }

                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: 17
                    selectByMouse: true
                    selectionColor: Theme.alpha(Theme.accent, 0.35)
                    clip: true

                    onTextChanged: grid.currentIndex = 0

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: search.text === ""
                        text: "Search emoji…"
                        color: Theme.faint
                        font: search.font
                    }

                    Keys.onEscapePressed: Globals.emoji = false
                    Keys.onRightPressed: grid.moveCurrentIndexRight()
                    Keys.onLeftPressed: grid.moveCurrentIndexLeft()
                    Keys.onDownPressed: grid.moveCurrentIndexDown()
                    Keys.onUpPressed: grid.moveCurrentIndexUp()
                    Keys.onTabPressed: grid.moveCurrentIndexRight()
                    Keys.onBacktabPressed: grid.moveCurrentIndexLeft()

                    Keys.onPressed: event => {
                        if (event.modifiers & Qt.ControlModifier
                                && (event.key === Qt.Key_Left
                                    || event.key === Qt.Key_Right)) {
                            const step = event.key === Qt.Key_Right ? 1 : -1;
                            const n = EmojiData.groups.length;
                            root.group = (root.group + step + n) % n;
                            grid.currentIndex = 0;
                            grid.positionViewAtBeginning();
                            event.accepted = true;
                        }
                    }

                    // hold the pick until Return is released, otherwise the
                    // key event follows the focus into the app underneath
                    Keys.onReturnPressed: event => root.arm(event)
                    Keys.onEnterPressed: event => root.arm(event)

                    Keys.onReleased: event => {
                        if (event.key === Qt.Key_Return
                                || event.key === Qt.Key_Enter) {
                            event.accepted = true;
                            if (!event.isAutoRepeat)
                                root.fire();
                        }
                    }
                }

                Text {
                    id: counter

                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter

                    text: root.results.length
                    color: Theme.faint
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                }
            }

            Rectangle {
                id: rule

                anchors.top: field.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 1

                height: 1
                visible: root.results.length > 0

                color: Theme.alpha(Theme.faint, 0.5)
            }

            Row {
                id: tabs

                anchors.top: rule.bottom
                anchors.topMargin: 4
                anchors.horizontalCenter: parent.horizontalCenter

                spacing: 2
                visible: search.text.trim() === ""

                Repeater {
                    model: EmojiData.groups

                    Rectangle {
                        id: tab

                        required property var modelData
                        required property int index

                        readonly property bool active: root.group === index

                        width: 30
                        height: 26
                        radius: Theme.radiusSm

                        color: active
                            ? Theme.alpha(Theme.accent, 0.16)
                            : tabHover.containsMouse
                                ? Theme.surfaceHover
                                : "transparent"

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        Text {
                            anchors.centerIn: parent
                            text: tab.modelData.glyph
                            font.family: Theme.fontIcon
                            font.pixelSize: 14
                            color: tab.active ? Theme.accent : Theme.subtext

                            Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        }

                        MouseArea {
                            id: tabHover

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                root.group = tab.index;
                                grid.currentIndex = 0;
                                grid.positionViewAtBeginning();
                            }
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: root.results.length === 0

                text: "NO MATCH"
                color: Theme.faint
                font.family: Theme.fontMono
                font.pixelSize: 10
                font.letterSpacing: Theme.trackingWide
            }

            Text {
                id: label

                anchors.bottom: parent.bottom
                anchors.bottomMargin: 10
                anchors.horizontalCenter: parent.horizontalCenter

                width: parent.width - 32
                horizontalAlignment: Text.AlignHCenter
                visible: root.results.length > 0

                text: (root.results[grid.currentIndex]?.[1] ?? "").toUpperCase()
                color: Theme.faint
                font.family: Theme.fontMono
                font.pixelSize: 9
                font.letterSpacing: Theme.trackingWide
                elide: Text.ElideRight
            }

            GridView {
                id: grid

                anchors {
                    top: tabs.visible ? tabs.bottom : rule.bottom
                    left: parent.left
                    right: parent.right
                    bottom: label.visible ? label.top : parent.bottom
                    topMargin: 6
                    bottomMargin: 6
                    leftMargin: 6
                    rightMargin: 6
                }

                model: root.results
                clip: true
                currentIndex: 0
                highlightMoveDuration: Theme.animFast
                keyNavigationWraps: true

                cellWidth: Math.floor(width / root.columns)
                cellHeight: cellWidth

                delegate: Item {
                    id: cell

                    required property var modelData
                    required property int index

                    readonly property bool selected: grid.currentIndex === index

                    width: grid.cellWidth
                    height: grid.cellHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 2
                        radius: Theme.radiusSm + 2

                        color: cell.selected
                            ? Theme.alpha(Theme.accent, 0.14)
                            : hover.containsMouse
                                ? Theme.surfaceHover
                                : "transparent"

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        Text {
                            anchors.centerIn: parent
                            text: cell.modelData[0]
                            color: Theme.text
                            font.pixelSize: Math.round(grid.cellHeight * 0.5)
                        }
                    }

                    MouseArea {
                        id: hover

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onEntered: grid.currentIndex = cell.index
                        onClicked: root.pick(cell.modelData)
                    }
                }
            }
        }
    }
}
