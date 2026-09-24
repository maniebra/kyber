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

    function remember(entry) {
        const text = entry.replace(/\n+$/, "");
        if (text.trim() === "")
            return;

        const next = root.history.filter(e => e !== text);
        next.unshift(text);
        root.history = next.slice(0, root.limit);
    }

    // Piped through stdin: argv caps a single argument at 128 KiB.
    // The watcher echoes this copy back, but remember() dedupes it.
    function copy(text) {
        writer.pending = text;
        writer.stdinEnabled = true;
        writer.running = true;
        root.remember(text);
    }

    Process {
        id: writer

        property string pending

        command: ["wl-copy"]
        onStarted: {
            writer.write(writer.pending);
            writer.stdinEnabled = false;
        }
    }

    function forget(text) {
        root.history = root.history.filter(e => e !== text);
    }

    function clear() {
        root.history = [];
    }

    // wl-paste --watch dies when the compositor drops the data-control
    // client or a read fails; without a restart history silently freezes.
    Process {
        id: watcher

        running: true
        // timeout: a hung source app would otherwise block every later read
        command: ["wl-paste", "--type", "text", "--watch",
                  "sh", "-c", "timeout 2 wl-paste --no-newline --type text; printf '\\0'"]
        onExited: respawn.restart()

        stdout: SplitParser {
            splitMarker: String.fromCharCode(0)
            onRead: data => root.remember(data)
        }
    }

    Timer {
        id: respawn

        interval: 1000
        onTriggered: watcher.running = true
    }
}
