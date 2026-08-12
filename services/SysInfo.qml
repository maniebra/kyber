pragma Singleton

import Quickshell
import QtQuick
import Quickshell.Io

// CPU + memory straight from /proc. No dependency, no daemon.
Singleton {
    id: root

    property real cpu: 0      // 0..1
    property real memory: 0   // 0..1
    property int memUsedMb: 0
    property int memTotalMb: 0

    property int _lastTotal: 0
    property int _lastIdle: 0

    property int uptimeSeconds: 0

    readonly property string uptime: {
        const d = Math.floor(uptimeSeconds / 86400);
        const h = Math.floor((uptimeSeconds % 86400) / 3600);
        const m = Math.floor((uptimeSeconds % 3600) / 60);
        return d > 0 ? `${d}d ${h}h` : h > 0 ? `${h}h ${m}m` : `${m}m`;
    }

    readonly property string user: Quickshell.env("USER") ?? "user"
    readonly property string host: Quickshell.env("HOSTNAME") ?? ""

    property string distro: ""
    readonly property string wm: Quickshell.env("XDG_CURRENT_DESKTOP")
        ?? Quickshell.env("XDG_SESSION_DESKTOP") ?? "wayland"

    FileView {
        path: "/etc/os-release"
        preload: true
        onLoaded: root.distro =
            text().match(/^PRETTY_NAME="?([^"\n]+)"?/m)?.[1] ?? "Linux"
    }

    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        onLoaded: root.uptimeSeconds = Math.floor(parseFloat(text().split(" ")[0]))
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            stat.reload();
            meminfo.reload();
            uptimeFile.reload();
        }
    }

    FileView {
        id: stat
        path: "/proc/stat"

        onLoaded: {
            const line = text().split("\n")[0].trim().split(/\s+/);
            if (line[0] !== "cpu")
                return;

            const nums = line.slice(1).map(Number);
            const total = nums.reduce((a, b) => a + b, 0);
            const idle = nums[3] + (nums[4] ?? 0);

            const dTotal = total - root._lastTotal;
            const dIdle = idle - root._lastIdle;

            if (root._lastTotal > 0 && dTotal > 0)
                root.cpu = Math.max(0, Math.min(1, 1 - dIdle / dTotal));

            root._lastTotal = total;
            root._lastIdle = idle;
        }
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"

        onLoaded: {
            const map = {};
            for (const line of text().split("\n")) {
                const m = line.match(/^(\w+):\s+(\d+)/);
                if (m)
                    map[m[1]] = parseInt(m[2]);
            }

            const total = map.MemTotal ?? 0;
            const avail = map.MemAvailable ?? total;
            if (total <= 0)
                return;

            root.memTotalMb = Math.round(total / 1024);
            root.memUsedMb = Math.round((total - avail) / 1024);
            root.memory = (total - avail) / total;
        }
    }
}
