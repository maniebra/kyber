import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick

import "root:/"
import "root:/components"

Rectangle {
    id: root

    required property var item

    width: 20
    height: 20
    radius: Theme.radiusSm

    color: mouse.containsMouse || menu.open ? Theme.surfaceHover : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    AppIcon {
        anchors.centerIn: parent

        size: 14
        source: root.item.icon
        glyph: ""
    }

    TrayMenu {
        id: menu

        trayItem: root.item
        anchorItem: root
    }

    IpcHandler {
        target: "traytest"
        function open(): void { console.log("TT", root.item.id, menu.open, menu.visible); if (root.item.id === "Throne") menu.toggle(); console.log("TT after", menu.open, menu.visible, menu.hide); }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

        onClicked: mouse => {
            const wantsMenu = mouse.button === Qt.RightButton || root.item.onlyMenu;
            if (wantsMenu && root.item.hasMenu) {
                menu.toggle();
            } else if (mouse.button === Qt.MiddleButton) {
                root.item.secondaryActivate();
            } else {
                root.item.activate();
            }
        }
    }
}
