import QtQuick

import "root:/"
import "root:/components"
import "root:/services"

Chip {
    id: root

    interactive: false
    padding: 10

    component Gauge: Row {
        id: gauge

        property real value: 0
        property string glyph: ""
        property color tint: Theme.cyan

        spacing: 5

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: gauge.glyph
            color: gauge.tint
            font.family: Theme.fontIcon
            font.pixelSize: 11
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter

            width: 28
            height: 3
            radius: 1.5
            color: Theme.alpha(Theme.text, 0.08)

            Rectangle {
                width: parent.width * Math.max(0.02, Math.min(1, gauge.value))
                height: parent.height
                radius: parent.radius
                color: gauge.value > 0.85 ? Theme.red : Theme.subtext

                Behavior on width { NumberAnimation { duration: 600 } }
                Behavior on color { ColorAnimation { duration: Theme.animMed } }
            }
        }
    }

    Gauge {
        anchors.verticalCenter: parent.verticalCenter
        glyph: ""
        tint: Theme.subtext
        value: SysInfo.cpu
    }

    Gauge {
        anchors.verticalCenter: parent.verticalCenter
        glyph: ""
        tint: Theme.faint
        value: SysInfo.memory
    }
}
