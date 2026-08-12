import QtQuick
import "root:/"
import "root:/components"
import "root:/services"

Chip {
    id: root

    active: Globals.controlCenter
    padding: 10
    onClicked: Globals.toggleControlCenter()
    onWheel: (delta) => {
        return Audio.nudge(delta > 0 ? 0.03 : -0.03);
    }

    Glyph {
        text: Globals.dnd ? "" : (Notifs.count > 0 ? "" : "")
        color: Globals.dnd ? Theme.faint : Notifs.count > 0 ? Theme.accent : Theme.subtext
    }

    Glyph {
        text: Network.icon
        color: Network.connected ? Theme.subtext : Theme.faint
    }

    Glyph {
        text: Audio.icon
        color: Audio.muted ? Theme.red : Theme.subtext
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        visible: Battery.available
        spacing: 4

        Glyph {
            text: Battery.icon
            color: Battery.low ? Theme.red : Battery.charging ? Theme.accent : Theme.subtext
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: `${Battery.percent}%`
            color: Theme.text
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontSizeSm
        }

    }

    component Glyph: Text {
        anchors.verticalCenter: parent.verticalCenter
        font.family: Theme.fontIcon
        font.pixelSize: 12
        color: Theme.subtext
    }

}
