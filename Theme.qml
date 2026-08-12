import QtQuick
import Quickshell
pragma Singleton

// Design tokens.
Singleton {
    id: root

    // --- base surfaces (8-digit colors are #AARRGGBB) --------------------
    // Translucent by design: the compositor supplies the blur behind them
    // (see README — `layerrule = blur, kyber-.*`). Alpha must stay above the
    // compositor's ignore_alpha or nothing behind them is blurred.
    // Pure neutral grey stack — no hue tint. Colour enters only via accent.
    readonly property color bg: "#0c0c0c"
    readonly property color panel: "#e6111111"
    readonly property color surface: "#d9242424"
    readonly property color surfaceAlt: "#e02c2c2c"
    readonly property color surfaceHover: "#ee383838"
    // Recessed well: widgets sitting *inside* a panel read as cut into it, so
    // they go darker than the slab, not lighter.
    readonly property color well: "#e6040404"
    // --- text: real hierarchy, not three shades of the same grey -----------
    readonly property color text: "#f0f0f0"
    readonly property color subtext: "#a8a8a8"
    readonly property color faint: "#757575"
    // --- accent: one light blue, everything else stays grey -----------------
    readonly property color cyan: "#45b4ff"
    readonly property color magenta: "#b0a8a8"
    readonly property color violet: "#a8a8b0"
    readonly property color lime: "#a8b0a8"
    readonly property color amber: "#b8ac96"
    readonly property color red: "#c09090"
    readonly property color accent: cyan
    readonly property color accentText: "#151515"
    // --- glass rims: the lit top edge that sells depth ----------------------
    // Slightly stronger than they'd be on mid grey — on a near-black slab a 6%
    // rim disappears entirely.
    readonly property color rim: Qt.rgba(1, 1, 1, 0.14)
    readonly property color rimSoft: Qt.rgba(1, 1, 1, 0.08)
    readonly property color shade: Qt.rgba(0, 0, 0, 0.28)
    // --- type --------------------------------------------------------------
    readonly property string font: "Inter"
    readonly property string fontMono: "JetBrainsMono Nerd Font"
    // Lucide, not the Nerd Font's Material glyphs: one consistent stroke weight
    // and optical size across every icon. Ships as ~/.local/share/fonts/lucide.ttf
    // (lucide-static) — without it, icons fall back to tofu.
    readonly property string fontIcon: "lucide"
    readonly property int fontSize: 11
    readonly property int fontSizeSm: 9
    readonly property real tracking: 0.2       // label letter-spacing
    readonly property real trackingWide: 0.8   // small-caps / meta labels
    // --- metrics -----------------------------------------------------------
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
    // Water, not springs. A drop moves fast the moment it lets go, then surface
    // tension drags the last third out — so the curve is steep at the start and
    // has a long, flat settle. `curveDrop` adds the small overshoot a droplet
    // makes as it lands and pulls itself back into shape; `curveFlow` is the
    // same motion without the wobble, for things that shouldn't bounce (fills,
    // slides, colour).
    readonly property var curveFlow: [0.22, 1.0, 0.28, 1.0, 1.0, 1.0]
    readonly property var curveDrop: [0.28, 1.18, 0.36, 1.0, 1.0, 1.0]
    readonly property int ease: Easing.OutCubic
    readonly property int easeEmph: Easing.OutBack

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

}
