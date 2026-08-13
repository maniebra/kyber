pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

import "root:/services"

Singleton {
    id: root

    readonly property int bandCount: 24

    property var bars: new Array(root.bandCount).fill(0)

    readonly property real bass: {
        const b = root.bars;
        return (b[0] + b[1] + b[2] + b[3]) / 4;
    }

    readonly property real level: {
        let sum = 0;
        for (const v of root.bars)
            sum += v;
        return sum / root.bandCount;
    }

    readonly property bool wanted: Globals.mediaPeek && Player.playing
    property bool configReady: false

    readonly property bool active: wanted && configReady

    readonly property string configPath: Quickshell.statePath("kyber/cava.conf")

    FileView {
        id: config

        path: root.configPath
        printErrors: false

        Component.onCompleted: {
            setText(`[general]
framerate = 60
bars = ${root.bandCount}
autosens = 1

[input]
method = pipewire
source = auto

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 100
bar_delimiter = 59
frame_delimiter = 10

[smoothing]
noise_reduction = 40
`);
            root.configReady = true;
        }
    }

    Process {
        running: root.active
        command: ["cava", "-p", root.configPath]

        stdout: SplitParser {
            onRead: line => {
                const parts = line.split(";");
                const out = [];
                for (let i = 0; i < root.bandCount; i++)
                    out.push(Math.min(1, (parseInt(parts[i]) || 0) / 100));
                root.bars = out;
            }
        }
    }

    onActiveChanged: if (!active) root.bars = new Array(root.bandCount).fill(0)
}
