import Quickshell
import QtQuick

import "root:/"
import "root:/components"

// Themed dbusmenu for a tray item. Submenus open in place with a back row.
PopupWindow {
    id: root

    required property var trayItem
    required property Item anchorItem

    property bool open: false
    property var stack: []
    readonly property var current: stack.length ? stack[stack.length - 1] : trayItem.menu

    // 0 = shown, 1 = hidden; the window stays mapped until the fade finishes
    property real hide: open ? 0 : 1
    Behavior on hide { Morph { duration: root.open ? Theme.animMorph : Theme.animFast } }

    function toggle() {
        stack = [];
        open = !open;
    }

    // Set imperatively, not bound: the compositor dismissing the grab (click
    // outside) writes visible = false and would break a binding for good.
    visible: false
    onOpenChanged: if (open) visible = true
    onHideChanged: if (hide >= 1 && !open) visible = false
    onVisibleChanged: if (!visible) open = false

    anchor.item: anchorItem
    anchor.rect.x: anchorItem.width
    anchor.rect.y: anchorItem.height + 8
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    grabFocus: true

    readonly property bool hasChecks: {
        const entries = opener.children.values;
        return entries.some(e => e.buttonType !== QsMenuButtonType.None);
    }

    readonly property real contentWidth: {
        let widest = 0;
        for (let i = 0; i < rows.count; i++) {
            const row = rows.itemAt(i);
            if (row && row.item)
                widest = Math.max(widest, row.item.naturalWidth || 0);
        }
        return Math.max(widest, back.naturalWidth);
    }

    implicitWidth: Math.round(Math.min(340, Math.max(180, contentWidth + 12)))
    implicitHeight: column.implicitHeight + 12
    color: "transparent"

    QsMenuOpener {
        id: opener

        menu: root.current
    }

    GlassPanel {
        id: panel

        anchors.fill: parent
        radius: Theme.radius

        opacity: 1 - root.hide
        transformOrigin: Item.TopRight
        scale: 1 - 0.04 * root.hide
        transform: Translate { y: -6 * root.hide }

        focus: true
        Keys.onEscapePressed: {
            if (root.stack.length)
                root.stack = root.stack.slice(0, -1);
            else
                root.open = false;
        }

        Brackets {
            anchors.margins: 3
            topLeft: false
            topRight: true
            bottomLeft: true
            bottomRight: false
            z: 200
        }

        Column {
            id: column

            anchors.fill: parent
            anchors.margins: 6
            spacing: 1

            MenuRow {
                id: back

                visible: root.stack.length > 0
                label: root.stack.length
                    ? root.stack[root.stack.length - 1].text.replace(/_(?!_)/g, "")
                    : ""
                lead: "‹"
                header: true
                onPicked: root.stack = root.stack.slice(0, -1)
            }

            Item {
                visible: back.visible
                width: parent.width
                height: 7

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width - 12
                    height: 1
                    color: Theme.rimSoft
                }
            }

            Repeater {
                id: rows

                model: opener.children

                Loader {
                    required property var modelData

                    width: column.width
                    sourceComponent: modelData.isSeparator ? separator : row

                    Component {
                        id: separator

                        Item {
                            readonly property real naturalWidth: 0
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
                            lead: modelData.buttonType !== QsMenuButtonType.None
                                && modelData.checkState === Qt.Checked ? "✓" : ""
                            trail: modelData.hasChildren ? "›" : ""
                            onPicked: {
                                if (modelData.hasChildren) {
                                    root.stack = root.stack.concat([modelData]);
                                } else {
                                    modelData.triggered();
                                    root.open = false;
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
        property string lead
        property string trail
        property bool header: false
        signal picked

        readonly property bool hot: area.containsMouse && enabled
        readonly property real leadWidth: header || root.hasChecks ? 18 : 0
        readonly property real naturalWidth:
            10 + leadWidth + (icon ? 22 : 0) + labelText.implicitWidth + (trail ? 22 : 10)

        width: parent ? parent.width : 0
        height: 28
        radius: Theme.radiusSm
        opacity: enabled ? 1 : 0.4
        color: hot ? Theme.alpha(Theme.accent, 0.14) : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.animFast } }

        Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: 1
            anchors.verticalCenter: parent.verticalCenter

            width: 2
            height: menuRow.hot ? parent.height - 12 : 0
            radius: 1
            color: Theme.accent

            Behavior on height { Morph { duration: Theme.animMed } }
        }

        Text {
            id: leadText

            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            width: menuRow.leadWidth

            text: menuRow.lead
            color: menuRow.header ? Theme.subtext : Theme.accent
            font.family: Theme.font
            font.pixelSize: menuRow.header ? 15 : 12
        }

        Image {
            id: iconImage

            anchors.left: leadText.right
            anchors.verticalCenter: parent.verticalCenter
            width: menuRow.icon ? 14 : 0
            height: 14
            source: menuRow.icon
            sourceSize: Qt.size(28, 28)
            smooth: true
        }

        Text {
            id: labelText

            anchors.left: iconImage.right
            anchors.leftMargin: menuRow.icon ? 8 : 0
            anchors.right: trailText.left
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter

            text: menuRow.label
            color: menuRow.header ? Theme.subtext : menuRow.hot ? Theme.text : Qt.darker(Theme.text, 1.08)
            font.family: menuRow.header ? Theme.fontMono : Theme.font
            font.pixelSize: menuRow.header ? 10 : Theme.fontSize + 1
            font.letterSpacing: menuRow.header ? Theme.trackingWide : 0
            font.capitalization: menuRow.header ? Font.AllUppercase : Font.MixedCase
            elide: Text.ElideRight
        }

        Text {
            id: trailText

            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter

            text: menuRow.trail
            color: menuRow.hot ? Theme.accent : Theme.faint
            font.family: Theme.font
            font.pixelSize: 15
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
