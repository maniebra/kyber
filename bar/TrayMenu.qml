import Quickshell
import QtQuick

import "root:/"
import "root:/components"

// Themed dbusmenu for a tray item. Submenus open in place with a back row.
PopupWindow {
    id: root

    required property var trayItem
    required property Item anchorItem

    property var stack: []
    readonly property var current: stack.length ? stack[stack.length - 1] : trayItem.menu

    function toggle() {
        stack = [];
        visible = !visible;
    }

    anchor.item: anchorItem
    anchor.rect.y: anchorItem.height + 6
    anchor.rect.x: anchorItem.width / 2
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    grabFocus: true

    implicitWidth: 220
    implicitHeight: column.implicitHeight + 12
    color: "transparent"

    QsMenuOpener {
        id: opener

        menu: root.current
    }

    GlassPanel {
        anchors.fill: parent
        radius: Theme.radius

        focus: true
        Keys.onEscapePressed: root.visible = false

        Column {
            id: column

            anchors.fill: parent
            anchors.margins: 6

            MenuRow {
                visible: root.stack.length > 0
                label: "Back"
                glyph: "‹"
                onPicked: root.stack = root.stack.slice(0, -1)
            }

            Repeater {
                model: opener.children

                Loader {
                    required property var modelData

                    width: column.width
                    sourceComponent: modelData.isSeparator ? separator : row

                    Component {
                        id: separator

                        Item {
                            height: 9

                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width - 12
                                height: 1
                                color: Theme.rimSoft
                            }
                        }
                    }

                    Component {
                        id: row

                        MenuRow {
                            label: modelData.text.replace(/_(?!_)/g, "")
                            icon: modelData.icon
                            enabled: modelData.enabled
                            checked: modelData.buttonType !== QsMenuButtonType.None
                                && modelData.checkState === Qt.Checked
                            glyph: modelData.hasChildren ? "›" : ""
                            onPicked: {
                                if (modelData.hasChildren) {
                                    root.stack = root.stack.concat([modelData]);
                                } else {
                                    modelData.triggered();
                                    root.visible = false;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    component MenuRow: Rectangle {
        id: menuRow

        property string label
        property string icon
        property string glyph
        property bool checked
        signal picked

        width: parent ? parent.width : 0
        height: 28
        radius: Theme.radiusSm
        opacity: enabled ? 1 : 0.4
        color: area.containsMouse && enabled ? Theme.surfaceHover : "transparent"

        Text {
            id: check

            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: 14

            text: menuRow.checked ? "✓" : ""
            color: Theme.accent
            font.family: Theme.font
            font.pixelSize: 12
        }

        Image {
            id: iconImage

            anchors.left: check.right
            anchors.leftMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            width: menuRow.icon ? 14 : 0
            height: 14
            source: menuRow.icon
            sourceSize: Qt.size(14, 14)
        }

        Text {
            anchors.left: iconImage.right
            anchors.leftMargin: menuRow.icon ? 8 : 0
            anchors.right: arrow.left
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter

            text: menuRow.label
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: Theme.fontSize + 1
            elide: Text.ElideRight
        }

        Text {
            id: arrow

            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter

            text: menuRow.glyph
            color: Theme.faint
            font.family: Theme.font
            font.pixelSize: 14
        }

        MouseArea {
            id: area

            anchors.fill: parent
            hoverEnabled: true
            enabled: menuRow.enabled
            cursorShape: Qt.PointingHandCursor
            onClicked: menuRow.picked()
        }
    }
}
