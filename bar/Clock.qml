import Quickshell
import QtQuick

import "root:/"
import "root:/components"
import "root:/services"

Chip {
    id: root

    active: Globals.dashboard || Globals.controlCenter
    padding: 10
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    onClicked: mouse => mouse.button === Qt.RightButton
        ? Globals.toggleControlCenter()
        : Globals.toggleDashboard()

    UniDot {
        anchors.verticalCenter: parent.verticalCenter
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter

        text: Qt.formatDate(clock.date, "ddd d MMM")
        color: Theme.subtext
        font.family: Theme.font
        font.pixelSize: Theme.fontSizeSm
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "·"
        color: Theme.faint
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter

        text: Qt.formatTime(clock.date, "HH:mm")
        color: Theme.text
        font.family: Theme.fontMono
        font.pixelSize: Theme.fontSize
        font.weight: Font.Medium
        font.letterSpacing: Theme.tracking
    }
}
