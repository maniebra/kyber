pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property var history: []
    readonly property int limit: 20

    property bool loaded: false

    FileView {
        id: store

        path: Quickshell.statePath("kyber/clipboard.json")
        blockLoading: true

        onLoaded: {
            try {
                const saved = JSON.parse(text());
                if (Array.isArray(saved))
                    root.history = saved.slice(0, root.limit);
            } catch (e) {
            }
            root.loaded = true;
        }

        onLoadFailed: root.loaded = true
    }

    onHistoryChanged: if (root.loaded) save.restart()

    Timer {
        id: save

        interval: 500
        onTriggered: store.setText(JSON.stringify(root.history))
    }

    property bool muted: false

    function remember(entry) {
        const text = entry.replace(/\n+$/, "");
        if (text.trim() === "")
            return;

        const next = root.history.filter(e => e !== text);
        next.unshift(text);
        root.history = next.slice(0, root.limit);
    }

    function copy(text) {
        root.muted = true;
        unmute.restart();
        Quickshell.execDetached(["wl-copy", "--", text]);
        root.remember(text);
    }

    function forget(text) {
        root.history = root.history.filter(e => e !== text);
    }

    function clear() {
        root.history = [];
    }

    Timer {
        id: unmute

        interval: 400
        onTriggered: root.muted = false
    }

    Process {
        running: true
        command: ["wl-paste", "--type", "text", "--watch",
                  "sh", "-c", "wl-paste --no-newline --type text; printf '\\0'"]

        stdout: SplitParser {
            splitMarker: String.fromCharCode(0)
            onRead: data => {
                if (!root.muted)
                    root.remember(data);
            }
        }
    }
}
