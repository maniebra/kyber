pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

// Shared UI state. Every window binds against this instead of talking to
// its siblings.
Singleton {
    id: root

    property bool launcher: false
    property bool controlCenter: false
    property bool dnd: false
    property bool dashboard: false

    // Span of the dropdown currently hanging off the bar, flares included, in
    // screen coordinates. The bar breaks its bottom hairline over exactly this
    // span so the line meets the flares instead of cutting across the sheet.
    // Width 0 means nothing hangs. Not every dropdown is centred — the app menu
    // hangs off the left edge — so the start is carried, not assumed.
    property real notchX: 0
    property real notchWidth: 0

    // Same idea for the left rail. Two sheets slide out of it — the app menu
    // and the layout OSD — and they each own their own pair rather than sharing
    // one: with a single pair, whichever sheet closed last wrote its 0 over the
    // value the still-open sheet had set, and the rail's hairline snapped back
    // across the open sheet.
    property real launcherNotchY: 0
    property real launcherNotchHeight: 0
    property real osdNotchY: 0
    property real osdNotchHeight: 0

    // The menu wins when both are out: it is the bigger sheet, and the OSD
    // rides inside its span anyway.
    readonly property real railNotchHeight:
        launcherNotchHeight > 0 ? launcherNotchHeight : osdNotchHeight
    readonly property real railNotchY:
        launcherNotchHeight > 0 ? launcherNotchY : osdNotchY

    // Hover on the clock pill's status dot, which the media peek hangs off. The
    // peek ORs its own hover in, so the pointer can travel from the dot onto
    // the sheet.
    property bool mediaDotHovered: false

    // Whether the media peek is on screen. The dot reports it back to the bar:
    // the thing you hovered stays lit for as long as the sheet it opened.
    property bool mediaPeek: false

    // Active keyboard layout, e.g. "English (US)". Hyprland only announces it on
    // change, so the initial value comes from a one-shot hyprctl read.
    property string keyboardLayout: ""
    // Bumped on every real switch; the OSD watches this rather than the name, so
    // switching back to a layout still shows.
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

    // Hyprland 0.56 dropped the plain-string dispatch grammar for a Lua one:
    // `dispatch workspace 3` now parses as Lua and fails.
    function focusWorkspace(ws) {
        Hyprland.dispatch(`hl.dsp.focus({ workspace = "${ws}" })`);
    }

    function closeAll() {
        launcher = false;
        controlCenter = false;
        dashboard = false;
    }

    function toggleLauncher() {
        controlCenter = false;
        dashboard = false;
        launcher = !launcher;
    }

    function toggleControlCenter() {
        launcher = false;
        dashboard = false;
        controlCenter = !controlCenter;
    }

    function toggleDashboard() {
        launcher = false;
        controlCenter = false;
        dashboard = !dashboard;
    }
}
