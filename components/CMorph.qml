import QtQuick

import "root:/"

// Colour twin of Morph — same duration, but the wobble-free curve: a colour
// can't overshoot, it would just run past the target and come back looking like
// a flicker.
ColorAnimation {
    duration: Theme.animMorph
    easing.type: Easing.Bezier
    easing.bezierCurve: Theme.curveFlow
}
