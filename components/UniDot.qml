import Quickshell.Services.Mpris
import QtQuick

import "root:/"
import "root:/services"

Item {
    id: root

    readonly property bool playing: Player.playing

    property bool fresh: false

    readonly property string mode:
        fresh ? "notify"
        : Globals.dnd ? "dnd"
        : playing ? "media"
        : Battery.available && Battery.charging ? "charging"
        : Battery.available && Battery.low ? "low"
        : "idle"

    readonly property color tint: Globals.mediaPeek ? Theme.accent : ({
        "notify": Theme.accent,
        "dnd": Theme.faint,
        "media": Theme.accent,
        "charging": Theme.lime,
        "low": Theme.red,
        "idle": Theme.faint
    })[mode]

    SequentialAnimation on opacity {
        running: Globals.mediaPeek
        loops: Animation.Infinite
        alwaysRunToEnd: true

        NumberAnimation { to: 0.45; duration: 620; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1; duration: 620; easing.type: Easing.InOutSine }
    }

    implicitWidth: 12
    implicitHeight: 14

    Item {
        anchors.centerIn: parent
        width: parent.width + 10
        height: parent.height + 6

        HoverHandler {
            onHoveredChanged: Globals.mediaDotHovered = hovered
        }
    }

    property int seen: 0

    Connections {
        target: Notifs

        function onCountChanged() {
            if (Notifs.count > root.seen)
                bloom.restart();
            root.seen = Notifs.count;
        }
    }

    Timer {
        id: bloom

        interval: 2600
        onTriggered: root.fresh = false
        onRunningChanged: if (running) root.fresh = true
    }

    Rectangle {
        id: dot

        anchors.centerIn: parent
        visible: root.mode !== "media"

        width: root.mode === "notify" ? 7 : 4
        height: width
        radius: width / 2
        color: root.tint
        antialiasing: true

        Behavior on width { Morph {} }
        Behavior on color { CMorph {} }

        SequentialAnimation on opacity {
            running: root.mode === "idle" || root.mode === "dnd"
            loops: Animation.Infinite
            alwaysRunToEnd: true

            NumberAnimation { to: 0.35; duration: 1900; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.9; duration: 1900; easing.type: Easing.InOutSine }
        }

        SequentialAnimation on opacity {
            running: root.mode === "low"
            loops: Animation.Infinite
            alwaysRunToEnd: true

            NumberAnimation { to: 0.25; duration: 420; easing.type: Easing.InOutQuad }
            NumberAnimation { to: 1; duration: 420; easing.type: Easing.InOutQuad }
        }

        Binding on opacity {
            when: root.mode === "charging" || root.mode === "notify"
            value: 1
        }
    }

    Rectangle {
        id: ripple

        anchors.centerIn: parent
        width: 4
        height: width
        radius: width / 2
        color: "transparent"
        border.width: 1
        border.color: root.tint
        opacity: 0
        antialiasing: true

        ParallelAnimation {
            id: splash

            NumberAnimation {
                target: ripple
                property: "width"
                from: 4
                to: 16
                duration: 620
                easing.type: Easing.Bezier
                easing.bezierCurve: Theme.curveFlow
            }

            NumberAnimation {
                target: ripple
                property: "opacity"
                from: 0.9
                to: 0
                duration: 620
            }
        }

        Connections {
            target: root

            function onFreshChanged() {
                if (root.fresh)
                    splash.restart();
            }
        }
    }

    Row {
        anchors.centerIn: parent
        visible: root.mode === "media"
        spacing: 2

        Repeater {
            model: 3

            Rectangle {
                required property int index

                anchors.verticalCenter: parent.verticalCenter
                width: 2
                height: 4
                radius: 1
                color: root.tint

                SequentialAnimation on height {
                    running: root.mode === "media"
                    loops: Animation.Infinite

                    NumberAnimation {
                        to: 11
                        duration: 340 + index * 130
                        easing.type: Easing.InOutQuad
                    }
                    NumberAnimation {
                        to: 4
                        duration: 300 + index * 90
                        easing.type: Easing.InOutQuad
                    }
                }
            }
        }
    }
}
