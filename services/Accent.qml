pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property var modes: ["off", "peek", "system"]
    property string mode: "peek"

    readonly property color base: "#45b4ff"
    readonly property real baseLightness: 0.635

    property real hue: -1
    property real saturation: 0
    property bool sampled: false

    // A cover with no real colour in it should read as a neutral, not as
    // whatever hue the noise averaged out to.
    readonly property bool greyscale: sampled && saturation <= 0
    readonly property real neutralLightness: 0.82

    readonly property bool valid: sampled && mode !== "off"

    readonly property color color: !valid
        ? root.base
        : greyscale
            ? Qt.hsla(0, 0, root.neutralLightness, 1)
            : Qt.hsla(root.hue, root.saturation, root.baseLightness, 1)

    readonly property string art: Player.current?.trackArtUrl ?? ""

    // Elisa hands the cover over inline as a base64 data: URL. It is far past the
    // 128K limit on a single argv entry, so it goes to the probe over stdin.
    readonly property bool inlineArt: art.startsWith("data:")

    // Local covers arrive as percent-encoded file:// URLs; ffmpeg wants a plain
    // path. Remote http(s) URLs it can open as-is.
    readonly property string artPath: art.startsWith("file://")
        ? decodeURIComponent(art.slice(7))
        : art

    onArtChanged: sample.restart()
    onModeChanged: {
        if (mode === "off") {
            root.sampled = false;
        } else {
            sample.restart();
        }
        prefs.setText(JSON.stringify({ mode: root.mode }));
    }

    Timer {
        id: sample

        interval: 120
        onTriggered: {
            if (root.mode === "off" || root.art === "") {
                root.sampled = false;
                return;
            }
            probe.running = false;
            probe.stdinEnabled = root.inlineArt;
            probe.running = true;
            if (root.inlineArt) {
                probe.write(root.art.slice(root.art.indexOf(",") + 1));
                probe.stdinEnabled = false;
            }
        }
    }

    Process {
        id: probe

        readonly property string pipeline:
            `ffmpeg -v error -i "$1" -vf scale=8:8 -frames:v 1 ` +
            `-f rawvideo -pix_fmt rgb24 - 2>/dev/null | od -An -tu1 -v`

        command: root.inlineArt
            ? ["sh", "-c", `base64 -d | ${pipeline}`, "sh", "-"]
            : ["sh", "-c", pipeline, "sh", root.artPath]

        stdinEnabled: false

        stdout: StdioCollector {
            onStreamFinished: {
                const nums = text.trim().split(/\s+/).map(n => parseInt(n));
                if (nums.length < 3) {
                    root.sampled = false;
                    return;
                }

                let x = 0;
                let y = 0;
                let chromaSum = 0;
                let weightSum = 0;

                for (let i = 0; i + 2 < nums.length; i += 3) {
                    const r = nums[i] / 255;
                    const g = nums[i + 1] / 255;
                    const b = nums[i + 2] / 255;

                    const max = Math.max(r, g, b);
                    const min = Math.min(r, g, b);
                    const chroma = max - min;
                    const light = (max + min) / 2;

                    // Chroma, not HSL saturation: saturation is meaningless near
                    // black and white, where a pixel two units off grey still
                    // reports a strong colour. Chroma stays ~0 for anything that
                    // actually looks grey, at any brightness.
                    if (light < 0.08 || light > 0.95 || chroma < 0.05)
                        continue;

                    let hue;
                    if (max === r)
                        hue = ((g - b) / chroma) % 6;
                    else if (max === g)
                        hue = (b - r) / chroma + 2;
                    else
                        hue = (r - g) / chroma + 4;
                    hue /= 6;

                    const angle = hue * 2 * Math.PI;
                    x += Math.cos(angle) * chroma;
                    y += Math.sin(angle) * chroma;
                    chromaSum += chroma * chroma;
                    weightSum += chroma;
                }

                root.sampled = true;

                if (weightSum <= 0) {
                    root.saturation = 0;
                    return;
                }

                const colorfulness = chromaSum / weightSum;
                if (colorfulness < 0.10) {
                    root.saturation = 0;
                    return;
                }

                let hue = Math.atan2(y, x) / (2 * Math.PI);
                if (hue < 0)
                    hue += 1;

                root.hue = hue;
                root.saturation = Math.max(0.35, Math.min(1, colorfulness * 2.2));
            }
        }
    }

    FileView {
        id: prefs

        path: Quickshell.statePath("kyber/accent.json")
        blockLoading: true
        printErrors: false

        onLoaded: {
            const saved = JSON.parse(text()).mode;
            if (root.modes.includes(saved))
                root.mode = saved;
        }
    }

    function cycle() {
        const i = root.modes.indexOf(root.mode);
        root.mode = root.modes[(i + 1) % root.modes.length];
    }
}
