pragma Singleton

import Quickshell
import QtQuick
import Quickshell.Io

// brightnessctl wrapper. Degrades to "unavailable" when it isn't installed.
Singleton {
    id: root

    property real value: 1        // 0..1
    property bool available: false

    // Sysfs is the fast path: the keyboard's brightness keys run brightnessctl
    // directly, and a 5s poll would show the OSD long after the key. Watching
    // the file picks those up the moment they land. The poll below stays as the
    // fallback for machines where this path doesn't exist.
    FileView {
        path: "/sys/class/backlight/intel_backlight/brightness"
        watchChanges: true

        onFileChanged: reload()
        onLoaded: {
            const cur = parseInt(text());
            if (root.max > 0 && cur >= 0) {
                root.available = true;
                root.value = cur / root.max;
            }
        }
    }

    property int max: 0

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: probe.running = true
    }

    Process {
        id: probe
        command: ["sh", "-c", "command -v brightnessctl >/dev/null 2>&1 && brightnessctl -m || true"]

        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(",");
                if (parts.length < 5) {
                    root.available = false;
                    return;
                }
                const cur = parseInt(parts[2]);
                const max = parseInt(parts[4]);
                if (!(max > 0))
                    return;

                root.available = true;
                root.max = max;
                root.value = cur / max;
            }
        }
    }

    function set(v) {
        if (!available)
            return;
        const pct = Math.round(Math.max(0.01, Math.min(1, v)) * 100);
        value = pct / 100;
        Quickshell.execDetached(["brightnessctl", "-q", "set", `${pct}%`]);
    }
}
