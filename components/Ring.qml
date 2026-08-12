import QtQuick

import "root:/"

// Radial gauge: a track, an arc for the value, a readout in the middle.
// Canvas rather than QtQuick.Shapes — three of these repaint twice a second,
// which is nowhere near enough work to justify a scene-graph shape.
Item {
    id: root

    property real value: 0        // 0..1
    property string caption: ""
    property string readout: ""
    property color tint: Theme.accent
    property int thickness: 7
    // most meters go red when they fill up; a battery goes red when it empties
    property bool warnHigh: true

    // The arc animates by easing this shadow of `value` and repainting, since
    // a Canvas has nothing to interpolate on its own.
    property real shown: 0

    implicitWidth: 96
    implicitHeight: 96

    onValueChanged: shown = Math.max(0, Math.min(1, value))
    Component.onCompleted: shown = Math.max(0, Math.min(1, value))

    Behavior on shown {
        NumberAnimation { duration: 700; easing.type: Easing.OutCubic }
    }

    onShownChanged: arc.requestPaint()
    onTintChanged: arc.requestPaint()

    readonly property color live:
        (warnHigh ? shown > 0.85 : shown < 0.15) ? Theme.red : tint

    Canvas {
        id: arc

        anchors.fill: parent
        antialiasing: true

        onPaint: {
            const ctx = getContext("2d");
            const r = Math.min(width, height) / 2 - root.thickness / 2;
            const cx = width / 2;
            const cy = height / 2;
            const start = -Math.PI / 2;

            ctx.reset();
            ctx.lineWidth = root.thickness;
            ctx.lineCap = "round";

            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, Math.PI * 2);
            ctx.strokeStyle = Theme.alpha(Theme.text, 0.1);
            ctx.stroke();

            if (root.shown <= 0)
                return;

            ctx.beginPath();
            ctx.arc(cx, cy, r, start, start + Math.PI * 2 * root.shown);
            ctx.strokeStyle = root.live;
            ctx.stroke();
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 1

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.readout
            color: Theme.text
            font.family: Theme.fontMono
            font.pixelSize: 15
            font.weight: Font.DemiBold
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.caption
            color: Theme.faint
            font.family: Theme.fontMono
            font.pixelSize: 8
            font.letterSpacing: 1.2
        }
    }
}
