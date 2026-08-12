import Quickshell.Services.SystemTray
import QtQuick

import "root:/"

Row {
    id: root

    visible: SystemTray.items.values.length > 0
    spacing: 1

    Repeater {
        model: SystemTray.items

        TrayItem {
            required property var modelData
            item: modelData
        }
    }
}
