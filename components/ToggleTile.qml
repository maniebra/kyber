import QtQuick

import "root:/"

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

    border.width: 1
    border.color: active ? Theme.alpha(accent, 0.35) : Theme.rimSoft

    antialiasing: true
    scale: mouse.pressed ? 0.975 : 1

    Rectangle {
        anchors.left: parent.left
        anchors.leftMargin: 1
        anchors.verticalCenter: parent.verticalCenter

        width: 2
        height: root.active ? parent.height - 14 : 0
        radius: 1
        color: root.accent

        Behavior on height { Morph { duration: Theme.animMed } }
    }

    Item {
        anchors.fill: parent
        clip: true
        opacity: root.active ? 0.14 : 0
        visible: opacity > 0

        Behavior on opacity { NumberAnimation { duration: Theme.animMed } }

        Repeater {
            model: 22

            Rectangle {
                required property int index

                width: 1
                height: root.height * 3
                x: index * 9 - root.height
                y: -root.height
                rotation: -35
                transformOrigin: Item.TopLeft
                color: root.accent
            }
        }
    }

    Brackets {
        color: root.accent
        inset: 3
        arm: 7
        topLeft: false
        topRight: true
        bottomLeft: true
        bottomRight: false
        opacity: root.active ? 1 : 0

        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
    }

    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 6

        width: 5
        height: 5
        radius: 1
        rotation: 45
        color: root.accent
        opacity: root.active ? 1 : 0

        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
    }

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

            radius: 5

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
                text: root.label.toUpperCase()
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 11
                font.weight: Font.DemiBold
                font.letterSpacing: Theme.trackingWide
                elide: Text.ElideRight
                width: parent.width
            }

            Text {
                text: root.sublabel.toUpperCase()
                visible: text !== ""
                color: root.active ? root.accent : Theme.faint
                font.family: Theme.fontMono
                font.pixelSize: 9
                font.letterSpacing: Theme.trackingWide
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
