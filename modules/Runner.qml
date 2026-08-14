import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

import "root:/"
import "root:/components"
import "root:/services"

PanelWindow {
    id: root

    required property string screenName

    readonly property bool shouldOpen:
        Globals.runner && Globals.focusedScreen === screenName

    property real slide: shouldOpen ? 0 : 1
    Behavior on slide { Morph {} }

    readonly property bool open: slide < 1

    visible: open

    WlrLayershell.namespace: "kyber-runner"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shouldOpen
        ? WlrKeyboardFocus.Exclusive
        : WlrKeyboardFocus.None

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    color: "transparent"
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore

    onVisibleChanged: if (visible) search.forceActiveFocus()

    onShouldOpenChanged: {
        if (shouldOpen) {
            search.text = "";
            list.currentIndex = 0;
            search.forceActiveFocus();
        }
    }

    function close() {
        Globals.runner = false;
    }

    function run(cmd) {
        Quickshell.execDetached(["sh", "-c", cmd]);
    }

    readonly property var sessionActions: [
        { key: "lock", title: "Lock", glyph: "\ue10b", cmd: "loginctl lock-session" },
        { key: "logout", title: "Log Out", glyph: "\ue10e", cmd: "hyprctl dispatch exit" },
        { key: "sleep suspend", title: "Suspend", glyph: "\ue11e", cmd: "systemctl suspend" },
        { key: "reboot restart", title: "Restart", glyph: "\ue149", cmd: "systemctl reboot" },
        { key: "shutdown poweroff halt", title: "Shut Down", glyph: "\ue140", cmd: "systemctl poweroff" }
    ]

    // ponytail: naive `find` scan of $HOME, swap for fd/plocate if it drags
    property var fileHits: []

    Timer {
        id: debounce

        interval: 220
        onTriggered: {
            const q = search.text.trim();
            root.fileHits = [];
            if (q.length < 3 || q.startsWith("=") || q.startsWith(">"))
                return;

            scan.command = ["sh", "-c",
                `find "$HOME" -maxdepth 6 \\( -name '.*' -o -name node_modules \\)`
                + ` -prune -o -iname ${JSON.stringify("*" + q + "*")}`
                + ` -printf '%y\\t%p\\n' 2>/dev/null`
                + ` | head -n 12`];
            scan.running = true;
        }
    }

    readonly property var fileGlyphs: ({
        jpg: "\ue31c", jpeg: "\ue31c", png: "\ue31c", gif: "\ue31c",
        webp: "\ue31c", svg: "\ue31c", bmp: "\ue31c", avif: "\ue31c",
        mp3: "\ue122", flac: "\ue122", ogg: "\ue122", wav: "\ue122",
        m4a: "\ue122", opus: "\ue122",
        mp4: "\ue1a5", mkv: "\ue1a5", webm: "\ue1a5", mov: "\ue1a5",
        avi: "\ue1a5",
        zip: "\ue30d", tar: "\ue30d", gz: "\ue30d", xz: "\ue30d",
        zst: "\ue30d", bz2: "\ue30d", "7z": "\ue30d", rar: "\ue30d",
        js: "\ue0c3", ts: "\ue0c3", qml: "\ue0c3", py: "\ue0c3",
        sh: "\ue0c3", rs: "\ue0c3", go: "\ue0c3", c: "\ue0c3",
        h: "\ue0c3", cpp: "\ue0c3", json: "\ue0c3", html: "\ue0c3",
        css: "\ue0c3", toml: "\ue0c3", yaml: "\ue0c3", yml: "\ue0c3",
        csv: "\ue326", tsv: "\ue326", xlsx: "\ue326", ods: "\ue326",
        ttf: "\ue329", otf: "\ue329", woff: "\ue329", woff2: "\ue329",
        txt: "\ue0cc", md: "\ue0cc", pdf: "\ue0cc", org: "\ue0cc"
    })

    function fileGlyph(name, isDir) {
        if (isDir)
            return "";
        const dot = name.lastIndexOf(".");
        const ext = dot > 0 ? name.slice(dot + 1).toLowerCase() : "";
        return root.fileGlyphs[ext] ?? "";
    }

    Process {
        id: scan

        stdout: StdioCollector {
            onStreamFinished: root.fileHits =
                text.split("\n").filter(l => l !== "")
        }
    }

    // entry: { glyph, icon, title, subtitle, act }
    readonly property var results: {
        const raw = search.text.trim();

        const out = [];

        if (raw === "")
            return DesktopEntries.applications.values
                .filter(a => !a.noDisplay)
                .sort((a, b) => a.name.localeCompare(b.name))
                .slice(0, 40)
                .map(a => ({
                    icon: Theme.monoAppIcons ? "" : a.icon,
                    glyph: AppGlyphs.forEntry(a),
                    title: a.name,
                    subtitle: a.genericName || a.comment || "application",
                    act: () => a.execute()
                }));

        if (raw.startsWith(">")) {
            const cmd = raw.slice(1).trim();
            if (cmd !== "")
                out.push({
                    glyph: "\ue181",
                    title: cmd,
                    subtitle: "run command",
                    act: () => root.run(cmd)
                });
            return out;
        }

        // calculator: explicit `=` or a bare arithmetic expression
        const expr = raw.startsWith("=") ? raw.slice(1) : raw;
        if (expr.trim() !== "" && /^[\d\s+\-*/%().,^]+$/.test(expr)) {
            let value;
            try {
                value = eval(expr.replace(/\^/g, "**"));
            } catch (e) {
                value = undefined;
            }
            if (typeof value === "number" && isFinite(value))
                out.push({
                    glyph: "\ue1bc",
                    title: `${expr.trim()} = ${value}`,
                    subtitle: "copy result",
                    act: () => root.run(`wl-copy -- ${JSON.stringify(String(value))}`)
                });
        }
        if (raw.startsWith("="))
            return out;

        const query = raw.toLowerCase();

        const scored = [];
        for (const app of DesktopEntries.applications.values) {
            if (app.noDisplay)
                continue;

            const name = app.name.toLowerCase();
            const extra = `${app.genericName ?? ""} ${app.comment ?? ""}`.toLowerCase();

            let score = -1;
            if (name.startsWith(query))
                score = 0;
            else if (name.includes(query))
                score = 1;
            else if (extra.includes(query))
                score = 2;

            if (score >= 0)
                scored.push({ app: app, score: score });
        }

        scored.sort((a, b) => a.score - b.score || a.app.name.localeCompare(b.app.name));
        for (const e of scored.slice(0, 6))
            out.push({
                icon: Theme.monoAppIcons ? "" : e.app.icon,
                glyph: AppGlyphs.forEntry(e.app),
                title: e.app.name,
                subtitle: e.app.genericName || e.app.comment || "application",
                act: () => e.app.execute()
            });

        for (const s of root.sessionActions) {
            if (s.key.split(" ").some(k => k.startsWith(query)))
                out.push({
                    glyph: s.glyph,
                    title: s.title,
                    subtitle: "session",
                    act: () => root.run(s.cmd)
                });
        }

        for (const hit of root.fileHits) {
            const tab = hit.indexOf("\t");
            const type = hit.slice(0, tab);
            const path = hit.slice(tab + 1);
            const name = path.slice(path.lastIndexOf("/") + 1);
            out.push({
                glyph: root.fileGlyph(name, type === "d"),
                title: name,
                subtitle: path,
                act: () => root.run(`xdg-open ${JSON.stringify(path)}`)
            });
        }

        out.push({
            glyph: "\ue181",
            title: raw,
            subtitle: "run command",
            act: () => root.run(raw)
        });

        out.push({
            glyph: "\ue0e8",
            title: `Search the web for “${raw}”`,
            subtitle: "duckduckgo",
            act: () => root.run(
                `xdg-open https://duckduckgo.com/?q=${encodeURIComponent(raw)}`)
        });

        return out;
    }

    function activate(entry) {
        if (!entry)
            return;
        root.close();
        entry.act();
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    readonly property real screenInset: (screen?.width ?? width) - width
    readonly property real reveal: 1 - Math.max(0, slide)

    Binding {
        target: Globals
        property: "notchWidth"
        value: Math.round((panel.width + 32) * root.reveal)
        when: root.open
        restoreMode: Binding.RestoreNone
    }

    Binding {
        target: Globals
        property: "notchX"
        value: Math.round(root.screenInset + panel.x
            + panel.width / 2 - (panel.width + 32) * root.reveal / 2)
        when: root.open
        restoreMode: Binding.RestoreNone
    }

    Item {
        id: stage

        anchors.fill: parent

        FlareCorner {
            anchors.top: parent.top
            anchors.right: panel.left
            anchors.rightMargin: -1
            size: 16 * (1 - root.slide)
            z: 1
        }

        FlareCorner {
            anchors.top: parent.top
            anchors.left: panel.right
            anchors.leftMargin: -1
            size: 16 * (1 - root.slide)
            mirrored: true
            z: 1
        }

        GlassPanel {
            id: panel

            anchors.horizontalCenter: parent.horizontalCenter
            y: -height * Math.max(0, root.slide)

            width: Math.min(560, root.width - 80)
            height: 64 + Math.min(8, root.results.length) * 52
                + (root.results.length ? 12 : 0)
            radius: Theme.radius + 4
            squareTop: true

            Behavior on height { Morph {} }

            MouseArea {
                anchors.fill: parent
            }

            Brackets {
                anchors.margins: 3
                topLeft: false
                topRight: false
                bottomLeft: true
                bottomRight: true
                z: 200
            }

            Item {
                id: field

                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: 6
                }

                height: 52

                Text {
                    id: prompt

                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter

                    text: "\ue151"
                    color: Theme.accent
                    font.family: Theme.fontIcon
                    font.pixelSize: 17
                }

                TextInput {
                    id: search

                    anchors {
                        left: prompt.right
                        leftMargin: 12
                        right: counter.left
                        rightMargin: 12
                        verticalCenter: parent.verticalCenter
                    }

                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: 17
                    focus: true
                    activeFocusOnPress: true
                    selectByMouse: true
                    selectionColor: Theme.alpha(Theme.accent, 0.35)
                    clip: true

                    onTextChanged: {
                        list.currentIndex = 0;
                        debounce.restart();
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: search.text === ""
                        text: "Run a command,  = calculate,  > shell"
                        color: Theme.faint
                        font: search.font
                    }

                    Keys.onEscapePressed: root.close()
                    Keys.onDownPressed: list.incrementCurrentIndex()
                    Keys.onUpPressed: list.decrementCurrentIndex()
                    Keys.onTabPressed: list.incrementCurrentIndex()
                    Keys.onBacktabPressed: list.decrementCurrentIndex()

                    Keys.onReturnPressed: root.activate(root.results[list.currentIndex])
                    Keys.onEnterPressed: root.activate(root.results[list.currentIndex])
                }

                Text {
                    id: counter

                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter

                    text: root.results.length
                    color: Theme.faint
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                }
            }

            Rectangle {
                id: rule

                anchors.top: field.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 1

                height: 1
                visible: root.results.length > 0

                color: Theme.alpha(Theme.faint, 0.5)
            }

            ListView {
                id: list

                anchors {
                    top: rule.bottom
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    topMargin: 6
                    bottomMargin: 6
                    leftMargin: 6
                    rightMargin: 6
                }

                model: root.results
                clip: true
                spacing: 2
                currentIndex: 0
                highlightMoveDuration: Theme.animFast
                keyNavigationWraps: true

                delegate: Rectangle {
                    id: row

                    required property var modelData
                    required property int index

                    readonly property bool selected: list.currentIndex === index

                    width: list.width
                    height: 50
                    radius: Theme.radiusSm + 2

                    color: selected
                        ? Theme.alpha(Theme.accent, 0.14)
                        : hover.containsMouse
                            ? Theme.surfaceHover
                            : "transparent"

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 3
                        height: row.selected ? 26 : 0
                        radius: 2
                        color: Theme.accent

                        Behavior on height {
                            NumberAnimation { duration: Theme.animFast }
                        }
                    }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 12
                        spacing: 12

                        AppIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            size: 30
                            name: row.modelData.icon ?? ""
                            glyph: row.modelData.glyph ?? ""
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 54
                            spacing: 2

                            Text {
                                width: parent.width
                                text: row.modelData.title
                                color: Theme.text
                                font.family: Theme.font
                                font.pixelSize: 13
                                font.weight: row.selected ? Font.DemiBold : Font.Normal
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: row.modelData.subtitle
                                visible: text !== ""
                                color: Theme.faint
                                font.family: Theme.font
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }
                        }
                    }

                    MouseArea {
                        id: hover

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onEntered: list.currentIndex = row.index
                        onClicked: root.activate(row.modelData)
                    }
                }
            }
        }
    }
}
