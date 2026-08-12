import Quickshell
import Quickshell.Wayland
import QtQuick

import "root:/"
import "root:/components"
import "root:/services"

PanelWindow {
    id: root

    required property string screenName

    readonly property bool shouldOpen:
        Globals.clipboard && Globals.focusedScreen === screenName

    property real slide: shouldOpen ? 0 : 1
    Behavior on slide { Morph {} }

    readonly property bool open: slide < 1

    visible: open

    WlrLayershell.namespace: "kyber-clipboard"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shouldOpen
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
        if (shouldOpen) {
            search.text = "";
            list.currentIndex = 0;
            search.forceActiveFocus();
        }
    }

    readonly property var results: {
        const query = search.text.trim().toLowerCase();
        if (query === "")
            return Clipboard.history.slice(0, 40);

        return Clipboard.history
            .filter(e => e.toLowerCase().includes(query))
            .slice(0, 40);
    }

    function pick(entry) {
        if (entry === undefined)
            return;
        Globals.clipboard = false;
        Clipboard.copy(entry);
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Globals.clipboard = false
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

            width: Math.min(460, root.width - 80)
            height: 64 + Math.min(7, root.results.length) * 54
                + (root.results.length ? 12 : 40)
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

                    text: ""
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

                    onTextChanged: list.currentIndex = 0

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: search.text === ""
                        text: "Search clipboard…"
                        color: Theme.faint
                        font: search.font
                    }

                    Keys.onEscapePressed: Globals.clipboard = false
                    Keys.onDownPressed: list.incrementCurrentIndex()
                    Keys.onUpPressed: list.decrementCurrentIndex()
                    Keys.onTabPressed: list.incrementCurrentIndex()
                    Keys.onBacktabPressed: list.decrementCurrentIndex()

                    Keys.onReturnPressed: root.pick(root.results[list.currentIndex])
                    Keys.onEnterPressed: root.pick(root.results[list.currentIndex])

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Delete) {
                            const entry = root.results[list.currentIndex];
                            if (entry !== undefined)
                                Clipboard.forget(entry);
                            event.accepted = true;
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

            Text {
                anchors.centerIn: parent
                visible: root.results.length === 0

                text: Clipboard.history.length === 0
                    ? "NOTHING COPIED YET"
                    : "NO MATCH"
                color: Theme.faint
                font.family: Theme.fontMono
                font.pixelSize: 10
                font.letterSpacing: Theme.trackingWide
            }

            ListView {
                id: list

                anchors {
                    top: rule.bottom
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    topMargin: 6
                    bottomMargin: 6
                    leftMargin: 6
                    rightMargin: 6
                }

                model: root.results
                clip: true
                spacing: 2
                currentIndex: 0
                highlightMoveDuration: Theme.animFast
                keyNavigationWraps: true

                delegate: Rectangle {
                    id: row

                    required property var modelData
                    required property int index

                    readonly property bool selected: list.currentIndex === index

                    width: list.width
                    height: 52
                    radius: Theme.radiusSm + 2

                    color: selected
                        ? Theme.alpha(Theme.accent, 0.14)
                        : hover.containsMouse
                            ? Theme.surfaceHover
                            : "transparent"

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.leftMargin: 1
                        anchors.verticalCenter: parent.verticalCenter

                        width: 2
                        height: row.selected ? parent.height - 16 : 0
                        radius: 1
                        color: Theme.accent

                        Behavior on height { Morph { duration: Theme.animMed } }
                    }

                    Column {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 14
                        anchors.rightMargin: 46
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            width: parent.width
                            text: row.modelData.split("\n")[0]
                            color: Theme.text
                            font.family: Theme.font
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            visible: text !== ""
                            text: {
                                const lines = row.modelData.split("\n").length;
                                const chars = row.modelData.length;
                                return lines > 1
                                    ? `${lines} LINES · ${chars} CHARS`
                                    : `${chars} CHARS`;
                            }
                            color: Theme.faint
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            font.letterSpacing: Theme.trackingWide
                            elide: Text.ElideRight
                        }
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter

                        text: row.index + 1
                        color: row.selected ? Theme.accent : Theme.faint
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                    }

                    MouseArea {
                        id: hover

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton

                        onEntered: list.currentIndex = row.index
                        onClicked: mouse => {
                            if (mouse.button === Qt.MiddleButton)
                                Clipboard.forget(row.modelData);
                            else
                                root.pick(row.modelData);
                        }
                    }
                }
            }
        }
    }
}
