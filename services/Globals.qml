pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool launcher: false
    property bool controlCenter: false
    property bool dnd: false
    property bool dashboard: false
    property bool clipboard: false

    property real notchX: 0
    property real notchWidth: 0

    property real launcherNotchY: 0
    property real launcherNotchHeight: 0
    property real osdNotchY: 0
    property real osdNotchHeight: 0

    readonly property real railNotchHeight:
        launcherNotchHeight > 0 ? launcherNotchHeight : osdNotchHeight
    readonly property real railNotchY:
        launcherNotchHeight > 0 ? launcherNotchY : osdNotchY

    property bool mediaDotHovered: false

    property bool mediaPeek: false

    property string keyboardLayout: ""
    property int keyboardLayoutTick: 0

    Process {
        running: true
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                const kbs = JSON.parse(text).keyboards;
                root.keyboardLayout =
                    (kbs.find(k => k.main) ?? kbs[0])?.active_keymap ?? "";
            }
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name !== "activelayout")
                return;
            root.keyboardLayout = event.data.split(",").slice(1).join(",");
            root.keyboardLayoutTick++;
        }
    }

    readonly property string focusedScreen:
        Hyprland.focusedMonitor?.name ?? ""

    function focusWorkspace(ws) {
        Hyprland.dispatch(`hl.dsp.focus({ workspace = "${ws}" })`);
    }

    function closeAll() {
        launcher = false;
        controlCenter = false;
        dashboard = false;
        clipboard = false;
    }

    function toggleLauncher() {
        controlCenter = false;
        dashboard = false;
        clipboard = false;
        launcher = !launcher;
    }

    function toggleClipboard() {
        controlCenter = false;
        dashboard = false;
        launcher = false;
        clipboard = !clipboard;
    }

    function toggleControlCenter() {
        launcher = false;
        clipboard = false;
        dashboard = false;
        controlCenter = !controlCenter;
    }

    function toggleDashboard() {
        launcher = false;
        clipboard = false;
        controlCenter = false;
        dashboard = !dashboard;
    }
}
