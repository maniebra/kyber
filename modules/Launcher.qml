import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick

import "root:/"
import "root:/components"
import "root:/services"

PanelWindow {
    id: root

    required property string screenName

    readonly property bool shouldOpen:
        Globals.launcher && Globals.focusedScreen === screenName

    property real slide: shouldOpen ? 0 : 1
    Behavior on slide { Morph {} }

    readonly property bool open: slide < 1

    visible: open

    WlrLayershell.namespace: "kyber-launcher"
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
        const apps = DesktopEntries.applications.values
            .filter(a => !a.noDisplay);

        if (query === "")
            return apps
                .slice()
                .sort((a, b) => a.name.localeCompare(b.name))
                .slice(0, 40);

        const scored = [];
        for (const app of apps) {
            const name = app.name.toLowerCase();
            const extra = `${app.genericName ?? ""} ${app.comment ?? ""}`.toLowerCase();

            let score = -1;
            if (name.startsWith(query))
                score = 0;
            else if (name.includes(query))
                score = 1;
            else if (extra.includes(query))
                score = 2;

            if (score >= 0)
                scored.push({ app: app, score: score });
        }

        return scored
            .sort((a, b) => a.score - b.score || a.app.name.localeCompare(b.app.name))
            .map(e => e.app)
            .slice(0, 40);
    }

    function launch(app) {
        if (!app)
            return;
        Globals.launcher = false;
        app.execute();
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Globals.launcher = false
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
            height: 64 + Math.min(8, root.results.length) * 52 + (root.results.length ? 12 : 0)
            radius: Theme.radius + 4
            squareLeft: true

            Behavior on height {
                Morph {}
            }

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
                        text: "Search applications…"
                        color: Theme.faint
                        font: search.font
                    }

                    Keys.onEscapePressed: Globals.launcher = false
                    Keys.onDownPressed: list.incrementCurrentIndex()
                    Keys.onUpPressed: list.decrementCurrentIndex()
                    Keys.onTabPressed: list.incrementCurrentIndex()
                    Keys.onBacktabPressed: list.decrementCurrentIndex()

                    Keys.onReturnPressed: root.launch(root.results[list.currentIndex])
                    Keys.onEnterPressed: root.launch(root.results[list.currentIndex])
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
                    height: 50
                    radius: Theme.radiusSm + 2

                    color: selected
                        ? Theme.alpha(Theme.accent, 0.14)
                        : hover.containsMouse
                            ? Theme.surfaceHover
                            : "transparent"

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 3
                        height: row.selected ? 26 : 0
                        radius: 2
                        color: Theme.accent

                        Behavior on height {
                            NumberAnimation { duration: Theme.animFast }
                        }
                    }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 12
                        spacing: 12

                        AppIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            size: 30
                            name: Theme.monoAppIcons ? "" : row.modelData.icon
                            glyph: AppGlyphs.forEntry(row.modelData)
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 54
                            spacing: 2

                            Text {
                                width: parent.width
                                text: row.modelData.name
                                color: Theme.text
                                font.family: Theme.font
                                font.pixelSize: 13
                                font.weight: row.selected ? Font.DemiBold : Font.Normal
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: row.modelData.genericName || row.modelData.comment || ""
                                visible: text !== ""
                                color: Theme.faint
                                font.family: Theme.font
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }
                        }
                    }

                    MouseArea {
                        id: hover

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onEntered: list.currentIndex = row.index
                        onClicked: root.launch(row.modelData)
                    }
                }
            }
        }
    }
}
