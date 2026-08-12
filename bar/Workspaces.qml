import Quickshell.Hyprland
import QtQuick

import "root:/"
import "root:/components"

Item {
    id: root

    required property var monitor

    // Always show 1..5, plus anything else live on this monitor.
    readonly property var entries: {
        const occupied = {};
        for (const t of Hyprland.toplevels.values) {
            const id = t.workspace?.id;
            if (id !== undefined)
                occupied[id] = true;
        }

        const ids = [1, 2, 3, 4, 5];
        for (const ws of Hyprland.workspaces.values) {
            if (ws.id > 0 && ws.monitor === root.monitor && !ids.includes(ws.id))
                ids.push(ws.id);
        }

        return ids.sort((a, b) => a - b).map(id => ({
            id: id,
            occupied: occupied[id] === true
        }));
    }

    readonly property int activeId: monitor?.activeWorkspace?.id ?? -1
    readonly property int activeIndex:
        entries.findIndex(e => e.id === activeId)

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    // One pill that slides to whichever button is active, instead of each
    // button lighting its own background — the travel is the transition.
    Rectangle {
        readonly property var target:
            root.activeIndex >= 0 ? rep.itemAt(root.activeIndex) : null

        visible: target !== null
        x: target?.x ?? 0
        width: target?.width ?? 0
        height: target?.height ?? 0
        y: 0

        radius: Theme.radiusSm
        antialiasing: true
        color: Theme.alpha(Theme.accent, 0.16)

        Behavior on x { Morph {} }
        Behavior on width { Morph {} }
    }

    Row {
        id: row

        spacing: 3

        Repeater {
            id: rep

            model: root.entries

            WorkspaceButton {
                required property var modelData

                workspaceId: modelData.id
                occupied: modelData.occupied
                active: modelData.id === root.activeId
            }
        }
    }
}
