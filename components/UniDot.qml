import Quickshell.Services.Mpris
import QtQuick

import "root:/"
import "root:/services"

// One dot that says whatever is currently worth saying. It sits in the clock
// pill and morphs between a handful of shapes rather than adding a widget per
// signal — the bar stays a clock, and the ambient state rides along in 14px.
//
// Priority is loudest-first: a fresh notification interrupts anything, then
// media, then whatever the machine is complaining about, then a resting pulse.
Item {
    id: root

    readonly property bool playing: Player.playing

    // A notification is "fresh" for a few seconds after it lands, which is what
    // gives the dot something to react to — `count` alone only says how many are
    // waiting, not that one just arrived.
    property bool fresh: false

    readonly property string mode:
        fresh ? "notify"
        : Globals.dnd ? "dnd"
        : playing ? "media"
        : Battery.available && Battery.charging ? "charging"
        : Battery.available && Battery.low ? "low"
        : "idle"

    // While the peek is out, the dot is the thing holding it open, so it goes
    // accent and breathes regardless of what it was reporting a moment ago.
    readonly property color tint: Globals.mediaPeek ? Theme.accent : ({
        "notify": Theme.accent,
        "dnd": Theme.faint,
        "media": Theme.accent,
        "charging": Theme.lime,
        "low": Theme.red,
        "idle": Theme.faint
    })[mode]

    // Faster and shallower than the resting breath: this one says "held", not
    // "alive". Overrides the per-mode animations below by running on the item
    // rather than on the dot inside it.
    SequentialAnimation on opacity {
        running: Globals.mediaPeek
        loops: Animation.Infinite
        alwaysRunToEnd: true

        NumberAnimation { to: 0.45; duration: 620; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1; duration: 620; easing.type: Easing.InOutSine }
    }

    implicitWidth: 12
    implicitHeight: 14

    // The dot is what stands for the media, so it is what reveals it. Padded a
    // few pixels past the dot's own 12x14 — a bare 4px dot is not a hit target.
    Item {
        anchors.centerIn: parent
        width: parent.width + 10
        height: parent.height + 6

        HoverHandler {
            onHoveredChanged: Globals.mediaDotHovered = hovered
        }
    }

    // Arrivals only. Dismissing a notification also changes `count`, and a dot
    // that blooms when you clear the queue is reporting the wrong event.
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

    // ---- resting dot / notification bloom ------------------------------
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

        // slow breath while nothing is happening, so the dot reads as alive
        // rather than as a dead pixel
        SequentialAnimation on opacity {
            running: root.mode === "idle" || root.mode === "dnd"
            loops: Animation.Infinite
            alwaysRunToEnd: true

            NumberAnimation { to: 0.35; duration: 1900; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.9; duration: 1900; easing.type: Easing.InOutSine }
        }

        // urgent states blink instead of breathing
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

    // The ring a notification throws off as it lands: expands past the dot and
    // fades, like a drop hitting the surface. Fires once per arrival.
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

    // ---- media: the dot splits into an equaliser ------------------------
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

                // each bar on its own period, so they never march in lockstep
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
