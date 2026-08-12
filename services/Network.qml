pragma Singleton

import Quickshell
import QtQuick
import Quickshell.Io

// Thin nmcli poll. Enough for a status readout + a wifi toggle; anything
// deeper belongs in nmtui.
Singleton {
    id: root

    property string name: ""
    property string type: ""       // wifi | ethernet | ""
    property int strength: 0       // 0..100
    property bool wifiEnabled: true

    readonly property bool connected: name !== ""

    readonly property string icon: {
        if (!connected)
            return type === "wifi" || wifiEnabled ? "" : "";
        if (type === "ethernet")
            return "";
        if (strength >= 75)
            return "";
        if (strength >= 50)
            return "";
        if (strength >= 25)
            return "";
        return "";
    }

    readonly property string label: connected ? name : "Offline"

    Timer {
        interval: 8000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: probe.running = true
    }

    Process {
        id: probe
        command: ["sh", "-c", `
            command -v nmcli >/dev/null 2>&1 || exit 0
            printf 'radio %s\\n' "$(nmcli -t radio wifi 2>/dev/null)"
            nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi 2>/dev/null |
                awk -F: '$1=="yes"{printf "wifi %s %s\\n", $3, $2; exit}'
            nmcli -t -f TYPE,STATE,CONNECTION dev status 2>/dev/null |
                awk -F: '$1=="ethernet" && $2=="connected"{printf "eth %s\\n", $3; exit}'
        `]

        stdout: StdioCollector {
            onStreamFinished: {
                let name = "";
                let type = "";
                let strength = 0;

                for (const line of text.trim().split("\n")) {
                    const parts = line.trim().split(" ");
                    if (parts[0] === "radio") {
                        root.wifiEnabled = parts[1] === "enabled";
                    } else if (parts[0] === "wifi") {
                        strength = parseInt(parts[1]) || 0;
                        name = parts.slice(2).join(" ");
                        type = "wifi";
                    } else if (parts[0] === "eth" && type === "") {
                        name = parts.slice(1).join(" ");
                        type = "ethernet";
                    }
                }

                root.name = name;
                root.type = type;
                root.strength = strength;
            }
        }
    }

    // ---- picker ---------------------------------------------------------
    // Scanned APs, strongest first, one row per SSID:
    // { ssid, signal, secured, known, active }
    property var networks: []
    property bool scanning: false
    property string error: ""

    function scan() {
        error = "";
        scanning = true;
        list.running = true;
    }

    // Known connection first — that reuses the stored secret instead of asking
    // for it again. Only a network we have never seen needs a password.
    function connect(ssid, password) {
        error = "";
        scanning = true;
        connector.command = ["sh", "-c", `
            if nmcli -t -f NAME con show | grep -qxF ${shellQuote(ssid)}; then
                nmcli con up id ${shellQuote(ssid)}
            else
                nmcli dev wifi connect ${shellQuote(ssid)}` +
                (password ? ` password ${shellQuote(password)}` : "") + `
            fi
        `];
        connector.running = true;
    }

    function forget(ssid) {
        Quickshell.execDetached(["nmcli", "con", "delete", "id", ssid]);
        refresh.restart();
    }

    function shellQuote(s) {
        return `'${String(s).replace(/'/g, `'\\''`)}'`;
    }

    Process {
        id: list
        command: ["sh", "-c", `
            command -v nmcli >/dev/null 2>&1 || exit 0
            nmcli -t -f NAME con show 2>/dev/null | sed 's/^/known:/'
            nmcli --escape no -t -f ACTIVE,SIGNAL,SECURITY,SSID dev wifi list 2>/dev/null |
                sed 's/^/ap:/'
        `]

        stdout: StdioCollector {
            onStreamFinished: {
                const known = {};
                const seen = {};
                const aps = [];

                for (const line of text.split("\n")) {
                    if (line.startsWith("known:")) {
                        known[line.slice(6)] = true;
                        continue;
                    }
                    if (!line.startsWith("ap:"))
                        continue;

                    // ACTIVE:SIGNAL:SECURITY:SSID — SSIDs may contain ':', so
                    // only the first three fields are split off.
                    const parts = line.slice(3).split(":");
                    const ssid = parts.slice(3).join(":");
                    if (ssid === "" || seen[ssid])
                        continue;
                    seen[ssid] = true;

                    aps.push({
                        ssid: ssid,
                        signal: parseInt(parts[1]) || 0,
                        secured: parts[2] !== "",
                        active: parts[0] === "yes"
                    });
                }

                root.networks = aps
                    .map(ap => Object.assign(ap, { known: known[ap.ssid] === true }))
                    .sort((a, b) => b.signal - a.signal);
                root.scanning = false;
            }
        }
    }

    Process {
        id: connector

        stderr: StdioCollector {
            onStreamFinished: {
                const msg = text.trim().split("\n").pop() ?? "";
                root.error = msg.replace(/^Error:\s*/, "");
            }
        }

        onExited: code => {
            root.scanning = false;
            if (code === 0)
                root.error = "";
            probe.running = true;
            list.running = true;
        }
    }

    function toggleWifi() {
        Quickshell.execDetached([
            "nmcli", "radio", "wifi", wifiEnabled ? "off" : "on"
        ]);
        wifiEnabled = !wifiEnabled;
        refresh.restart();
    }

    function openEditor() {
        Quickshell.execDetached([
            "sh", "-c",
            "command -v nm-connection-editor >/dev/null && exec nm-connection-editor || exec kitty -e nmtui"
        ]);
    }

    Timer {
        id: refresh
        interval: 1200
        onTriggered: probe.running = true
    }
}
