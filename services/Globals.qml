pragma Singleton

import Quickshell
import Quickshell.Hyprland

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

    // Same idea for the left rail, which the app menu slides out of.
    property real railNotchY: 0
    property real railNotchHeight: 0

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
