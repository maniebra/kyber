import QtQuick
import Quickshell
import "root:/services"
pragma Singleton

Singleton {
    id: root

    readonly property color bg: "#0c0c0c"
    readonly property color panel: "#e6111111"
    readonly property color surface: "#d9242424"
    readonly property color surfaceAlt: "#e02c2c2c"
    readonly property color surfaceHover: "#ee383838"
    readonly property color well: "#e6040404"
    readonly property color text: "#f0f0f0"
    readonly property color subtext: "#a8a8a8"
    readonly property color faint: "#757575"
    readonly property color cyan: "#45b4ff"
    readonly property color magenta: "#b0a8a8"
    readonly property color violet: "#a8a8b0"
    readonly property color lime: "#a8b0a8"
    readonly property color amber: "#b8ac96"
    readonly property color red: "#c09090"
    readonly property color accent:
        Accent.mode === "system" && Accent.valid ? Accent.color : cyan
    readonly property color accentText: "#151515"
    readonly property color rim: Qt.rgba(1, 1, 1, 0.14)
    readonly property color rimSoft: Qt.rgba(1, 1, 1, 0.08)
    readonly property color shade: Qt.rgba(0, 0, 0, 0.28)
    readonly property string font: "SF Pro Text"
    readonly property string fontMono: "JetBrainsMono Nerd Font"
    readonly property string fontIcon: "lucide"

    // draw apps with the lucide set instead of the system icon theme
    readonly property bool monoAppIcons: true
    readonly property int fontSize: 11
    readonly property int fontSizeSm: 9
    readonly property real tracking: 0.2
    readonly property real trackingWide: 0.8
    readonly property int barHeight: 30
    readonly property int barMargin: 0
    readonly property int radius: 8
    readonly property int radiusSm: 4
    readonly property int gap: 6
    readonly property int railWidth: 36
    readonly property int animFast: 110
    readonly property int animMed: 200
    readonly property int animSlow: 380
    readonly property int animMorph: 300
    readonly property var curveFlow: [0.22, 1.0, 0.28, 1.0, 1.0, 1.0]
    readonly property var curveDrop: [0.28, 1.18, 0.36, 1.0, 1.0, 1.0]
    readonly property int ease: Easing.OutCubic
    readonly property int easeEmph: Easing.OutBack

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

}
