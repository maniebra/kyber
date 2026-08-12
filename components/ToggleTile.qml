import QtQuick

import "root:/"

// Control-center tile: icon + label + state, in the macOS pill idiom.
Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property string sublabel: ""
    property bool active: false
    property color accent: Theme.cyan

    signal clicked()
    signal secondaryClicked()

    implicitHeight: 54
    radius: Theme.radiusSm

    color: active
        ? Theme.alpha(accent, 0.24)
        : mouse.containsMouse
            ? Theme.surfaceHover
            : Theme.alpha(Theme.surface, 0.85)

    // A hairline as well as the lighter fill: the compositor's blur varies with
    // what's behind the panel, and on a bright wallpaper the fill step alone
    // stops reading.
    border.width: 1
    border.color: active ? Theme.alpha(accent, 0.35) : Theme.rimSoft

    antialiasing: true
    scale: mouse.pressed ? 0.975 : 1

    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    Behavior on scale { Morph { duration: Theme.animMed } }

    Row {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 10

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 32
            height: 32
            radius: Theme.radiusSm

            color: root.active ? root.accent : Theme.alpha(Theme.text, 0.08)
            antialiasing: true
            Behavior on color { ColorAnimation { duration: Theme.animFast } }

            Text {
                anchors.centerIn: parent
                text: root.icon
                font.family: Theme.fontIcon
                font.pixelSize: 15
                color: root.active ? Theme.accentText : Theme.subtext
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1
            width: parent.width - 42 - parent.spacing

            Text {
                text: root.label
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 12
                font.weight: Font.DemiBold
                font.letterSpacing: Theme.tracking
                elide: Text.ElideRight
                width: parent.width
            }

            Text {
                text: root.sublabel
                visible: text !== ""
                color: root.active ? Theme.subtext : Theme.faint
                font.family: Theme.font
                font.pixelSize: 10
                font.letterSpacing: Theme.tracking
                elide: Text.ElideRight
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                width: parent.width
            }
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                root.secondaryClicked();
            else
                root.clicked();
        }
    }
}
